// Calculator island: wires the server-rendered form in Calculator.astro to
// globalThis.mitlio.calculateTrip. Live recalculation, state in the URL, no network.
import { calculatorMessages, type CalculatorMessageKey } from '../i18n/calculator';
import {
  MAX_PERSONS,
  buildInput,
  buildResultView,
  fill,
  formatMoney,
  isUntouchedEnergyDefaults,
  localizeState,
  mapFacadeError,
  paramsToState,
  parseDecimal,
  parsePersons,
  stateToParams,
  energyDefaults,
  formatField,
  type CalcState,
  type Energy,
  type FacadeResult,
  type FieldErrors,
  type FieldKey,
  type Locale,
  type TripInput,
} from './core';
import { buildDeepLink } from '../lib/deeplink';
import { buildShareText, whatsappHref } from '../lib/share';

declare global {
  var mitlio: { calculateTrip(input: TripInput): FacadeResult } | undefined;
}

const root = document.getElementById('calculator');

if (root) {
  const locale: Locale = root.dataset.locale === 'en' ? 'en' : 'de';
  const m = calculatorMessages[locale];
  const $ = <T extends HTMLElement>(id: string): T => {
    const el = document.getElementById(id);
    if (!el) throw new Error(`calculator: missing #${id}`);
    return el as T;
  };

  const fields: FieldKey[] = ['km', 'cons', 'price', 'persons', 'extras'];
  const input = Object.fromEntries(fields.map((k) => [k, $<HTMLInputElement>(`calc-${k}`)])) as Record<
    FieldKey,
    HTMLInputElement
  >;
  const errorEl = Object.fromEntries(fields.map((k) => [k, $<HTMLElement>(`calc-${k}-error`)])) as Record<
    FieldKey,
    HTMLElement
  >;
  const driverPays = $<HTMLInputElement>('calc-driver-pays');
  const roundTrip = $<HTMLInputElement>('calc-round-trip');
  const energyRadios = Array.from(root.querySelectorAll<HTMLInputElement>('input[name="energy"]'));

  const out = {
    root: $('calc-result'),
    lead: $('calc-result-lead'),
    amount: $('calc-result-amount'),
    sub: $('calc-result-sub'),
    extra: $('calc-result-extra'),
    fuelLabel: $('calc-b-fuel-label'),
    fuel: $('calc-b-fuel'),
    extrasRow: $('calc-b-extras-row'),
    extras: $('calc-b-extras'),
    total: $('calc-b-total'),
    consLabel: $('calc-cons-label'),
    consUnit: $('calc-cons-unit'),
    priceLabel: $('calc-price-label'),
    priceUnit: $('calc-price-unit'),
  };
  const tripInput = $<HTMLInputElement>('calc-trip');
  const share = {
    root: $('calc-share'),
    native: $<HTMLButtonElement>('calc-share-native'),
    fallback: $('calc-share-fallback'),
    whatsapp: $<HTMLAnchorElement>('calc-share-wa'),
    copy: $<HTMLButtonElement>('calc-share-copy'),
    status: $('calc-share-status'),
  };
  const ctaOpen = document.getElementById('calc-cta-open') as HTMLAnchorElement | null;
  const appBanner = document.getElementById('apple-itunes-app');
  const canNativeShare = typeof navigator.share === 'function';
  let shareText = '';
  let shareUrl = '';
  let nativeFailed = false;
  let statusTimer: number | undefined;

  let state: CalcState = localizeState(paramsToState(location.search), locale);
  const touched = new Set<FieldKey>();

  const writeStateToDom = () => {
    for (const k of fields) input[k].value = state[k];
    tripInput.value = state.trip;
    driverPays.checked = state.driverPays;
    roundTrip.checked = state.roundTrip;
    for (const r of energyRadios) r.checked = r.value === state.energy;
  };

  const showErrors = (errors: FieldErrors) => {
    for (const k of fields) {
      const key: CalculatorMessageKey | undefined = errors[k];
      const visible = key !== undefined && (key !== 'errRequired' || touched.has(k));
      const el = errorEl[k];
      el.hidden = !visible;
      el.textContent = visible && key ? m[key] : '';
      input[k].setAttribute('aria-invalid', visible ? 'true' : 'false');
      if (visible) input[k].setAttribute('aria-describedby', el.id);
      else input[k].removeAttribute('aria-describedby');
    }
  };

  const setStatus = (text: string) => {
    window.clearTimeout(statusTimer);
    share.status.textContent = text;
    if (text) statusTimer = window.setTimeout(() => (share.status.textContent = ''), 3000);
  };

  const showShare = (visible: boolean) => {
    share.root.hidden = !visible;
    const native = canNativeShare && !nativeFailed;
    share.native.hidden = !native;
    share.fallback.hidden = native;
  };

  const updateAppLinks = () => {
    const extras = parseDecimal(state.extras);
    const km = parseDecimal(state.km);
    const l100 = parseDecimal(state.cons);
    const price = parseDecimal(state.price);
    const n = parsePersons(state.persons);
    if (km.kind !== 'ok' || l100.kind !== 'ok' || price.kind !== 'ok' || n === null) return;
    const link = buildDeepLink({
      km: km.value,
      l100: l100.value,
      price: price.value,
      n,
      d: state.driverPays,
      rt: state.roundTrip,
      x: extras.kind === 'ok' ? extras.value : undefined,
      t: state.trip,
      ev: state.energy === 'ev',
    });
    if (ctaOpen) ctaOpen.href = link;
    const bannerId = appBanner?.getAttribute('content')?.split(',')[0];
    if (bannerId) appBanner?.setAttribute('content', `${bannerId}, app-argument=${link}`);
  };

  const payers = () => (parsePersons(state.persons) ?? 1) - (state.driverPays ? 0 : 1);

  const showNoResult = (message: string) => {
    showShare(false);
    out.root.dataset.state = 'empty';
    out.lead.textContent = m.noResult;
    out.amount.textContent = '–';
    out.sub.textContent = message;
    out.extra.textContent = '';
    out.extra.hidden = true;
  };

  const render = () => {
    const ev = state.energy === 'ev';
    out.consLabel.textContent = `${ev ? m.consumptionEv : m.consumptionFuel} (${ev ? m.consumptionEvUnit : m.consumptionFuelUnit})`;
    out.consUnit.textContent = ev ? m.consumptionEvUnit : m.consumptionFuelUnit;
    out.priceLabel.textContent = `${ev ? m.priceEv : m.priceFuel} (${ev ? m.priceEvUnit : m.priceFuelUnit})`;
    out.priceUnit.textContent = ev ? m.priceEvUnit : m.priceFuelUnit;
    out.fuelLabel.textContent = ev ? m.rowEv : m.rowFuel;

    const api = globalThis.mitlio;
    if (!api) {
      showNoResult(m.errLoad);
      return;
    }
    const built = buildInput(state);
    let errors: FieldErrors = 'errors' in built ? built.errors : {};
    let result: FacadeResult | null = null;
    if ('input' in built) {
      result = api.calculateTrip(built.input);
      if (!result.ok) errors = mapFacadeError(result, state.driverPays);
    }
    showErrors(errors);
    if (!result?.ok) {
      showNoResult(m.fixFields);
      return;
    }

    const view = buildResultView(result, state.driverPays);
    out.root.dataset.state = 'ok';
    out.lead.textContent = state.driverPays ? m.perPerson : m.perPassenger;
    out.amount.textContent = formatMoney(view.perPersonCents, locale);
    out.sub.textContent =
      view.driverGetsCents === null
        ? ''
        : fill(m.driverGets, { amount: formatMoney(view.driverGetsCents, locale) });
    out.sub.hidden = view.driverGetsCents === null;
    out.extra.hidden = view.rounding === null;
    out.extra.textContent = view.rounding
      ? fill(m.rounding, {
          nHigh: view.rounding.nHigh,
          high: formatMoney(view.rounding.high, locale),
          nLow: view.rounding.nLow,
          low: formatMoney(view.rounding.low, locale),
        })
      : '';
    out.fuel.textContent = formatMoney(view.fuelCents, locale);
    out.extrasRow.hidden = view.extrasCents === 0;
    out.extras.textContent = formatMoney(view.extrasCents, locale);
    out.total.textContent = formatMoney(view.totalCents, locale);

    shareUrl = `${location.origin}${location.pathname}?${stateToParams(state).toString()}`;
    shareText = buildShareText({
      locale,
      payers: payers(),
      passengersOnly: !state.driverPays,
      perPersonCents: view.perPersonCents,
      rounded: view.rounding !== null,
      totalCents: view.totalCents,
      trip: state.trip,
      url: shareUrl,
    });
    share.whatsapp.href = whatsappHref(shareText);
    showShare(true);
    updateAppLinks();
  };

  const commit = () => {
    render();
    history.replaceState(null, '', `${location.pathname}?${stateToParams(state).toString()}${location.hash}`);
  };

  for (const k of fields) {
    input[k].addEventListener('input', () => {
      state = { ...state, [k]: input[k].value };
      commit();
    });
    input[k].addEventListener('blur', () => {
      touched.add(k);
      render();
    });
  }

  tripInput.addEventListener('input', () => {
    state = { ...state, trip: tripInput.value };
    commit();
  });

  share.native.addEventListener('click', () => {
    navigator.share({ text: shareText }).catch((e: unknown) => {
      // Dismissing the sheet is not an error; anything else falls back to the inline actions.
      if (e instanceof DOMException && e.name === 'AbortError') return;
      nativeFailed = true;
      showShare(true);
    });
  });

  share.copy.addEventListener('click', () => {
    const done = (ok: boolean) => setStatus(ok ? m.shareCopied : m.shareCopyFailed);
    if (!navigator.clipboard) return done(false);
    navigator.clipboard.writeText(shareUrl).then(
      () => done(true),
      () => done(false),
    );
  });

  driverPays.addEventListener('change', () => {
    state = { ...state, driverPays: driverPays.checked };
    commit();
  });
  roundTrip.addEventListener('change', () => {
    state = { ...state, roundTrip: roundTrip.checked };
    commit();
  });

  for (const r of energyRadios) {
    r.addEventListener('change', () => {
      if (!r.checked) return;
      const next = r.value as Energy;
      if (next === state.energy) return;
      const keepUserValues = !isUntouchedEnergyDefaults(state, state.energy);
      state = {
        ...state,
        energy: next,
        ...(keepUserValues
          ? {}
          : {
              cons: formatField(Number(energyDefaults[next].cons), locale),
              price: formatField(Number(energyDefaults[next].price), locale, 2),
            }),
      };
      writeStateToDom();
      commit();
    });
  }

  const step = (delta: number) => {
    const current = parsePersons(state.persons) ?? 2;
    const next = Math.min(MAX_PERSONS, Math.max(1, current + delta));
    state = { ...state, persons: String(next) };
    input.persons.value = state.persons;
    commit();
  };
  $('calc-persons-dec').addEventListener('click', () => step(-1));
  $('calc-persons-inc').addEventListener('click', () => step(1));

  // Restore state after bfcache / back navigation.
  window.addEventListener('pageshow', (e) => {
    if (e.persisted) {
      state = localizeState(paramsToState(location.search), locale);
      writeStateToDom();
      render();
    }
  });

  writeStateToDom();
  render();
  // The domain script is deferred and runs first; if it was slow, retry once loaded.
  if (!globalThis.mitlio) window.addEventListener('load', render, { once: true });
  root.dataset.ready = 'true';
}
