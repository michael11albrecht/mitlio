import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

import { futurePrivacySectionsDe, futurePrivacySectionsEn, legalTexts } from '../src/i18n/legal';
import { assertNoPlaceholders, findPlaceholders, isProductionSite } from '../src/lib/legal';

// Release blockers: the owner fills these in src/i18n/legal.ts (docs/release.md, "Legal texts").
const EXPECTED_PLACEHOLDERS = [
  '[[STRASSE HAUSNUMMER]]',
  '[[PLZ ORT]]',
  '[[E-MAIL]]',
  '[[ZUSTÄNDIGE LANDESBEHÖRDE FÜR DEN DATENSCHUTZ]]',
];

test.describe('placeholder gate', () => {
  test('lists exactly the known placeholders, in every text', () => {
    for (const locale of ['de', 'en'] as const) {
      for (const key of ['imprint', 'privacy'] as const) {
        for (const p of findPlaceholders(legalTexts[locale][key])) {
          expect(EXPECTED_PLACEHOLDERS, `${locale}/${key}`).toContain(p);
        }
      }
    }
    const all = (['de', 'en'] as const).flatMap((l) => findPlaceholders(legalTexts[l].privacy));
    expect(new Set(all)).toEqual(new Set(EXPECTED_PLACEHOLDERS));
  });

  test('production origins and strict mode are blocked, stand-in and local hosts are not', () => {
    expect(isProductionSite('https://mitlio.web.app')).toBe(false);
    expect(isProductionSite('http://localhost:4321')).toBe(false);
    expect(isProductionSite('http://127.0.0.1:4321')).toBe(false);
    expect(isProductionSite('https://mitlio.de')).toBe(true);
    expect(isProductionSite('https://mitlio.web.app', true)).toBe(true);
  });

  test('the build fails on a production domain while placeholders remain', () => {
    for (const locale of ['de', 'en'] as const) {
      for (const key of ['imprint', 'privacy'] as const) {
        const text = legalTexts[locale][key];
        expect(() => assertNoPlaceholders(text, 'https://mitlio.de')).toThrow(/placeholders/);
        expect(() => assertNoPlaceholders(text, 'https://mitlio.web.app', true)).toThrow(/placeholders/);
        expect(() => assertNoPlaceholders(text, 'https://mitlio.web.app')).not.toThrow();
      }
    }
  });

  test('passes once every placeholder is filled', () => {
    const filled = { sections: [{ heading: 'A', paragraphs: ['Musterstraße 1'] }] };
    expect(() => assertNoPlaceholders(filled, 'https://mitlio.de')).not.toThrow();
  });
});

const pages = [
  { path: '/impressum/', lang: 'de', h1: 'Impressum', h2: 'Angaben gemäß § 5 DDG' },
  { path: '/datenschutz/', lang: 'de', h1: 'Datenschutz', h2: 'Deine Rechte' },
  { path: '/en/imprint/', lang: 'en', h1: 'Imprint', h2: 'Information according to § 5 DDG' },
  { path: '/en/privacy/', lang: 'en', h1: 'Privacy', h2: 'Your rights' },
] as const;

test.describe('legal pages', () => {
  for (const p of pages) {
    test(`${p.path} renders the text, stays noindex and has no axe violations`, async ({ page }) => {
      await page.goto(p.path);
      await expect(page.locator('h1')).toHaveText(p.h1);
      await expect(page.getByRole('heading', { level: 2, name: p.h2 })).toBeVisible();
      await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);
      const results = await new AxeBuilder({ page }).analyze();
      expect(results.violations).toEqual([]);
    });
  }

  test('sections for features that are not live are not rendered', async ({ page }) => {
    for (const [path, future] of [
      ['/datenschutz/', futurePrivacySectionsDe],
      ['/en/privacy/', futurePrivacySectionsEn],
    ] as const) {
      await page.goto(path);
      const body = await page.locator('main').innerText();
      expect(future.length).toBeGreaterThan(0);
      for (const s of future) expect(body).not.toContain(s.heading);
      expect(body).not.toContain('Firebase Cloud Messaging');
    }
  });

  test('the privacy pages state that there are no cookies', async ({ page }) => {
    await page.goto('/datenschutz/');
    await expect(page.locator('main')).toContainText('keine Cookies');
    await page.goto('/en/privacy/');
    await expect(page.locator('main')).toContainText('no cookies');
  });
});
