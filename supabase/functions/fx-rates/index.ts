// Edge Function `fx-rates` (P7-T02). Contract: docs/fx-rates-api.md.
// The provider (Frankfurter, ECB reference rates, keyless) receives a plain GET with the currency
// pair and the day: no client headers, no IP, no user id.
import { clientIp, constantTimeEquals, corsHeaders, hashClient } from "../_shared/fuel.ts";
import {
  type FxRow,
  isUsable,
  keyDate,
  parseFrankfurter,
  providerPath,
  type Query,
  shapeResponse,
  toRow,
  validateParams,
} from "../_shared/fx.ts";

const DEFAULT_PROVIDER_URL = "https://api.frankfurter.app";
const PROVIDER_TIMEOUT_MS = 8000;

const env = (name: string): string => Deno.env.get(name) ?? "";
const envInt = (name: string, fallback: number): number => {
  const n = Number(env(name));
  return Number.isFinite(n) && n > 0 ? n : fallback;
};

// ---------------------------------------------------------------------------
// Database access (PostgREST with the service role; the only writer of the cache)

async function rest(path: string, init: RequestInit = {}): Promise<Response> {
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  return await fetch(`${env("SUPABASE_URL")}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
    signal: AbortSignal.timeout(5000),
  });
}

async function readRows(query: Query, date: string | null): Promise<FxRow | null> {
  // `date` set: that exact key day. Null: the newest row of the pair (stale fallback).
  const filter = date === null ? "&order=date.desc&limit=1" : `&date=eq.${date}`;
  const res = await rest(
    `fx_rates?base=eq.${query.base}&quote=eq.${query.quote}${filter}&select=*`,
  );
  if (!res.ok) throw new Error(`cache read failed: ${res.status}`);
  const rows = await res.json();
  return rows[0] ?? null;
}

async function writeRow(row: FxRow): Promise<void> {
  const res = await rest("fx_rates?on_conflict=base,quote,date", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
    body: JSON.stringify([row]),
  });
  if (!res.ok) throw new Error(`cache write failed: ${res.status}`);
}

async function takeToken(keyHash: string): Promise<boolean> {
  const res = await rest("rpc/consume_rate_limit", {
    method: "POST",
    body: JSON.stringify({
      p_key: keyHash,
      p_capacity: envInt("FX_RATE_LIMIT_CAPACITY", 60),
      p_refill_per_sec: envInt("FX_RATE_LIMIT_PER_MIN", 60) / 60,
    }),
  });
  if (!res.ok) throw new Error(`rate limit failed: ${res.status}`);
  return (await res.json()) === true;
}

// ---------------------------------------------------------------------------
// Provider

class NoData extends Error {}

async function refresh(query: Query): Promise<FxRow> {
  const base = (env("FX_PROVIDER_URL") || DEFAULT_PROVIDER_URL).replace(/\/+$/, "");
  const res = await fetch(`${base}/${providerPath(query)}`, {
    headers: { Accept: "application/json" },
    signal: AbortSignal.timeout(PROVIDER_TIMEOUT_MS),
  });
  // Frankfurter answers 404 for a currency the ECB does not publish.
  if (res.status === 404) {
    await res.body?.cancel();
    throw new NoData();
  }
  if (!res.ok) throw new Error(`provider status ${res.status}`);
  const parsed = parseFrankfurter(await res.json(), query);
  if (!parsed) throw new Error("provider returned an unexpected body");
  const row = toRow(query, parsed, Date.now());
  await writeRow(row);
  return row;
}

// ---------------------------------------------------------------------------
// Request handling

function json(body: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers },
  });
}

async function handle(req: Request): Promise<Response> {
  const cors = corsHeaders(req.headers.get("origin"), env("FX_ALLOWED_ORIGINS"));
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405, cors);

  const now = Date.now();
  const query = validateParams(new URL(req.url).searchParams, now);
  const warmToken = env("FX_WARM_TOKEN");
  const warm = warmToken !== "" &&
    constantTimeEquals(req.headers.get("x-fx-warm") ?? "", warmToken);

  if (!warm) {
    try {
      const salt = env("FX_RATE_LIMIT_SALT") || env("SUPABASE_SERVICE_ROLE_KEY");
      // "fx|" keeps this bucket apart from the fuel-prices bucket of the same client.
      if (!(await takeToken(await hashClient(`fx|${clientIp(req.headers)}`, salt)))) {
        return json({ error: "rate_limited" }, 429, { ...cors, "Retry-After": "60" });
      }
    } catch (e) {
      // A broken limiter must not take the feature down; the cache still bounds provider calls.
      console.error("rate limiter unavailable", (e as Error).message);
    }
  }
  if (!query) return json({ error: "invalid_params" }, 400, cors);

  let cached: FxRow | null = null;
  try {
    cached = await readRows(query, keyDate(query, now));
    if (cached && !warm && isUsable(cached, query, now)) {
      return json(shapeResponse(cached), 200, { ...cors, "Cache-Control": "public, max-age=60" });
    }
    // A warm call refreshes "latest" only; a past day never changes.
    if (cached && warm && query.date !== null) {
      return json(shapeResponse(cached), 200, { ...cors, "Cache-Control": "public, max-age=60" });
    }
  } catch (e) {
    console.error("cache read failed", (e as Error).message);
  }
  try {
    const row = await refresh(query);
    return json(shapeResponse(row), 200, { ...cors, "Cache-Control": "public, max-age=60" });
  } catch (e) {
    if (e instanceof NoData) return json({ error: "no_data" }, 404, cors);
    console.error("provider refresh failed", (e as Error).message);
  }
  // Provider down: for "latest" the newest cached rate is better than nothing.
  try {
    cached = query.date === null ? await readRows(query, null) : cached;
  } catch (e) {
    console.error("stale cache read failed", (e as Error).message);
  }
  if (cached) {
    return json(shapeResponse(cached), 200, { ...cors, "Cache-Control": "public, max-age=60" });
  }
  return json({ error: "provider_unavailable" }, 503, cors);
}

Deno.serve(handle);
