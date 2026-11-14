// Pure logic of the fuel-prices Edge Function (P6c-T03, T06). No I/O, no Deno globals except
// WebCrypto, so it is unit-testable and mutation-testable. Contract: docs/fuel-prices-api.md.
//
// Privacy rule: exact user coordinates never leave this module's callers. `snapToCell` reduces
// them to the centre of a geohash precision-6 cell (~1.2 km x 0.6 km) and only that point is
// used for the provider query and the cache key.

export type FuelType = "e5" | "e10" | "diesel";
export type Scope = "nearby" | "plz" | "national";
export type Source = "tankerkoenig" | "eu-oil-bulletin";

export const FUEL_TYPES: readonly FuelType[] = ["e5", "e10", "diesel"];

export type Query =
  | { type: FuelType; scope: "nearby"; lat: number; lng: number; radius: number }
  | { type: FuelType; scope: "plz"; plz: string }
  | { type: FuelType; scope: "national" };

export const ATTRIBUTION: Record<Source, string> = {
  tankerkoenig: "Daten: MTS-K via Tankerkönig (CC BY 4.0)",
  "eu-oil-bulletin": "Quelle: EU Weekly Oil Bulletin",
};

export const GEOHASH_PRECISION = 6;
export const DEFAULT_RADIUS_KM = 5;

/** Cache TTLs in seconds. */
export const TTL_SECONDS = {
  nearby: 600,
  plz: 1800,
  national: 3600,
  bulletin: 43_200,
} as const;

// ---------------------------------------------------------------------------
// Validation

const DECIMAL = /^-?\d{1,3}(\.\d{1,10})?$/;

function parseCoordinate(raw: string | null, limit: number): number | null {
  if (raw === null || !DECIMAL.test(raw)) return null;
  const value = Number(raw);
  return Math.abs(value) <= limit ? value : null;
}

export function validateParams(params: URLSearchParams): Query | null {
  const type = params.get("type");
  if (type !== "e5" && type !== "e10" && type !== "diesel") return null;
  const hasLat = params.has("lat");
  const hasLng = params.has("lng");
  const plz = params.get("plz");

  if (plz !== null) {
    if (hasLat || hasLng || params.has("radius")) return null;
    if (!/^\d{5}$/.test(plz) || plzCoordinate(plz) === null) return null;
    return { type, scope: "plz", plz };
  }
  if (hasLat || hasLng) {
    const lat = parseCoordinate(params.get("lat"), 90);
    const lng = parseCoordinate(params.get("lng"), 180);
    if (lat === null || lng === null) return null;
    let radius = DEFAULT_RADIUS_KM;
    if (params.has("radius")) {
      const raw = params.get("radius")!;
      if (!/^\d{1,2}(\.\d{1,3})?$/.test(raw)) return null;
      radius = Number(raw);
      if (radius < 1 || radius > 10) return null;
      radius = Math.round(radius);
    }
    return { type, scope: "nearby", lat, lng, radius };
  }
  if (params.has("radius")) return null;
  return { type, scope: "national" };
}

// ---------------------------------------------------------------------------
// Geohash (precision 6) and coordinate snapping

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

export function geohashEncode(lat: number, lng: number, precision = GEOHASH_PRECISION): string {
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let hash = "";
  let bits = 0;
  let index = 0;
  let evenBit = true;
  while (hash.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        index = index * 2 + 1;
        lngMin = mid;
      } else {
        index = index * 2;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        index = index * 2 + 1;
        latMin = mid;
      } else {
        index = index * 2;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (++bits === 5) {
      hash += BASE32[index];
      bits = 0;
      index = 0;
    }
  }
  return hash;
}

export function geohashCenter(hash: string): { lat: number; lng: number } {
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  let evenBit = true;
  for (const ch of hash) {
    const value = BASE32.indexOf(ch);
    for (let bit = 4; bit >= 0; bit--) {
      const on = ((value >> bit) & 1) === 1;
      if (evenBit) {
        const mid = (lngMin + lngMax) / 2;
        if (on) lngMin = mid;
        else lngMax = mid;
      } else {
        const mid = (latMin + latMax) / 2;
        if (on) latMin = mid;
        else latMax = mid;
      }
      evenBit = !evenBit;
    }
  }
  return { lat: (latMin + latMax) / 2, lng: (lngMin + lngMax) / 2 };
}

/** The ~1 km cell containing the point: its hash and its centre (rounded to 5 decimals). */
export function snapToCell(lat: number, lng: number): { hash: string; lat: number; lng: number } {
  const hash = geohashEncode(lat, lng);
  const c = geohashCenter(hash);
  return { hash, lat: Number(c.lat.toFixed(5)), lng: Number(c.lng.toFixed(5)) };
}

// ---------------------------------------------------------------------------
// PLZ zones and national sample (approximate main-city coordinates; never user data)

const PLZ_ZONES: Record<string, [number, number]> = {
  "01": [51.05, 13.74],
  "02": [51.15, 14.99],
  "03": [51.76, 14.33],
  "04": [51.34, 12.37],
  "06": [51.48, 11.97],
  "07": [50.88, 12.08],
  "08": [50.72, 12.49],
  "09": [50.83, 12.92],
  "10": [52.52, 13.4],
  "12": [52.47, 13.43],
  "13": [52.57, 13.35],
  "14": [52.4, 13.06],
  "15": [52.35, 14.55],
  "16": [52.83, 13.81],
  "17": [53.56, 13.26],
  "18": [54.09, 12.13],
  "19": [53.63, 11.41],
  "20": [53.55, 9.99],
  "21": [53.25, 10.41],
  "22": [53.58, 10.05],
  "23": [53.87, 10.69],
  "24": [54.32, 10.14],
  "25": [54.48, 9.05],
  "26": [53.14, 8.21],
  "27": [53.54, 8.58],
  "28": [53.08, 8.8],
  "29": [52.62, 10.08],
  "30": [52.37, 9.74],
  "31": [52.15, 9.95],
  "32": [52.11, 8.67],
  "33": [52.02, 8.53],
  "34": [51.31, 9.48],
  "35": [50.58, 8.67],
  "36": [50.55, 9.68],
  "37": [51.53, 9.93],
  "38": [52.27, 10.52],
  "39": [52.13, 11.63],
  "40": [51.23, 6.78],
  "41": [51.19, 6.44],
  "42": [51.26, 7.15],
  "44": [51.51, 7.47],
  "45": [51.46, 7.01],
  "46": [51.47, 6.85],
  "47": [51.43, 6.76],
  "48": [51.96, 7.63],
  "49": [52.28, 8.05],
  "50": [50.94, 6.96],
  "51": [50.96, 7.0],
  "52": [50.78, 6.08],
  "53": [50.74, 7.1],
  "54": [49.75, 6.64],
  "55": [50.0, 8.27],
  "56": [50.36, 7.59],
  "57": [50.87, 8.02],
  "58": [51.36, 7.47],
  "59": [51.68, 7.82],
  "60": [50.11, 8.68],
  "61": [50.23, 8.61],
  "63": [50.1, 8.76],
  "64": [49.87, 8.65],
  "65": [50.08, 8.24],
  "66": [49.24, 7.0],
  "67": [49.48, 8.44],
  "68": [49.49, 8.47],
  "69": [49.4, 8.69],
  "70": [48.78, 9.18],
  "71": [48.68, 9.01],
  "72": [48.52, 9.06],
  "73": [48.7, 9.65],
  "74": [49.14, 9.22],
  "75": [48.89, 8.7],
  "76": [49.01, 8.4],
  "77": [48.47, 7.94],
  "78": [48.06, 8.46],
  "79": [47.99, 7.85],
  "80": [48.14, 11.58],
  "81": [48.13, 11.6],
  "82": [48.0, 11.34],
  "83": [47.86, 12.12],
  "84": [48.54, 12.15],
  "85": [48.76, 11.42],
  "86": [48.37, 10.9],
  "87": [47.73, 10.31],
  "88": [47.78, 9.61],
  "89": [48.4, 9.99],
  "90": [49.45, 11.08],
  "91": [49.6, 11.0],
  "92": [49.44, 11.86],
  "93": [49.01, 12.1],
  "94": [48.57, 13.46],
  "95": [49.94, 11.58],
  "96": [49.89, 10.89],
  "97": [49.79, 9.95],
  "98": [50.61, 10.69],
  "99": [50.98, 11.03],
};

/** Main-city coordinate of the two-digit PLZ zone, or null for zones that do not exist. */
export function plzCoordinate(plz: string): { lat: number; lng: number } | null {
  const zone = PLZ_ZONES[plz.slice(0, 2)];
  return zone ? { lat: zone[0], lng: zone[1] } : null;
}

/** State capitals; the national average is the median over all open stations around them. */
export const NATIONAL_SAMPLE: readonly { lat: number; lng: number }[] = [
  { lat: 48.78, lng: 9.18 },
  { lat: 48.14, lng: 11.58 },
  { lat: 52.52, lng: 13.4 },
  { lat: 52.4, lng: 13.06 },
  { lat: 53.08, lng: 8.8 },
  { lat: 53.55, lng: 9.99 },
  { lat: 50.08, lng: 8.24 },
  { lat: 53.63, lng: 11.41 },
  { lat: 52.37, lng: 9.74 },
  { lat: 51.23, lng: 6.78 },
  { lat: 50.0, lng: 8.27 },
  { lat: 49.24, lng: 7.0 },
  { lat: 51.05, lng: 13.74 },
  { lat: 52.13, lng: 11.63 },
  { lat: 54.32, lng: 10.14 },
  { lat: 50.98, lng: 11.03 },
];
export const NATIONAL_SAMPLE_RADIUS_KM = 10;
export const NATIONAL_MIN_SUCCESSFUL_SAMPLES = 8;

// ---------------------------------------------------------------------------
// Cache keys and provider request

export function cacheKey(query: Query): { scope: Scope; scopeKey: string } {
  switch (query.scope) {
    case "nearby":
      return {
        scope: "nearby",
        scopeKey: `${geohashEncode(query.lat, query.lng)}:${query.radius}`,
      };
    case "plz":
      return { scope: "plz", scopeKey: query.plz };
    case "national":
      return { scope: "national", scopeKey: "de" };
  }
}

/** The only location data the provider ever sees: a cell centre or a fixed city coordinate. */
export function providerArea(
  query: Query & { scope: "nearby" | "plz" },
): { lat: number; lng: number; radius: number } {
  if (query.scope === "nearby") {
    const cell = snapToCell(query.lat, query.lng);
    return { lat: cell.lat, lng: cell.lng, radius: query.radius };
  }
  const c = plzCoordinate(query.plz)!;
  return { lat: c.lat, lng: c.lng, radius: NATIONAL_SAMPLE_RADIUS_KM };
}

// ---------------------------------------------------------------------------
// Provider data -> prices

export function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = sorted.length >> 1;
  return sorted.length % 2 === 1 ? sorted[mid] : Math.round((sorted[mid - 1] + sorted[mid]) / 2);
}

/** EUR per litre as sent by Tankerkönig (e.g. 1.799) -> integer milli-EUR, or null if unusable. */
export function toPriceMilli(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  const milli = Math.round(value * 1000);
  return milli >= 500 && milli <= 5000 ? milli : null;
}

/** Validates a Tankerkönig list.php body; returns its stations or null. */
export function parseStationList(body: unknown): Record<string, unknown>[] | null {
  if (typeof body !== "object" || body === null) return null;
  const b = body as Record<string, unknown>;
  if (b.ok !== true || !Array.isArray(b.stations)) return null;
  return b.stations.filter((s): s is Record<string, unknown> =>
    typeof s === "object" && s !== null
  );
}

/** Prices (milli) of the open stations that report `type`. */
export function openStationPrices(
  stations: Record<string, unknown>[],
  type: FuelType,
): number[] {
  const out: number[] = [];
  for (const s of stations) {
    if (s.isOpen !== true) continue;
    const price = toPriceMilli(s[type]);
    if (price !== null) out.push(price);
  }
  return out;
}

export interface Summary {
  priceMilli: number;
  stations: number;
}

export function summarize(
  pricesByType: Record<FuelType, number[]>,
): Record<FuelType, Summary | null> {
  const out = {} as Record<FuelType, Summary | null>;
  for (const type of FUEL_TYPES) {
    const prices = pricesByType[type];
    const m = median(prices);
    out[type] = m === null ? null : { priceMilli: m, stations: prices.length };
  }
  return out;
}

export function pricesFromStations(
  stations: Record<string, unknown>[],
): Record<FuelType, number[]> {
  return {
    e5: openStationPrices(stations, "e5"),
    e10: openStationPrices(stations, "e10"),
    diesel: openStationPrices(stations, "diesel"),
  };
}

// ---------------------------------------------------------------------------
// TTL and national source selection

export function isFresh(fetchedAtMs: number, nowMs: number, ttlSeconds: number): boolean {
  const age = nowMs - fetchedAtMs;
  return age >= 0 && age < ttlSeconds * 1000;
}

export type NationalStep =
  | "serve_provider"
  | "fetch_provider"
  | "serve_bulletin"
  | "fetch_bulletin";

/**
 * Which national source to use. With a provider key: the fresh Tankerkönig average, else refresh
 * it. Without a key (or after the refresh failed): the fresh bulletin value, else fetch it.
 * `force` (cron warm-up) skips both caches.
 */
export function nationalStep(opts: {
  hasKey: boolean;
  providerFresh: boolean;
  bulletinFresh: boolean;
  force: boolean;
}): NationalStep {
  if (opts.hasKey) return opts.providerFresh && !opts.force ? "serve_provider" : "fetch_provider";
  return opts.bulletinFresh && !opts.force ? "serve_bulletin" : "fetch_bulletin";
}

// ---------------------------------------------------------------------------
// Response shaping

export interface CacheRow {
  type: FuelType;
  scope: Scope;
  scope_key: string;
  price_milli: number;
  stations: number;
  fetched_at: string;
  source: Source;
  observed_at: string | null;
  approximation: "e5" | null;
}

export function shapeResponse(row: CacheRow): Record<string, unknown> {
  const body: Record<string, unknown> = {
    type: row.type,
    priceMilli: row.price_milli,
    source: row.source,
    scope: row.scope,
    fetchedAt: new Date(row.observed_at ?? row.fetched_at).toISOString(),
    stations: row.stations,
    attribution: ATTRIBUTION[row.source],
  };
  if (row.approximation) body.approximation = row.approximation;
  return body;
}

// ---------------------------------------------------------------------------
// CORS, client identity

export function allowedOrigin(origin: string | null, allowlist: string): string | null {
  if (!origin) return null;
  const allowed = allowlist.split(",").map((s) => s.trim()).filter((s) => s !== "");
  return allowed.includes(origin) ? origin : null;
}

export function corsHeaders(origin: string | null, allowlist: string): Record<string, string> {
  const allowed = allowedOrigin(origin, allowlist);
  if (!allowed) return {};
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

/** Client address as seen by the platform proxy. Used only to derive a salted hash. */
export function clientIp(headers: Headers): string {
  const cf = headers.get("cf-connecting-ip")?.trim();
  if (cf) return cf;
  const xff = headers.get("x-forwarded-for")?.split(",")[0].trim();
  return xff || "unknown";
}

/** sha256(ip + salt) as hex: the only form in which a client is ever stored. */
export async function hashClient(ip: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}|${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

export function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
