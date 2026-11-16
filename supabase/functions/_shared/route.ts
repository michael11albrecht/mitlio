// Pure logic of the route-distance Edge Function (P9-T08). No Deno globals except WebCrypto and
// AbortSignal; all I/O (fetch, rate limiter, env) is injected so it is unit-testable.
// Contract: docs/route-distance-api.md.
//
// Privacy rules: the query text and the coordinates are used for exactly one provider call and
// are never logged, cached or stored. The provider only sees the Edge Function's egress IP.
// Rate-limit keys are salted hashes of the user id (or client address), never of the query.

export const ATTRIBUTION_ORS =
  "Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice";
export const ATTRIBUTION_GEOAPIFY =
  "Karten- und Routendaten © OpenStreetMap-Mitwirkende, via Geoapify";

export const MIN_TEXT = 3;
export const MAX_TEXT = 120;
export const MAX_SUGGESTIONS = 5;
export const PROVIDER_TIMEOUT_MS = 6000;
/** Longest plausible answer; the providers refuse routes beyond about 6000 km anyway. */
export const MAX_METERS = 6_000_000;

export interface Coord {
  lat: number;
  lng: number;
}
export interface Suggestion extends Coord {
  label: string;
}

export type RouteRequest =
  | { action: "suggest"; text: string; lang: "de" | "en" }
  | { action: "distance"; from: Coord; to: Coord };

// ---------------------------------------------------------------------------
// Validation

function isCoord(v: unknown): v is Coord {
  if (typeof v !== "object" || v === null) return false;
  const { lat, lng } = v as Record<string, unknown>;
  return typeof lat === "number" && typeof lng === "number" && Number.isFinite(lat) &&
    Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

/** Strict request validation; null means 400. Unknown actions and shapes are rejected. */
export function validateRequest(body: unknown): RouteRequest | null {
  if (typeof body !== "object" || body === null || Array.isArray(body)) return null;
  const b = body as Record<string, unknown>;
  if (b.action === "suggest") {
    if (typeof b.text !== "string") return null;
    const text = b.text.replace(/\s+/g, " ").trim();
    // Count code points, not UTF-16 units, so umlauts and emoji are not double-counted.
    const length = [...text].length;
    if (length < MIN_TEXT || length > MAX_TEXT) return null;
    // Control characters have no place in an address.
    if ([...text].some((c) => c.charCodeAt(0) < 32 || c.charCodeAt(0) === 127)) return null;
    return { action: "suggest", text, lang: b.lang === "en" ? "en" : "de" };
  }
  if (b.action === "distance") {
    if (!isCoord(b.from) || !isCoord(b.to)) return null;
    return {
      action: "distance",
      from: { lat: b.from.lat, lng: b.from.lng },
      to: { lat: b.to.lat, lng: b.to.lng },
    };
  }
  return null;
}

// ---------------------------------------------------------------------------
// Provider adapters

export type ProviderFailure = "unavailable" | "no_route";

/** Thrown by adapters. `unavailable` lets the next provider try; `no_route` is a final answer. */
export class ProviderError extends Error {
  constructor(public readonly kind: ProviderFailure, message: string) {
    super(message);
  }
}

export interface RouteProvider {
  readonly name: "openrouteservice" | "geoapify";
  readonly attribution: string;
  suggest(text: string, lang: "de" | "en"): Promise<Suggestion[]>;
  /** Driving distance in metres, fastest route. */
  distance(from: Coord, to: Coord): Promise<number>;
}

export type Fetch = (input: string, init?: RequestInit) => Promise<Response>;

async function call(fetcher: Fetch, url: string, init: RequestInit): Promise<Response> {
  try {
    return await fetcher(url, { ...init, signal: AbortSignal.timeout(PROVIDER_TIMEOUT_MS) });
  } catch {
    // The message of a fetch error can contain the URL (and with it the query): drop it.
    throw new ProviderError("unavailable", "provider unreachable");
  }
}

async function readJson(res: Response): Promise<unknown> {
  try {
    return await res.json();
  } catch {
    throw new ProviderError("unavailable", "provider returned a non-JSON body");
  }
}

const isNum = (v: unknown): v is number => typeof v === "number" && Number.isFinite(v);
const round6 = (n: number): number => Math.round(n * 1e6) / 1e6;

function cleanLabel(label: unknown): string | null {
  if (typeof label !== "string") return null;
  const s = label.replace(/\s+/g, " ").trim();
  return s === "" ? null : s.slice(0, 160);
}

function pushUnique(out: Suggestion[], s: Suggestion): void {
  if (!out.some((o) => o.label === s.label)) out.push(s);
}

// deno-lint-ignore no-explicit-any
type Json = any;

export function parseOrsSuggestions(body: unknown): Suggestion[] {
  const features = (body as Json)?.features;
  if (!Array.isArray(features)) throw new ProviderError("unavailable", "unexpected suggest body");
  const out: Suggestion[] = [];
  for (const f of features) {
    const coords = f?.geometry?.coordinates;
    const label = cleanLabel(f?.properties?.label);
    if (!Array.isArray(coords) || !isNum(coords[0]) || !isNum(coords[1]) || !label) continue;
    pushUnique(out, { label, lat: round6(coords[1]), lng: round6(coords[0]) });
    if (out.length === MAX_SUGGESTIONS) break;
  }
  return out;
}

export function parseGeoapifySuggestions(body: unknown): Suggestion[] {
  const features = (body as Json)?.features;
  if (!Array.isArray(features)) throw new ProviderError("unavailable", "unexpected suggest body");
  const out: Suggestion[] = [];
  for (const f of features) {
    const p = f?.properties;
    const label = cleanLabel(p?.formatted);
    if (!isNum(p?.lat) || !isNum(p?.lon) || !label) continue;
    pushUnique(out, { label, lat: round6(p.lat), lng: round6(p.lon) });
    if (out.length === MAX_SUGGESTIONS) break;
  }
  return out;
}

function checkDistance(meters: unknown): number {
  if (!isNum(meters) || meters < 0 || meters > MAX_METERS) {
    throw new ProviderError("unavailable", "unusable distance");
  }
  return Math.round(meters);
}

export function orsProvider(apiKey: string, fetcher: Fetch, baseUrl?: string): RouteProvider {
  const base = baseUrl || "https://api.openrouteservice.org";
  return {
    name: "openrouteservice",
    attribution: ATTRIBUTION_ORS,
    async suggest(text, lang) {
      const url = `${base}/geocode/autocomplete?size=${MAX_SUGGESTIONS}` +
        `&lang=${lang}&text=${encodeURIComponent(text)}`;
      const res = await call(fetcher, url, {
        headers: { Authorization: apiKey, Accept: "application/json" },
      });
      if (!res.ok) throw new ProviderError("unavailable", `ors suggest status ${res.status}`);
      return parseOrsSuggestions(await readJson(res));
    },
    async distance(from, to) {
      const res = await call(fetcher, `${base}/v2/directions/driving-car`, {
        method: "POST",
        headers: {
          Authorization: apiKey,
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          coordinates: [[from.lng, from.lat], [to.lng, to.lat]],
          preference: "fastest",
          units: "m",
        }),
      });
      // ORS answers 404 for "no routable point nearby" and 400 for "route not possible".
      if (res.status === 404 || res.status === 400) {
        throw new ProviderError("no_route", `ors route status ${res.status}`);
      }
      if (!res.ok) throw new ProviderError("unavailable", `ors route status ${res.status}`);
      const distance = ((await readJson(res)) as Json)?.routes?.[0]?.summary?.distance;
      if (distance === undefined) throw new ProviderError("no_route", "no route in answer");
      return checkDistance(distance);
    },
  };
}

export function geoapifyProvider(apiKey: string, fetcher: Fetch, baseUrl?: string): RouteProvider {
  const base = baseUrl || "https://api.geoapify.com";
  return {
    name: "geoapify",
    attribution: ATTRIBUTION_GEOAPIFY,
    async suggest(text, lang) {
      const url = `${base}/v1/geocode/autocomplete?limit=${MAX_SUGGESTIONS}&format=geojson` +
        `&lang=${lang}&text=${encodeURIComponent(text)}&apiKey=${encodeURIComponent(apiKey)}`;
      const res = await call(fetcher, url, { headers: { Accept: "application/json" } });
      if (!res.ok) throw new ProviderError("unavailable", `geoapify suggest status ${res.status}`);
      return parseGeoapifySuggestions(await readJson(res));
    },
    async distance(from, to) {
      // `balanced` is Geoapify's fastest-leaning mode (the others are `short`, `less_maneuvers`).
      const url = `${base}/v1/routing?mode=drive&type=balanced&units=metric` +
        `&waypoints=${from.lat},${from.lng}|${to.lat},${to.lng}` +
        `&apiKey=${encodeURIComponent(apiKey)}`;
      const res = await call(fetcher, url, { headers: { Accept: "application/json" } });
      if (res.status === 400 || res.status === 404) {
        throw new ProviderError("no_route", `geoapify route status ${res.status}`);
      }
      if (!res.ok) throw new ProviderError("unavailable", `geoapify route status ${res.status}`);
      const distance = ((await readJson(res)) as Json)?.features?.[0]?.properties?.distance;
      if (distance === undefined) throw new ProviderError("no_route", "no route in answer");
      return checkDistance(distance);
    },
  };
}

/**
 * Providers in the order they are tried. `ROUTE_PROVIDER` is a comma separated list
 * (`openrouteservice,geoapify`, `geoapify`, ...; `ors` is accepted as a short name). Unset: ORS
 * first, then Geoapify. A provider without its key is skipped, so switching is a secret change,
 * not an app update.
 */
export function selectProviders(env: (name: string) => string, fetcher: Fetch): RouteProvider[] {
  const order = (env("ROUTE_PROVIDER") || "openrouteservice,geoapify")
    .split(",").map((s) => s.trim().toLowerCase()).filter((s) => s !== "");
  const out: RouteProvider[] = [];
  for (const name of order) {
    if ((name === "openrouteservice" || name === "ors") && env("ORS_API_KEY") !== "") {
      out.push(orsProvider(env("ORS_API_KEY"), fetcher, env("ORS_BASE_URL")));
    } else if (name === "geoapify" && env("GEOAPIFY_API_KEY") !== "") {
      out.push(geoapifyProvider(env("GEOAPIFY_API_KEY"), fetcher, env("GEOAPIFY_BASE_URL")));
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Rate limiting

export interface Bucket {
  key: string;
  capacity: number;
  refillPerSec: number;
  /** Seconds to tell the client to wait when this bucket is empty. */
  retryAfter: number;
}

export function envInt(raw: string, fallback: number): number {
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
}

/** Seconds until the next UTC midnight (at least 1). */
export function secondsToUtcMidnight(now: number): number {
  const d = new Date(now);
  const next = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + 1);
  return Math.max(1, Math.ceil((next - now) / 1000));
}

/**
 * Buckets one request must pass, in order: the per-user minute bucket, then the global daily
 * budget (kept below the provider quota so the free tier is never exceeded). Reuses
 * `consume_rate_limit` (migration 0005) unchanged: the daily budget is a bucket that never
 * refills and gets a new key every UTC day.
 */
export function bucketsFor(
  action: RouteRequest["action"],
  userHash: string,
  now: number,
  env: (name: string) => string,
): Bucket[] {
  const perMin = action === "suggest"
    ? envInt(env("ROUTE_SUGGEST_PER_MIN"), 30)
    : envInt(env("ROUTE_DISTANCE_PER_MIN"), 10);
  const daily = action === "suggest"
    ? envInt(env("ROUTE_SUGGEST_DAILY"), 1000)
    : envInt(env("ROUTE_DISTANCE_DAILY"), 1500);
  const day = new Date(now).toISOString().slice(0, 10);
  return [
    {
      key: `route:${action}:u:${userHash}`,
      capacity: Math.min(perMin, 10000),
      refillPerSec: Math.min(perMin, 10000) / 60,
      retryAfter: 60,
    },
    {
      key: `route:${action}:global:${day}`,
      capacity: Math.min(daily, 10000),
      refillPerSec: 0,
      retryAfter: secondsToUtcMidnight(now),
    },
  ];
}

/** `sub` of a JWT, without verifying it (the platform gateway already did). Null when absent. */
export function jwtSubject(authorization: string | null): string | null {
  const token = authorization?.replace(/^Bearer\s+/i, "").trim();
  const payload = token?.split(".")[1];
  if (!payload) return null;
  try {
    const b64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const json = JSON.parse(atob(b64.padEnd(Math.ceil(b64.length / 4) * 4, "=")));
    return typeof json.sub === "string" && json.sub !== "" ? json.sub : null;
  } catch {
    return null;
  }
}

export function clientIp(headers: Headers): string {
  const cf = headers.get("cf-connecting-ip")?.trim();
  if (cf) return cf;
  const xff = headers.get("x-forwarded-for")?.split(",")[0].trim();
  return xff || "unknown";
}

export async function hashClient(id: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}|route|${id}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

// ---------------------------------------------------------------------------
// CORS and responses

export function corsHeaders(origin: string | null, allowlist: string): Record<string, string> {
  const allowed = allowlist.split(",").map((s) => s.trim()).filter((s) => s !== "");
  if (!origin || !allowed.includes(origin)) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function json(body: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    // Never cacheable: the body is one user's query result.
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...headers,
    },
  });
}

// ---------------------------------------------------------------------------
// Handler

export interface Deps {
  env: (name: string) => string;
  fetch: Fetch;
  /** Takes one token from the bucket; false when empty. Throws when the limiter is broken. */
  takeToken: (bucket: Bucket) => Promise<boolean>;
  now: () => number;
  /** Receives non-sensitive failure notes only (never request content). */
  log?: (message: string) => void;
}

export async function handleRoute(req: Request, deps: Deps): Promise<Response> {
  const cors = corsHeaders(req.headers.get("origin"), deps.env("ROUTE_ALLOWED_ORIGINS"));
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405, cors);

  let body: unknown = null;
  try {
    body = await req.json();
  } catch {
    // stays null: answered as invalid_params below
  }
  const request = validateRequest(body);
  if (!request) return json({ error: "invalid_params" }, 400, cors);

  const providers = selectProviders(deps.env, deps.fetch);
  if (providers.length === 0) return json({ error: "provider_unconfigured" }, 503, cors);

  const salt = deps.env("ROUTE_RATE_LIMIT_SALT") || deps.env("SUPABASE_SERVICE_ROLE_KEY");
  const who = jwtSubject(req.headers.get("authorization")) ?? clientIp(req.headers);
  const userHash = await hashClient(who, salt);
  try {
    for (const bucket of bucketsFor(request.action, userHash, deps.now(), deps.env)) {
      if (!(await deps.takeToken(bucket))) {
        return json({ error: "rate_limited" }, 429, {
          ...cors,
          "Retry-After": String(bucket.retryAfter),
        });
      }
    }
  } catch {
    // Fail closed: a broken limiter must not let the provider quota run dry.
    deps.log?.("rate limiter unavailable");
    return json({ error: "provider_unavailable" }, 503, cors);
  }

  for (const provider of providers) {
    try {
      if (request.action === "suggest") {
        const suggestions = await provider.suggest(request.text, request.lang);
        return json({ suggestions, attribution: provider.attribution }, 200, cors);
      }
      const meters = await provider.distance(request.from, request.to);
      return json({ meters, attribution: provider.attribution }, 200, cors);
    } catch (e) {
      if (!(e instanceof ProviderError)) throw e;
      // Only provider name and failure class are logged, never text or coordinates.
      deps.log?.(`${provider.name} ${request.action} failed: ${e.kind}`);
      if (e.kind === "no_route") return json({ error: "no_route" }, 404, cors);
    }
  }
  return json({ error: "provider_unavailable" }, 503, cors);
}
