// Fuel price API helpers (contract: docs/fuel-prices-api.md). Pure and DOM-free.
import type { Locale } from '../calculator/core';

export const FUEL_TYPES = ['e5', 'e10', 'diesel'] as const;
export type FuelType = (typeof FUEL_TYPES)[number];

export interface FuelPrice {
  type: FuelType;
  /** Thousandths of EUR per litre: 1.799 EUR/l is 1799. */
  priceMilli: number;
  source: 'tankerkoenig' | 'eu-oil-bulletin';
  scope: 'nearby' | 'plz' | 'national';
  fetchedAt: string;
  stations: number;
  attribution: string;
  /** True when the value for this type is an estimate taken from E5. */
  approximation: boolean;
}

export type FuelQuery =
  | { kind: 'national' }
  | { kind: 'nearby'; lat: number; lng: number }
  | { kind: 'plz'; plz: string };

/** Coordinates are rounded client-side to 2 decimals (about 1 km) before they leave the device. */
export function roundCoord(v: number): string {
  const s = (Math.round(v * 100) / 100).toFixed(2);
  return s === '-0.00' ? '0.00' : s;
}

/** A German postcode: exactly 5 digits. */
export function parsePlz(raw: string): string | null {
  const s = raw.trim();
  return /^\d{5}$/.test(s) ? s : null;
}

export function fuelUrl(base: string, type: FuelType, query: FuelQuery): string {
  const url = new URL(base);
  url.searchParams.set('type', type);
  if (query.kind === 'nearby') {
    url.searchParams.set('lat', roundCoord(query.lat));
    url.searchParams.set('lng', roundCoord(query.lng));
  } else if (query.kind === 'plz') {
    url.searchParams.set('plz', query.plz);
  }
  return url.toString();
}

/** Validates an API body; anything off-contract is "no live price" (null). */
export function parseFuelPrice(raw: unknown, expected: FuelType): FuelPrice | null {
  if (typeof raw !== 'object' || raw === null) return null;
  const r = raw as Record<string, unknown>;
  const { priceMilli, source, scope, fetchedAt, stations, attribution } = r;
  if (r['type'] !== expected) return null;
  if (typeof priceMilli !== 'number' || !Number.isInteger(priceMilli) || priceMilli < 200 || priceMilli > 9999) {
    return null;
  }
  if (source !== 'tankerkoenig' && source !== 'eu-oil-bulletin') return null;
  if (scope !== 'nearby' && scope !== 'plz' && scope !== 'national') return null;
  if (typeof fetchedAt !== 'string' || Number.isNaN(Date.parse(fetchedAt))) return null;
  if (typeof attribution !== 'string' || attribution === '') return null;
  return {
    type: expected,
    priceMilli,
    source,
    scope,
    fetchedAt,
    stations: typeof stations === 'number' ? stations : 0,
    attribution,
    approximation: r['approximation'] === 'e5',
  };
}

const intlTag = (l: Locale) => (l === 'de' ? 'de-DE' : 'en-IE');

/** "1,799 €": the chip text. Three decimals, as fuel is priced. */
export function formatChipPrice(milli: number, locale: Locale): string {
  const n = new Intl.NumberFormat(intlTag(locale), { minimumFractionDigits: 3, maximumFractionDigits: 3 }).format(
    milli / 1000,
  );
  return `${n} €`;
}

/** The "Stand" value: a time for a same-day provider fetch, else the date ("10.11." / "10 Nov"). */
export function formatAsOf(
  p: Pick<FuelPrice, 'source' | 'fetchedAt'>,
  locale: Locale,
  now: Date = new Date(),
): string {
  const at = new Date(p.fetchedAt);
  const timeZone = 'Europe/Berlin';
  const day = (d: Date) => new Intl.DateTimeFormat('en-CA', { timeZone }).format(d);
  if (p.source !== 'eu-oil-bulletin' && day(at) === day(now)) {
    return new Intl.DateTimeFormat(intlTag(locale), { timeZone, hour: '2-digit', minute: '2-digit' }).format(at);
  }
  if (locale === 'de') {
    const date = new Intl.DateTimeFormat('de-DE', { timeZone, day: '2-digit', month: '2-digit' }).format(at);
    return date.endsWith('.') ? date : `${date}.`;
  }
  return new Intl.DateTimeFormat('en-IE', { timeZone, day: 'numeric', month: 'short' }).format(at);
}
