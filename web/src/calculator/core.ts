// Pure calculator logic: parsing, URL state, mapping to/from the domain facade. No DOM.
// All cost math lives in globalThis.mitlio.calculateTrip (packages/domain_web).
import type { CalculatorMessageKey } from '../i18n/calculator';

export type Locale = 'de' | 'en';
export type Energy = 'fuel' | 'ev';
export type FieldKey = 'km' | 'cons' | 'price' | 'persons' | 'extras';

/** Raw field text is kept as typed so the UI never reformats under the cursor. */
export interface CalcState {
  energy: Energy;
  km: string;
  cons: string;
  price: string;
  persons: string;
  extras: string;
  driverPays: boolean;
  roundTrip: boolean;
  /** Optional trip name ("Wofür?"), raw as typed; sanitised when it leaves the page. */
  trip: string;
}

export const MAX_PERSONS = 100;
export const MAX_TRIP_NAME = 60;

/** Trims, drops control characters, collapses whitespace and caps at 60 characters. */
export function sanitizeTripName(raw: string): string {
  return [...raw.replace(/[\p{Cc}\p{Cf}]/gu, ' ').replace(/\s+/g, ' ').trim()]
    .slice(0, MAX_TRIP_NAME)
    .join('')
    .trim();
}

export const energyDefaults: Record<Energy, { cons: string; price: string }> = {
  fuel: { cons: '7', price: '1.80' },
  ev: { cons: '18', price: '0.35' },
};

export function defaultState(energy: Energy = 'fuel'): CalcState {
  return {
    energy,
    km: '100',
    cons: energyDefaults[energy].cons,
    price: energyDefaults[energy].price,
    persons: '2',
    extras: '',
    driverPays: true,
    roundTrip: false,
    trip: '',
  };
}

export type Parsed =
  | { kind: 'ok'; value: number }
  | { kind: 'empty' }
  | { kind: 'invalid' }
  | { kind: 'negative' };

/**
 * Parses user text to a number. Accepts "," or "." as decimal separator and
 * "1.234,5" / "1,234.5" style grouping (the last separator is the decimal one).
 */
export function parseDecimal(raw: string): Parsed {
  let s = raw.replace(/[\s  ']/g, '');
  if (s === '') return { kind: 'empty' };
  let negative = false;
  if (s.startsWith('-') || s.startsWith('−')) {
    negative = true;
    s = s.slice(1);
  }
  const lastDot = s.lastIndexOf('.');
  const lastComma = s.lastIndexOf(',');
  const decimalAt = Math.max(lastDot, lastComma);
  let intPart = decimalAt === -1 ? s : s.slice(0, decimalAt);
  const fracPart = decimalAt === -1 ? '' : s.slice(decimalAt + 1);
  if (lastDot !== -1 && lastComma !== -1) {
    // Both present: the other one must be grouping.
    intPart = intPart.replace(/[.,]/g, '');
  } else if (/[.,]/.test(intPart)) {
    return { kind: 'invalid' };
  }
  if (!/^\d*$/.test(intPart) || !/^\d*$/.test(fracPart) || intPart + fracPart === '') {
    return { kind: 'invalid' };
  }
  const value = Number(`${intPart || '0'}.${fracPart || '0'}`);
  if (!Number.isFinite(value)) return { kind: 'invalid' };
  if (negative) return value === 0 ? { kind: 'ok', value: 0 } : { kind: 'negative' };
  return { kind: 'ok', value };
}

export function parsePersons(raw: string): number | null {
  const s = raw.trim();
  if (!/^\d{1,3}$/.test(s)) return null;
  const n = Number(s);
  return n >= 1 && n <= MAX_PERSONS ? n : null;
}

export type FieldErrors = Partial<Record<FieldKey, CalculatorMessageKey>>;

export interface TripInput {
  distanceKm: number;
  consumptionPer100km: number;
  pricePerUnit: number;
  persons: number;
  driverPays: boolean;
  roundTrip: boolean;
  tollsEur?: number;
}

const parseError = (p: Parsed): CalculatorMessageKey | null =>
  p.kind === 'empty'
    ? 'errRequired'
    : p.kind === 'invalid'
      ? 'errInvalid'
      : p.kind === 'negative'
        ? 'errNegative'
        : null;

/** Turns raw state into the facade input, or per-field errors. */
export function buildInput(state: CalcState): { input: TripInput } | { errors: FieldErrors } {
  const errors: FieldErrors = {};
  const num = (key: 'km' | 'cons' | 'price'): number => {
    const p = parseDecimal(state[key]);
    const err = parseError(p);
    if (err) errors[key] = err;
    return p.kind === 'ok' ? p.value : 0;
  };
  const distanceKm = num('km');
  const consumptionPer100km = num('cons');
  const pricePerUnit = num('price');
  const extras = parseDecimal(state.extras);
  const extrasErr = extras.kind === 'empty' ? null : parseError(extras);
  if (extrasErr) errors.extras = extrasErr;
  const persons = parsePersons(state.persons);
  if (persons === null) errors.persons = 'errPersons';
  if (persons === null || Object.keys(errors).length > 0) return { errors };
  return {
    input: {
      distanceKm,
      consumptionPer100km,
      pricePerUnit,
      persons,
      driverPays: state.driverPays,
      roundTrip: state.roundTrip,
      ...(extras.kind === 'ok' ? { tollsEur: extras.value } : {}),
    },
  };
}

export interface FacadeResult {
  ok: boolean;
  error?: string;
  field?: string;
  totalCents?: number;
  perPersonCents?: number[];
  breakdown?: { fuelCents: number; wearCents: number; tollsCents: number; ferryCents: number };
}

const facadeFieldToKey: Record<string, FieldKey> = {
  distanceKm: 'km',
  consumptionPer100km: 'cons',
  pricePerUnit: 'price',
  tollsEur: 'extras',
  extrasEur: 'extras',
  persons: 'persons',
};

/** Maps a failed facade result onto a field and calm message. */
export function mapFacadeError(res: FacadeResult, driverPays: boolean): FieldErrors {
  if (res.error === 'NonPositiveDistance') return { km: 'errDistance' };
  if (res.error === 'TripNoParticipants') {
    return { persons: driverPays ? 'errPersons' : 'errNeedPassenger' };
  }
  const key: FieldKey = (res.field && facadeFieldToKey[res.field]) || 'km';
  if (res.error === 'InvalidPersons') return { persons: 'errPersons' };
  if (res.error === 'TripNegativeValue') return { [key]: 'errNegative' };
  return { [key]: 'errTooLarge' };
}

export interface ResultView {
  /** Share per paying person, in cents (the larger one when rounding splits). */
  perPersonCents: number;
  /** Set when shares differ by cent rounding. */
  rounding: { high: number; nHigh: number; low: number; nLow: number } | null;
  /** Set when the driver does not pay: what the driver receives. */
  driverGetsCents: number | null;
  totalCents: number;
  fuelCents: number;
  extrasCents: number;
}

export function buildResultView(res: FacadeResult, driverPays: boolean): ResultView {
  const all = res.perPersonCents ?? [];
  const payers = driverPays ? all : all.slice(1);
  const high = Math.max(...payers);
  const low = Math.min(...payers);
  const nHigh = payers.filter((c) => c === high).length;
  const b = res.breakdown;
  return {
    perPersonCents: high,
    rounding: high === low ? null : { high, nHigh, low, nLow: payers.length - nHigh },
    driverGetsCents: driverPays ? null : (res.totalCents ?? 0),
    totalCents: res.totalCents ?? 0,
    fuelCents: (b?.fuelCents ?? 0) + (b?.wearCents ?? 0),
    extrasCents: (b?.tollsCents ?? 0) + (b?.ferryCents ?? 0),
  };
}

const intlTag = (l: Locale) => (l === 'de' ? 'de-DE' : 'en-IE');

export function formatMoney(cents: number, locale: Locale): string {
  return new Intl.NumberFormat(intlTag(locale), { style: 'currency', currency: 'EUR' }).format(
    cents / 100,
  );
}

/** Number for a text field in the locale's decimal style, without grouping. */
export function formatField(value: number, locale: Locale, minFraction = 0): string {
  return new Intl.NumberFormat(intlTag(locale), {
    useGrouping: false,
    minimumFractionDigits: minFraction,
    maximumFractionDigits: 3,
  }).format(value);
}

export function fill(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, k: string) => String(values[k] ?? ''));
}

// ---- URL state: ?km=&l100=&p=&n=&d=&rt=&x=&ev=&t= (numbers use "." as decimal separator) ----

export function stateToParams(state: CalcState): URLSearchParams {
  const params = new URLSearchParams();
  const put = (name: string, raw: string) => {
    const p = parseDecimal(raw);
    if (p.kind === 'ok') params.set(name, String(p.value));
  };
  put('km', state.km);
  put('l100', state.cons);
  put('p', state.price);
  const n = parsePersons(state.persons);
  if (n !== null) params.set('n', String(n));
  params.set('d', state.driverPays ? '1' : '0');
  params.set('rt', state.roundTrip ? '1' : '0');
  put('x', state.extras);
  if (state.energy === 'ev') params.set('ev', '1');
  const trip = sanitizeTripName(state.trip);
  if (trip !== '') params.set('t', trip);
  return params;
}

export function paramsToState(search: string): CalcState {
  const q = new URLSearchParams(search);
  const energy: Energy = q.get('ev') === '1' ? 'ev' : 'fuel';
  const state = defaultState(energy);
  const num = (name: string): string | null => {
    const raw = q.get(name);
    if (raw === null) return null;
    const p = parseDecimal(raw);
    return p.kind === 'ok' ? String(p.value) : null;
  };
  state.km = num('km') ?? state.km;
  state.cons = num('l100') ?? state.cons;
  state.price = num('p') ?? state.price;
  state.extras = num('x') ?? '';
  const n = q.get('n');
  if (n !== null && parsePersons(n) !== null) state.persons = n.trim();
  if (q.get('d') === '0') state.driverPays = false;
  if (q.get('rt') === '1') state.roundTrip = true;
  state.trip = sanitizeTripName(q.get('t') ?? '');
  return state;
}

/** Localises numeric strings of a state parsed from the URL for display. */
export function localizeState(state: CalcState, locale: Locale): CalcState {
  const loc = (raw: string, minFraction = 0) => {
    const p = parseDecimal(raw);
    return p.kind === 'ok' ? formatField(p.value, locale, minFraction) : raw;
  };
  return {
    ...state,
    km: loc(state.km),
    cons: loc(state.cons),
    price: loc(state.price, 2),
    extras: state.extras === '' ? '' : loc(state.extras),
  };
}

/** True when cons+price still equal the untouched defaults of `energy`. */
export function isUntouchedEnergyDefaults(state: CalcState, energy: Energy): boolean {
  const d = energyDefaults[energy];
  const c = parseDecimal(state.cons);
  const p = parseDecimal(state.price);
  return (
    c.kind === 'ok' && p.kind === 'ok' && c.value === Number(d.cons) && p.value === Number(d.price)
  );
}
