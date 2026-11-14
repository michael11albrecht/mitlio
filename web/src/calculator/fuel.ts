// Live fuel price chips (PW-T04). Rendered by Calculator.astro only when FUEL_API_URL is configured.
// Privacy: no location unless the user taps "In meiner Nähe"; coordinates are rounded to 2 decimals
// before sending; the only network target is the configured API. Any failure just hides the chips.
import { calculatorMessages, type CalculatorMessageKey } from '../i18n/calculator';
import { fill, formatField, parseDecimal, type Locale } from './core';
import {
  FUEL_TYPES,
  formatAsOf,
  formatChipPrice,
  fuelUrl,
  parseFuelPrice,
  parsePlz,
  type FuelPrice,
  type FuelQuery,
  type FuelType,
} from '../lib/fuel';

export interface FuelHooks {
  locale: Locale;
  /** True when the price field is a per-litre fuel price (fuel drive, not km-rate mode). */
  active: () => boolean;
  /** Current text of the price field. */
  currentPrice: () => string;
  /** Writes a price into the field and recalculates. */
  applyPrice: (text: string) => void;
}

type Failure = 'provider_unconfigured' | 'no_data' | 'rate_limited' | 'unavailable';
type Fetched = { ok: true; price: FuelPrice } | { ok: false; failure: Failure };

const FETCH_TIMEOUT_MS = 8000;

export function initFuel(hooks: FuelHooks): { sync: () => void } | null {
  const root = document.getElementById('calc-fuel');
  if (!root) return null;
  const api = root.dataset['api'] ?? '';
  const key = root.dataset['key'];
  if (api === '') return null;

  const { locale } = hooks;
  const m = calculatorMessages[locale];
  const chipEls = new Map<FuelType, HTMLButtonElement>();
  for (const t of FUEL_TYPES) {
    const el = root.querySelector<HTMLButtonElement>(`.chip[data-fuel="${t}"]`);
    if (el) chipEls.set(t, el);
  }
  const sourceEl = document.getElementById('calc-fuel-source') as HTMLElement;
  const statusEl = document.getElementById('calc-fuel-status') as HTMLElement;
  const whereEl = document.getElementById('calc-fuel-where') as HTMLElement;
  const nearbyBtn = document.getElementById('calc-fuel-nearby') as HTMLButtonElement;
  const plzGo = document.getElementById('calc-fuel-plz-go') as HTMLButtonElement;
  const plzInput = document.getElementById('calc-fuel-plz') as HTMLInputElement;

  const prices = new Map<FuelType, FuelPrice>();
  let started = false;
  let hasChips = false;
  let generation = 0;

  const status = (msg: CalculatorMessageKey | '') => {
    statusEl.textContent = msg === '' ? '' : m[msg];
  };

  const fetchOne = async (type: FuelType, query: FuelQuery): Promise<Fetched> => {
    const ctrl = new AbortController();
    const timer = window.setTimeout(() => ctrl.abort(), FETCH_TIMEOUT_MS);
    try {
      const headers: Record<string, string> = {};
      if (key) {
        headers['apikey'] = key;
        headers['Authorization'] = `Bearer ${key}`;
      }
      const res = await fetch(fuelUrl(api, type, query), {
        headers,
        signal: ctrl.signal,
        credentials: 'omit',
        referrerPolicy: 'no-referrer',
      });
      if (!res.ok) {
        const body: unknown = await res.json().catch(() => null);
        const code = typeof body === 'object' && body !== null ? (body as Record<string, unknown>)['error'] : null;
        if (res.status === 503 && code === 'provider_unconfigured') return { ok: false, failure: 'provider_unconfigured' };
        if (res.status === 404) return { ok: false, failure: 'no_data' };
        if (res.status === 429) return { ok: false, failure: 'rate_limited' };
        return { ok: false, failure: 'unavailable' };
      }
      const price = parseFuelPrice(await res.json(), type);
      return price ? { ok: true, price } : { ok: false, failure: 'unavailable' };
    } catch {
      return { ok: false, failure: 'unavailable' };
    } finally {
      window.clearTimeout(timer);
    }
  };

  const fetchAll = async (query: FuelQuery): Promise<{ got: FuelPrice[]; failure: Failure | null }> => {
    const results = await Promise.all(FUEL_TYPES.map((t) => fetchOne(t, query)));
    const got = results.flatMap((r) => (r.ok ? [r.price] : []));
    const failures = results.flatMap((r) => (r.ok ? [] : [r.failure]));
    // provider_unconfigured and no_data are about the area, so they win over transient errors.
    const failure =
      failures.find((f) => f === 'provider_unconfigured') ??
      failures.find((f) => f === 'no_data') ??
      failures.find((f) => f === 'rate_limited') ??
      failures[0] ??
      null;
    return { got, failure };
  };

  const scopeLabel = (p: FuelPrice, plz?: string): string => {
    if (p.scope === 'nearby') return m.fuelScopeNearby;
    if (p.scope === 'plz') return fill(m.fuelScopePlz, { plz: plz ?? '' });
    return m.fuelScopeNational;
  };

  const syncPressed = () => {
    const current = parseDecimal(hooks.currentPrice());
    for (const [type, el] of chipEls) {
      const p = prices.get(type);
      const pressed = current.kind === 'ok' && p !== undefined && Math.round(current.value * 1000) === p.priceMilli;
      el.setAttribute('aria-pressed', pressed ? 'true' : 'false');
    }
  };

  const show = (got: FuelPrice[], plz?: string) => {
    prices.clear();
    for (const p of got) prices.set(p.type, p);
    for (const [type, el] of chipEls) {
      const p = prices.get(type);
      el.hidden = p === undefined;
      if (!p) continue;
      const shown = `${p.approximation ? '≈' : ''}${formatChipPrice(p.priceMilli, locale)}`;
      (el.querySelector('.chip-price') as HTMLElement).textContent = shown;
      const name = (el.querySelector('.chip-name') as HTMLElement).textContent ?? '';
      // The accessible name must start with the visible text (WCAG 2.5.3), including the "≈".
      el.setAttribute('aria-label', fill(m.fuelChipAria, { fuel: name, price: shown }));
    }
    const first = got[0];
    hasChips = first !== undefined;
    if (first) {
      // Honest label: scope, age and the API's own attribution text.
      const parts = [
        scopeLabel(first, plz),
        fill(m.fuelAsOf, { when: formatAsOf(first, locale) }),
        first.attribution,
      ];
      if (got.some((p) => p.approximation)) parts.push(m.fuelApproxNote);
      sourceEl.textContent = parts.join(' · ');
      sourceEl.hidden = false;
    } else {
      sourceEl.textContent = '';
      sourceEl.hidden = true;
    }
    syncPressed();
    sync();
  };

  const failureKey = (f: Failure): CalculatorMessageKey =>
    f === 'no_data' ? 'fuelNoData' : f === 'rate_limited' ? 'fuelRateLimited' : f === 'provider_unconfigured' ? 'fuelRegionalOff' : 'fuelUnavailable';

  const regional = async (query: FuelQuery, plz?: string) => {
    const gen = ++generation;
    const { got, failure } = await fetchAll(query);
    if (gen !== generation) return;
    nearbyBtn.disabled = false;
    nearbyBtn.textContent = m.fuelNearby;
    if (got.length > 0) {
      status('');
      show(got, plz);
      return;
    }
    status(failureKey(failure ?? 'unavailable'));
    // The server has no provider key: regional lookups cannot work, so stop offering them.
    if (failure === 'provider_unconfigured') whereEl.hidden = true;
  };

  nearbyBtn.addEventListener('click', () => {
    if (!('geolocation' in navigator)) {
      status('fuelLocationUnavailable');
      return;
    }
    nearbyBtn.disabled = true;
    nearbyBtn.textContent = m.fuelNearbyBusy;
    status('');
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        void regional({ kind: 'nearby', lat: pos.coords.latitude, lng: pos.coords.longitude });
      },
      (err) => {
        nearbyBtn.disabled = false;
        nearbyBtn.textContent = m.fuelNearby;
        status(err.code === err.PERMISSION_DENIED ? 'fuelLocationDenied' : 'fuelLocationUnavailable');
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 600000 },
    );
  });

  const submitPlz = () => {
    const plz = parsePlz(plzInput.value);
    if (!plz) {
      status('fuelPlzInvalid');
      plzInput.setAttribute('aria-invalid', 'true');
      return;
    }
    plzInput.removeAttribute('aria-invalid');
    status('');
    void regional({ kind: 'plz', plz }, plz);
  };
  plzGo.addEventListener('click', submitPlz);
  plzInput.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    e.preventDefault(); // Enter must not submit the surrounding calculator form.
    submitPlz();
  });

  for (const [type, el] of chipEls) {
    el.addEventListener('click', () => {
      const p = prices.get(type);
      if (p) hooks.applyPrice(formatField(p.priceMilli / 1000, locale, 2));
    });
  }

  const loadNational = async () => {
    const gen = ++generation;
    const { got } = await fetchAll({ kind: 'national' });
    // A regional answer that arrived first wins; failure of the national average hides everything.
    if (gen !== generation) return;
    if (got.length > 0) show(got);
  };

  function sync() {
    const visible = hooks.active() && hasChips;
    root!.hidden = !visible;
    if (hooks.active() && !started) {
      started = true;
      void loadNational();
    }
    if (visible) syncPressed();
  }

  return { sync };
}
