// Route distance API helpers (contract: docs/route-distance-api.md). Pure and DOM-free.

export const ROUTE_ATTRIBUTION = 'Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice';
export const MIN_QUERY = 3;
export const MAX_QUERY = 120;
export const MAX_SUGGESTIONS = 5;

export interface Place {
  label: string;
  lat: number;
  lng: number;
}

/** Whitespace collapsed and trimmed, like the server does; null while too short or too long to send. */
export function normalizeQuery(raw: string): string | null {
  const text = raw.replace(/\s+/g, ' ').trim();
  const length = [...text].length;
  return length >= MIN_QUERY && length <= MAX_QUERY ? text : null;
}

const isRecord = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null;

const attributionOf = (body: Record<string, unknown>): string => {
  const a = body['attribution'];
  return typeof a === 'string' && a.trim() !== '' ? a : ROUTE_ATTRIBUTION;
};

/** Validates a `suggest` response; null when the body is not usable. */
export function parseSuggestions(body: unknown): { places: Place[]; attribution: string } | null {
  if (!isRecord(body) || !Array.isArray(body['suggestions'])) return null;
  const places: Place[] = [];
  for (const raw of body['suggestions'] as unknown[]) {
    if (!isRecord(raw)) continue;
    const { label, lat, lng } = raw;
    if (typeof label !== 'string' || label.trim() === '') continue;
    if (typeof lat !== 'number' || !Number.isFinite(lat) || lat < -90 || lat > 90) continue;
    if (typeof lng !== 'number' || !Number.isFinite(lng) || lng < -180 || lng > 180) continue;
    places.push({ label: label.trim(), lat, lng });
    if (places.length === MAX_SUGGESTIONS) break;
  }
  return { places, attribution: attributionOf(body) };
}

/** Validates a `distance` response; null when the body is not usable. */
export function parseDistance(body: unknown): { meters: number; attribution: string } | null {
  if (!isRecord(body)) return null;
  const meters = body['meters'];
  if (typeof meters !== 'number' || !Number.isFinite(meters) || meters < 0) return null;
  return { meters, attribution: attributionOf(body) };
}

/** One-way kilometres rounded to 100 m, as the app does. */
export function metersToKm(meters: number): number {
  return Math.round(meters / 100) / 10;
}

/** Seconds from a Retry-After header; null when absent or not a plain number. */
export function parseRetryAfter(raw: string | null): number | null {
  if (raw === null || !/^\d{1,7}$/.test(raw.trim())) return null;
  return Number(raw.trim());
}
