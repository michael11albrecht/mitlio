// From-to route field (PW-T12). Rendered by Calculator.astro only when ROUTE_WEB=1 and an API is configured.
// Privacy: opt-in (collapsed row), nothing is sent on page load, typing is debounced and starts at 3 characters.
// The km field never depends on the service: a hand edit always wins (an answer that arrives after it is dropped),
// and every failure is shown in plain text next to the row (never silent).
import { calculatorMessages, type CalculatorMessageKey } from '../i18n/calculator';
import { fill, formatField, type Locale } from './core';
import { metersToKm, normalizeQuery, parseDistance, parseRetryAfter, parseSuggestions, type Place } from '../lib/route';

export interface RouteHooks {
  locale: Locale;
  /** Writes the kilometres into the km field and recalculates. */
  applyKm: (text: string) => void;
}

type Failure = 'offline' | 'rate_limited' | 'no_route' | 'unconfigured' | 'unavailable';
type Reply<T> = { ok: true; value: T } | { ok: false; failure: Failure; retryAfter: number | null };
type Side = 'from' | 'to';

const FETCH_TIMEOUT_MS = 8000;
export const DEBOUNCE_MS = 300;

export function initRoute(hooks: RouteHooks): void {
  const root = document.getElementById('calc-route');
  if (!root) return;
  const api = root.dataset['api'] ?? '';
  const key = root.dataset['key'];
  if (api === '') return;

  const { locale } = hooks;
  const m = calculatorMessages[locale];
  const kmInput = document.getElementById('calc-km') as HTMLInputElement;
  const statusEl = document.getElementById('calc-route-status') as HTMLElement;
  const attributionEl = document.getElementById('calc-route-attribution') as HTMLElement;
  const recalcBtn = document.getElementById('calc-route-recalc') as HTMLButtonElement;

  const inputs: Record<Side, HTMLInputElement> = {
    from: document.getElementById('calc-route-from') as HTMLInputElement,
    to: document.getElementById('calc-route-to') as HTMLInputElement,
  };
  const lists: Record<Side, HTMLElement> = {
    from: document.getElementById('calc-route-from-list') as HTMLElement,
    to: document.getElementById('calc-route-to-list') as HTMLElement,
  };
  const picked: Record<Side, Place | null> = { from: null, to: null };
  const timers: Record<Side, number | undefined> = { from: undefined, to: undefined };
  // Bumped by every new request and by every hand edit of the km field; an older answer is dropped.
  const suggestGen: Record<Side, number> = { from: 0, to: 0 };
  let distanceGen = 0;

  const say = (msg: CalculatorMessageKey | '', values: Record<string, string | number> = {}) => {
    statusEl.textContent = msg === '' ? '' : fill(m[msg], values);
  };

  const showAttribution = (text: string | null) => {
    attributionEl.textContent = text ?? '';
    attributionEl.hidden = text === null;
  };

  const when = (seconds: number): string => {
    const minutes = Math.max(1, Math.ceil(seconds / 60));
    if (minutes < 60) return minutes === 1 ? m.routeWhenMinute : fill(m.routeWhenMinutes, { n: minutes });
    const hours = Math.ceil(minutes / 60);
    return hours === 1 ? m.routeWhenHour : fill(m.routeWhenHours, { n: hours });
  };

  const failureMessage = (failure: Failure, retryAfter: number | null) => {
    switch (failure) {
      case 'offline':
        return say('routeOffline');
      case 'rate_limited':
        return retryAfter === null
          ? say('routeRateLimitedNoTime')
          : say('routeRateLimited', { when: when(retryAfter) });
      case 'no_route':
        return say('routeNoRoute');
      case 'unconfigured':
        return say('routeUnconfigured');
      default:
        return say('routeUnavailable');
    }
  };

  const post = async <T>(body: unknown, parse: (b: unknown) => T | null): Promise<Reply<T>> => {
    const ctrl = new AbortController();
    const timer = window.setTimeout(() => ctrl.abort(), FETCH_TIMEOUT_MS);
    try {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (key) {
        headers['apikey'] = key;
        headers['Authorization'] = `Bearer ${key}`;
      }
      const res = await fetch(api, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
        signal: ctrl.signal,
        credentials: 'omit',
        referrerPolicy: 'no-referrer',
      });
      if (!res.ok) {
        const data: unknown = await res.json().catch(() => null);
        const code = typeof data === 'object' && data !== null ? (data as Record<string, unknown>)['error'] : null;
        if (res.status === 429) return { ok: false, failure: 'rate_limited', retryAfter: parseRetryAfter(res.headers.get('retry-after')) };
        if (res.status === 404) return { ok: false, failure: 'no_route', retryAfter: null };
        if (res.status === 503 && code === 'provider_unconfigured') return { ok: false, failure: 'unconfigured', retryAfter: null };
        return { ok: false, failure: 'unavailable', retryAfter: null };
      }
      const value = parse(await res.json());
      return value === null ? { ok: false, failure: 'unavailable', retryAfter: null } : { ok: true, value };
    } catch {
      // A thrown fetch means the service was not reachable at all (no network, blocked, timeout).
      return { ok: false, failure: 'offline', retryAfter: null };
    } finally {
      window.clearTimeout(timer);
    }
  };

  const clearList = (side: Side) => {
    lists[side].replaceChildren();
    lists[side].hidden = true;
  };

  const updateRecalc = () => {
    recalcBtn.hidden = picked.from === null || picked.to === null;
  };

  const calculate = async () => {
    const { from, to } = picked;
    if (!from || !to) return;
    const gen = ++distanceGen;
    showAttribution(null);
    say('routeCalculating');
    const reply = await post({ action: 'distance', from: { lat: from.lat, lng: from.lng }, to: { lat: to.lat, lng: to.lng } }, parseDistance);
    if (gen !== distanceGen) return;
    if (!reply.ok) {
      failureMessage(reply.failure, reply.retryAfter);
      return;
    }
    const km = metersToKm(reply.value.meters);
    hooks.applyKm(formatField(km, locale));
    say('routeDone', { km: formatField(km, locale, 1) });
    showAttribution(reply.value.attribution);
  };

  const pick = (side: Side, place: Place) => {
    picked[side] = place;
    inputs[side].value = place.label;
    clearList(side);
    updateRecalc();
    void calculate();
  };

  const suggest = async (side: Side) => {
    const text = normalizeQuery(inputs[side].value);
    if (text === null) {
      clearList(side);
      say('');
      return;
    }
    const gen = ++suggestGen[side];
    say('routeSearching');
    const reply = await post({ action: 'suggest', text, lang: locale }, parseSuggestions);
    if (gen !== suggestGen[side]) return;
    if (!reply.ok) {
      clearList(side);
      failureMessage(reply.failure, reply.retryAfter);
      return;
    }
    const { places, attribution } = reply.value;
    clearList(side);
    if (places.length === 0) {
      say('routeNoMatch');
      return;
    }
    say('');
    showAttribution(attribution);
    for (const place of places) {
      const li = document.createElement('li');
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'route-option';
      btn.textContent = place.label;
      btn.addEventListener('click', () => pick(side, place));
      li.append(btn);
      lists[side].append(li);
    }
    lists[side].hidden = false;
  };

  for (const side of ['from', 'to'] as const) {
    inputs[side].addEventListener('input', () => {
      // Typing again invalidates the earlier pick and any answer still on its way.
      picked[side] = null;
      suggestGen[side] += 1;
      distanceGen += 1;
      updateRecalc();
      window.clearTimeout(timers[side]);
      if (normalizeQuery(inputs[side].value) === null) {
        clearList(side);
        say('');
        return;
      }
      timers[side] = window.setTimeout(() => void suggest(side), DEBOUNCE_MS);
    });
  }

  // A hand edit of the km field wins: forget answers that are still on their way. Programmatic writes
  // (applyKm) do not fire `input`, so a fill never cancels itself.
  kmInput.addEventListener('input', () => {
    distanceGen += 1;
    if (statusEl.textContent === m.routeCalculating) say('');
  });

  recalcBtn.addEventListener('click', () => void calculate());

  showAttribution(null);
  updateRecalc();
}
