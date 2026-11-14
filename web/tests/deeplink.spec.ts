// Unit tests for the app deep link builder. The fixtures are shared with the app (P3r-T08).
import { readFileSync } from 'node:fs';
import { expect, test } from '@playwright/test';

import { buildDeepLink, type DeepLinkInput } from '../src/lib/deeplink';

interface Case {
  name: string;
  input: DeepLinkInput;
  expected: string;
}

const cases = JSON.parse(
  readFileSync(new URL('../../tool/fixtures/deeplink.json', import.meta.url), 'utf8'),
) as Case[];

test.describe('buildDeepLink', () => {
  test('fixture file has the three contract cases', () => {
    expect(cases.length).toBeGreaterThanOrEqual(3);
  });
  for (const c of cases) {
    test(c.name, () => {
      expect(buildDeepLink(c.input)).toBe(c.expected);
    });
  }

  test('trip name is capped at 60 characters', () => {
    const link = buildDeepLink({ km: 1, l100: 1, price: 1, n: 2, d: true, rt: false, t: 'a'.repeat(90) });
    expect(new URL(link).searchParams.get('t')).toBe('a'.repeat(60));
  });

  test('survives a round trip through URL parsing', () => {
    const t = 'Fahrt & Spaß = 100 % "ok" +1';
    const link = buildDeepLink({ km: 10, l100: 5, price: 2, n: 2, d: true, rt: false, t });
    expect(new URL(link).searchParams.get('t')).toBe(t);
  });
});
