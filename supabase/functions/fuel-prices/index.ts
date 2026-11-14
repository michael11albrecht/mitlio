// Edge Function `fuel-prices` (P6c-T03, T06). Contract: docs/fuel-prices-api.md.
// Never forwards client IP or exact location: see _shared/fuel.ts (snapToCell, providerArea).
import {
  cacheKey,
  type CacheRow,
  clientIp,
  constantTimeEquals,
  corsHeaders,
  FUEL_TYPES,
  type FuelType,
  hashClient,
  isFresh,
  NATIONAL_MIN_SUCCESSFUL_SAMPLES,
  NATIONAL_SAMPLE,
  NATIONAL_SAMPLE_RADIUS_KM,
  nationalStep,
  parseStationList,
  pricesFromStations,
  providerArea,
  type Query,
  type Scope,
  shapeResponse,
  summarize,
  TTL_SECONDS,
  validateParams,
} from "../_shared/fuel.ts";
import { parseBulletinXlsx } from "../_shared/oil_bulletin.ts";

const DEFAULT_TK_BASE = "https://creativecommons.tankerkoenig.de/json";
const DEFAULT_BULLETIN_URL =
  "https://energy.ec.europa.eu/document/download/264c2d0f-f161-4ea3-a777-78faae59bea0_en?filename=weekly-oil-bulletin-prices-with-taxes.xlsx";
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

async function readCache(type: FuelType, scope: Scope, scopeKey: string): Promise<CacheRow | null> {
  const q = `fuel_price_cache?type=eq.${type}&scope=eq.${scope}` +
    `&scope_key=eq.${encodeURIComponent(scopeKey)}&select=*`;
  const res = await rest(q);
  if (!res.ok) throw new Error(`cache read failed: ${res.status}`);
  const rows = await res.json();
  return rows[0] ?? null;
}

async function writeCache(rows: CacheRow[]): Promise<void> {
  if (rows.length === 0) return;
  const res = await rest("fuel_price_cache?on_conflict=type,scope,scope_key", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
    body: JSON.stringify(rows),
  });
  if (!res.ok) throw new Error(`cache write failed: ${res.status}`);
}

async function takeToken(keyHash: string): Promise<boolean> {
  const res = await rest("rpc/consume_rate_limit", {
    method: "POST",
    body: JSON.stringify({
      p_key: keyHash,
      p_capacity: envInt("FUEL_RATE_LIMIT_CAPACITY", 30),
      p_refill_per_sec: envInt("FUEL_RATE_LIMIT_PER_MIN", 30) / 60,
    }),
  });
  if (!res.ok) throw new Error(`rate limit failed: ${res.status}`);
  return (await res.json()) === true;
}

// ---------------------------------------------------------------------------
// Providers

async function fetchStations(lat: number, lng: number, radius: number) {
  const base = env("TANKERKOENIG_BASE_URL") || DEFAULT_TK_BASE;
  // Only the snapped point, the radius and the key are sent: no client headers, no IP, no user id.
  const url = `${base}/list.php?lat=${lat}&lng=${lng}&rad=${radius}&sort=dist&type=all` +
    `&apikey=${encodeURIComponent(env("TANKERKOENIG_API_KEY"))}`;
  const res = await fetch(url, {
    headers: { Accept: "application/json" },
    signal: AbortSignal.timeout(PROVIDER_TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`provider status ${res.status}`);
  const stations = parseStationList(await res.json());
  if (!stations) throw new Error("provider returned an unexpected body");
  return stations;
}

function toRows(
  scope: Scope,
  scopeKey: string,
  pricesByType: Record<FuelType, number[]>,
): CacheRow[] {
  const summary = summarize(pricesByType);
  const now = new Date().toISOString();
  const rows: CacheRow[] = [];
  for (const type of FUEL_TYPES) {
    const s = summary[type];
    if (s) {
      rows.push({
        type,
        scope,
        scope_key: scopeKey,
        price_milli: s.priceMilli,
        stations: s.stations,
        fetched_at: now,
        source: "tankerkoenig",
        observed_at: null,
        approximation: null,
      });
    }
  }
  return rows;
}

async function refreshArea(query: Query & { scope: "nearby" | "plz" }): Promise<CacheRow[]> {
  const area = providerArea(query);
  const stations = await fetchStations(area.lat, area.lng, area.radius);
  const { scope, scopeKey } = cacheKey(query);
  const rows = toRows(scope, scopeKey, pricesFromStations(stations));
  await writeCache(rows);
  return rows;
}

async function refreshNationalProvider(): Promise<CacheRow[]> {
  const pooled: Record<FuelType, number[]> = { e5: [], e10: [], diesel: [] };
  let ok = 0;
  for (const point of NATIONAL_SAMPLE) {
    try {
      const prices = pricesFromStations(
        await fetchStations(point.lat, point.lng, NATIONAL_SAMPLE_RADIUS_KM),
      );
      for (const type of FUEL_TYPES) pooled[type].push(...prices[type]);
      ok++;
    } catch (e) {
      console.error("national sample failed", (e as Error).message);
    }
  }
  if (ok < NATIONAL_MIN_SUCCESSFUL_SAMPLES) throw new Error("too few national samples");
  const rows = toRows("national", "de", pooled);
  await writeCache(rows);
  return rows;
}

async function refreshNationalBulletin(): Promise<CacheRow[]> {
  const res = await fetch(env("OIL_BULLETIN_URL") || DEFAULT_BULLETIN_URL, {
    signal: AbortSignal.timeout(PROVIDER_TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`bulletin status ${res.status}`);
  const prices = await parseBulletinXlsx(new Uint8Array(await res.arrayBuffer()), "Germany");
  const now = new Date().toISOString();
  const common = {
    scope: "national" as const,
    scope_key: "de-bulletin",
    stations: 0,
    fetched_at: now,
    source: "eu-oil-bulletin" as const,
    observed_at: prices.date.toISOString(),
  };
  const rows: CacheRow[] = [
    { ...common, type: "e5", price_milli: prices.e5Milli, approximation: null },
    { ...common, type: "diesel", price_milli: prices.dieselMilli, approximation: null },
    // The bulletin has no E10: serve the E5 value and say so.
    { ...common, type: "e10", price_milli: prices.e5Milli, approximation: "e5" },
  ];
  await writeCache(rows);
  return rows;
}

// ---------------------------------------------------------------------------
// Request handling

function json(body: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers },
  });
}

const fresh = (row: CacheRow | null, ttl: number): row is CacheRow =>
  row !== null && isFresh(Date.parse(row.fetched_at), Date.now(), ttl);

async function national(query: Query, force: boolean): Promise<CacheRow | "unavailable"> {
  const hasKey = env("TANKERKOENIG_API_KEY") !== "";
  const providerRow = hasKey ? await readCache(query.type, "national", "de") : null;
  const bulletinRow = await readCache(query.type, "national", "de-bulletin");
  const step = nationalStep({
    hasKey,
    providerFresh: fresh(providerRow, TTL_SECONDS.national),
    bulletinFresh: fresh(bulletinRow, TTL_SECONDS.bulletin),
    force,
  });
  if (step === "serve_provider") return providerRow!;
  if (step === "serve_bulletin") return bulletinRow!;
  if (step === "fetch_provider") {
    try {
      const rows = await refreshNationalProvider();
      const row = rows.find((r) => r.type === query.type);
      if (row) return row;
    } catch (e) {
      console.error("national provider refresh failed", (e as Error).message);
    }
    // Provider failed or has no data: a fresh bulletin value is still better than nothing.
    if (fresh(bulletinRow, TTL_SECONDS.bulletin)) return bulletinRow!;
  }
  try {
    const rows = await refreshNationalBulletin();
    return rows.find((r) => r.type === query.type)!;
  } catch (e) {
    console.error("bulletin refresh failed", (e as Error).message);
    return providerRow ?? bulletinRow ?? "unavailable";
  }
}

async function area(
  query: Query & { scope: "nearby" | "plz" },
): Promise<CacheRow | "unavailable" | "no_data"> {
  const { scope, scopeKey } = cacheKey(query);
  const cached = await readCache(query.type, scope, scopeKey);
  if (fresh(cached, TTL_SECONDS[scope])) return cached;
  try {
    const rows = await refreshArea(query);
    return rows.find((r) => r.type === query.type) ?? "no_data";
  } catch (e) {
    console.error("provider refresh failed", (e as Error).message);
    return cached ?? "unavailable";
  }
}

async function handle(req: Request): Promise<Response> {
  const cors = corsHeaders(req.headers.get("origin"), env("FUEL_ALLOWED_ORIGINS"));
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405, cors);

  const query = validateParams(new URL(req.url).searchParams);
  const warmToken = env("FUEL_WARM_TOKEN");
  const warm = warmToken !== "" &&
    constantTimeEquals(req.headers.get("x-fuel-warm") ?? "", warmToken);

  if (!warm) {
    try {
      const salt = env("FUEL_RATE_LIMIT_SALT") || env("SUPABASE_SERVICE_ROLE_KEY");
      if (!(await takeToken(await hashClient(clientIp(req.headers), salt)))) {
        return json({ error: "rate_limited" }, 429, { ...cors, "Retry-After": "60" });
      }
    } catch (e) {
      // A broken limiter must not take the feature down; the cache still bounds provider calls.
      console.error("rate limiter unavailable", (e as Error).message);
    }
  }
  if (!query) return json({ error: "invalid_params" }, 400, cors);

  if (query.scope !== "national" && env("TANKERKOENIG_API_KEY") === "") {
    return json({ error: "provider_unconfigured" }, 503, cors);
  }
  try {
    const result = query.scope === "national" ? await national(query, warm) : await area(query);
    if (result === "unavailable") {
      return json({ error: "provider_unavailable" }, 503, cors);
    }
    if (result === "no_data") return json({ error: "no_data" }, 404, cors);
    return json(shapeResponse(result), 200, { ...cors, "Cache-Control": "public, max-age=60" });
  } catch (e) {
    console.error("fuel-prices failed", (e as Error).message);
    return json({ error: "provider_unavailable" }, 503, cors);
  }
}

Deno.serve(handle);
