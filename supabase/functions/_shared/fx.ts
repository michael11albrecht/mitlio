// Pure logic of the fx-rates Edge Function (P7-T02). No I/O, no Deno globals, so it is
// unit-testable. Contract: docs/fx-rates-api.md. CORS, client hashing and the constant-time
// compare are shared with fuel-prices (_shared/fuel.ts).

export const ATTRIBUTION = "Quelle: EZB-Referenzkurse via Frankfurter";
export const SOURCE = "frankfurter";

/** A "latest" row is refreshed after this many seconds (ECB publishes once per working day). */
export const LATEST_TTL_SECONDS = 10_800;

/** The ECB series starts on 1999-01-04. */
export const EARLIEST_DATE = "1999-01-04";

/** Rates above this are rejected as garbage (1e6 major units per unit would be absurd). */
const MAX_RATE = 1_000_000;

export interface Query {
  base: string;
  quote: string;
  /** Requested day (`YYYY-MM-DD`), or null for the latest rate. */
  date: string | null;
}

export interface FxRow {
  base: string;
  quote: string;
  /** Cache key: the day that was asked for (today, UTC, for "latest"). */
  date: string;
  rate_ppm: number;
  /** The ECB working day the rate is from. */
  source_date: string;
  fetched_at: string;
}

// ---------------------------------------------------------------------------
// Dates

/** `YYYY-MM-DD` of an instant, in UTC. */
export function isoDay(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

/** Whether [text] is a real calendar day in `YYYY-MM-DD` form. */
export function isIsoDay(text: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) return false;
  const ms = Date.parse(`${text}T00:00:00Z`);
  return !Number.isNaN(ms) && isoDay(ms) === text;
}

// ---------------------------------------------------------------------------
// Validation

/**
 * `base` and `quote` are required three-letter upper-case codes and differ. `date` is optional,
 * a real day between 1999-01-04 and today (UTC). A date of today is the same as the latest rate.
 */
export function validateParams(params: URLSearchParams, nowMs: number): Query | null {
  const base = params.get("base");
  const quote = params.get("quote");
  if (base === null || quote === null) return null;
  if (!/^[A-Z]{3}$/.test(base) || !/^[A-Z]{3}$/.test(quote) || base === quote) return null;
  const date = params.get("date");
  if (date === null) return { base, quote, date: null };
  const today = isoDay(nowMs);
  if (!isIsoDay(date) || date < EARLIEST_DATE || date > today) return null;
  return { base, quote, date: date === today ? null : date };
}

/** The cache key day of a query: the asked-for day, or today for "latest". */
export function keyDate(query: Query, nowMs: number): string {
  return query.date ?? isoDay(nowMs);
}

// ---------------------------------------------------------------------------
// Provider response

/**
 * Decimal rate to parts per million, rounded half away from zero to a whole ppm
 * (0.92 -> 920000, 1.0869565 -> 1086957). Null when it is not a usable rate: not a finite
 * number, not positive, absurdly large, or so small that it rounds to 0 ppm.
 */
export function rateToPpm(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  if (value <= 0 || value > MAX_RATE) return null;
  const ppm = Math.round(value * 1_000_000);
  return ppm > 0 ? ppm : null;
}

/**
 * Reads a Frankfurter body (`{"amount":1,"base":"USD","date":"2025-11-14","rates":{"EUR":0.92}}`).
 * Null when it does not match the request or is malformed.
 */
export function parseFrankfurter(
  body: unknown,
  query: Query,
): { ppm: number; sourceDate: string } | null {
  if (typeof body !== "object" || body === null) return null;
  const b = body as Record<string, unknown>;
  if (b.base !== query.base) return null;
  if (typeof b.date !== "string" || !isIsoDay(b.date)) return null;
  if (typeof b.rates !== "object" || b.rates === null) return null;
  const ppm = rateToPpm((b.rates as Record<string, unknown>)[query.quote]);
  if (ppm === null) return null;
  return { ppm, sourceDate: b.date };
}

/** Provider path and query for a query: `latest` or the asked-for day (the provider answers the last working day). */
export function providerPath(query: Query): string {
  return `${query.date ?? "latest"}?from=${query.base}&to=${query.quote}`;
}

// ---------------------------------------------------------------------------
// Cache and response

/**
 * A cached row answers the query when it is for the same key day and, for "latest", younger
 * than the TTL. A row for a past day never changes, so it is served as long as it exists.
 */
export function isUsable(row: FxRow, query: Query, nowMs: number): boolean {
  if (query.date !== null) return row.date === query.date;
  if (row.date !== isoDay(nowMs)) return false;
  return nowMs - Date.parse(row.fetched_at) < LATEST_TTL_SECONDS * 1000;
}

export function shapeResponse(row: FxRow): Record<string, unknown> {
  return {
    base: row.base,
    quote: row.quote,
    date: row.source_date,
    ratePpm: row.rate_ppm,
    source: SOURCE,
    fetchedAt: new Date(row.fetched_at).toISOString(),
    attribution: ATTRIBUTION,
  };
}

/** The row to store for a provider answer. */
export function toRow(
  query: Query,
  parsed: { ppm: number; sourceDate: string },
  nowMs: number,
): FxRow {
  return {
    base: query.base,
    quote: query.quote,
    date: keyDate(query, nowMs),
    rate_ppm: parsed.ppm,
    source_date: parsed.sourceDate,
    fetched_at: new Date(nowMs).toISOString(),
  };
}
