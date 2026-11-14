// Unit tests for the pure calculator logic (no browser needed; run by Playwright's runner).
import { expect, test } from '@playwright/test';

import {
  buildInput,
  buildResultView,
  defaultState,
  localizeState,
  mapFacadeError,
  parseDecimal,
  parsePersons,
  paramsToState,
  sanitizeTripName,
  stateToParams,
} from '../src/calculator/core';

test.describe('parseDecimal', () => {
  const ok = (raw: string, value: number) => expect(parseDecimal(raw)).toEqual({ kind: 'ok', value });

  test('accepts comma and dot decimals', () => {
    ok('6,5', 6.5);
    ok('6.5', 6.5);
    ok('1,799', 1.799);
    ok(' 250 ', 250);
    ok('.5', 0.5);
    ok('7,', 7);
  });
  test('accepts grouping when both separators are present', () => {
    ok('1.234,5', 1234.5);
    ok('1,234.5', 1234.5);
    ok('1 234', 1234);
  });
  test('classifies empty, negative and junk', () => {
    expect(parseDecimal('')).toEqual({ kind: 'empty' });
    expect(parseDecimal('  ')).toEqual({ kind: 'empty' });
    expect(parseDecimal('-3')).toEqual({ kind: 'negative' });
    for (const bad of ['abc', '1e5', '1.2.3', '1,2,3', ',', '.', '--1', '5 km']) {
      expect(parseDecimal(bad), bad).toEqual({ kind: 'invalid' });
    }
  });
});

test('parsePersons accepts 1..100 integers only', () => {
  expect(parsePersons('1')).toBe(1);
  expect(parsePersons('100')).toBe(100);
  for (const bad of ['0', '101', '2.5', '', 'x', '-1']) expect(parsePersons(bad), bad).toBeNull();
});

test('buildInput maps state to the facade input and reports field errors', () => {
  const s = { ...defaultState(), km: '250', cons: '6,5', price: '1,799', persons: '3', extras: '11,5' };
  expect(buildInput(s)).toEqual({
    input: {
      distanceKm: 250,
      consumptionPer100km: 6.5,
      pricePerUnit: 1.799,
      persons: 3,
      driverPays: true,
      roundTrip: false,
      tollsEur: 11.5,
    },
  });
  expect(buildInput({ ...defaultState(), extras: '' })).not.toHaveProperty('input.tollsEur');
  expect(buildInput({ ...defaultState(), km: '', price: 'x', persons: '0' })).toEqual({
    errors: { km: 'errRequired', price: 'errInvalid', persons: 'errPersons' },
  });
});

test('mapFacadeError picks calm messages', () => {
  expect(mapFacadeError({ ok: false, error: 'NonPositiveDistance', field: 'distanceKm' }, true)).toEqual({
    km: 'errDistance',
  });
  expect(mapFacadeError({ ok: false, error: 'TripNoParticipants', field: 'persons' }, false)).toEqual({
    persons: 'errNeedPassenger',
  });
  expect(mapFacadeError({ ok: false, error: 'InvalidNumber', field: 'pricePerUnit' }, true)).toEqual({
    price: 'errTooLarge',
  });
});

test('buildResultView: shares, rounding and driver-free split', () => {
  const res = {
    ok: true,
    totalCents: 2923,
    perPersonCents: [975, 974, 974],
    breakdown: { fuelCents: 2923, wearCents: 0, tollsCents: 0, ferryCents: 0 },
  };
  expect(buildResultView(res, true)).toMatchObject({
    perPersonCents: 975,
    rounding: { high: 975, nHigh: 1, low: 974, nLow: 2 },
    driverGetsCents: null,
    totalCents: 2923,
    fuelCents: 2923,
    extrasCents: 0,
  });
  const free = { ...res, perPersonCents: [0, 1462, 1461] };
  expect(buildResultView(free, false)).toMatchObject({
    perPersonCents: 1462,
    rounding: { high: 1462, nHigh: 1, low: 1461, nLow: 1 },
    driverGetsCents: 2923,
  });
  expect(buildResultView({ ...res, perPersonCents: [500, 500] }, true).rounding).toBeNull();
});

test.describe('URL state', () => {
  test('round-trips every field', () => {
    const s = {
      energy: 'ev' as const,
      km: '120.5',
      cons: '17',
      price: '0.39',
      persons: '4',
      extras: '8',
      driverPays: false,
      roundTrip: true,
      trip: 'Fahrt nach München',
    };
    expect(stateToParams(s).toString()).toBe(
      'km=120.5&l100=17&p=0.39&n=4&d=0&rt=1&x=8&ev=1&t=Fahrt+nach+M%C3%BCnchen',
    );
    expect(paramsToState(stateToParams(s).toString())).toEqual(s);
  });
  test('trip name is sanitised: control chars, whitespace, 60 char cap', () => {
    expect(sanitizeTripName('  Fahrt \n nach\u0000\t München  ')).toBe('Fahrt nach München');
    expect(sanitizeTripName('x'.repeat(80))).toHaveLength(60);
    expect(sanitizeTripName('😀'.repeat(70))).toBe('😀'.repeat(60));
    expect(paramsToState('?t=' + 'y'.repeat(100)).trip).toHaveLength(60);
    expect(stateToParams({ ...defaultState(), trip: '   ' }).has('t')).toBe(false);
  });
  test('localizes numbers for display', () => {
    const s = localizeState({ ...defaultState(), price: '1.799' }, 'de');
    expect(s.price).toBe('1,799');
    expect(localizeState({ ...defaultState(), price: '1.799' }, 'en').price).toBe('1.799');
  });
  test('invalid params fall back to defaults', () => {
    expect(paramsToState('?km=-1&l100=x&n=500&x=abc')).toEqual(defaultState());
  });
  test('ev mode without explicit values uses EV defaults', () => {
    expect(paramsToState('?ev=1')).toEqual(defaultState('ev'));
  });
});
