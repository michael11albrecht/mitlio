// Build-time helpers for the landing pages: runs the same compiled domain facade as the
// calculator island (public/mitlio_domain.js) so worked examples are computed, never typed.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import vm from 'node:vm';

import {
  buildResultView,
  fill,
  formatField,
  formatMoney,
  type CalcState,
  type FacadeResult,
} from '../calculator/core';

export interface ExampleInput {
  distanceKm: number;
  consumptionPer100km?: number | undefined;
  pricePerUnit?: number | undefined;
  kmRate?: number | undefined;
  persons: number;
  driverPays: boolean;
  roundTrip: boolean;
  tollsEur?: number | undefined;
  ev: boolean;
}

type Facade = { calculateTrip(input: Record<string, unknown>): FacadeResult };

let facade: Facade | undefined;

function loadFacade(): Facade {
  if (facade) return facade;
  const file = resolve(process.cwd(), 'public', 'mitlio_domain.js');
  let bundle: string;
  try {
    bundle = readFileSync(file, 'utf8');
  } catch {
    throw new Error(`landing pages need ${file}: run "npm run prebuild" (compiles packages/domain_web)`);
  }
  vm.runInThisContext(bundle);
  const api = (globalThis as unknown as { mitlio?: Facade }).mitlio;
  if (!api) throw new Error('mitlio_domain.js did not install globalThis.mitlio');
  facade = api;
  return api;
}

const defined = <T extends object>(o: T): Partial<T> =>
  Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined)) as Partial<T>;

function run(input: ExampleInput): ReturnType<typeof buildResultView> {
  const { ev: _ev, ...facadeInput } = input;
  const res = loadFacade().calculateTrip(defined(facadeInput));
  if (!res.ok) throw new Error(`facade rejected example ${JSON.stringify(input)}: ${res.error}`);
  return buildResultView(res, input.driverPays);
}

const de = (v: number, minFraction = 0) => formatField(v, 'de', minFraction);

/**
 * Placeholder values for a landing page; every number comes from the facade or the example input.
 * {km} {kmTotal} {cons} {price} {rate} {n} {payers} {units} {tolls} {total} {fuel} {perPerson}
 * {driverGets}, and with `compare`: {total2} {perPerson2} {n2}.
 */
export function exampleValues(
  input: ExampleInput,
  compare?: {
    persons?: number | undefined;
    driverPays?: boolean | undefined;
    roundTrip?: boolean | undefined;
    tollsEur?: number | undefined;
  },
): Record<string, string> {
  const view = run(input);
  const km = input.distanceKm * (input.roundTrip ? 2 : 1);
  const values: Record<string, string> = {
    km: de(input.distanceKm),
    kmTotal: de(km),
    cons: de(input.consumptionPer100km ?? 0),
    price: de(input.pricePerUnit ?? 0, 2),
    rate: de(input.kmRate ?? 0, 2),
    n: String(input.persons),
    payers: String(input.persons - (input.driverPays ? 0 : 1)),
    units: de(Math.round(((km * (input.consumptionPer100km ?? 0)) / 100) * 100) / 100),
    tolls: formatMoney(Math.round((input.tollsEur ?? 0) * 100), 'de'),
    total: formatMoney(view.totalCents, 'de'),
    fuel: formatMoney(view.fuelCents, 'de'),
    perPerson: formatMoney(view.perPersonCents, 'de'),
    driverGets: formatMoney(view.driverGetsCents ?? 0, 'de'),
  };
  if (compare) {
    const second = run(Object.assign({}, input, defined(compare)));
    values['total2'] = formatMoney(second.totalCents, 'de');
    values['perPerson2'] = formatMoney(second.perPersonCents, 'de');
    values['n2'] = String(compare.persons ?? input.persons);
  }
  return values;
}

/** Fills {placeholders} and fails the build on a typo instead of printing an empty gap. */
export function fillStrict(template: string, values: Record<string, string>): string {
  for (const m of template.matchAll(/\{(\w+)\}/g)) {
    const key = m[1] as string;
    if (!(key in values)) throw new Error(`unknown placeholder {${key}} in: ${template.slice(0, 60)}`);
  }
  return fill(template, values);
}

/** Calculator preset (form strings) derived from the worked example. */
export function presetFromExample(input: ExampleInput): Partial<CalcState> {
  const s = (v: number) => String(v);
  return {
    energy: input.ev ? 'ev' : 'fuel',
    km: s(input.distanceKm),
    ...(input.kmRate !== undefined
      ? { price: s(input.kmRate) }
      : { cons: s(input.consumptionPer100km ?? 0), price: s(input.pricePerUnit ?? 0) }),
    persons: s(input.persons),
    driverPays: input.driverPays,
    roundTrip: input.roundTrip,
    ...(input.tollsEur ? { extras: s(input.tollsEur) } : {}),
  };
}
