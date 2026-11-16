import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

import { futurePrivacySectionsDe, futurePrivacySectionsEn, legalTexts } from '../src/i18n/legal';
import { assertNoPlaceholders, fillAddress, findPlaceholders, isProductionSite } from '../src/lib/legal';
import retention from '../../supabase/retention.json' with { type: 'json' };

// Release blockers: filled at build time from LEGAL_STREET / LEGAL_CITY (docs/release.md, "Legal texts").
const EXPECTED_PLACEHOLDERS = ['[[STRASSE HAUSNUMMER]]', '[[PLZ ORT]]'];
const ALL_TEXTS = (['de', 'en'] as const).flatMap((l) => (['imprint', 'privacy'] as const).map((k) => legalTexts[l][k]));
const flat = (t: (typeof ALL_TEXTS)[number]): string =>
  t.sections.flatMap((s) => [s.heading, ...(s.paragraphs ?? []), ...(s.items ?? [])]).join('\n');

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

test.describe('address from the build environment', () => {
  const env = { LEGAL_STREET: 'Teststraße 1', LEGAL_CITY: '12345 Teststadt' };

  test('fills both placeholders in every text', () => {
    for (const t of ALL_TEXTS) {
      const filled = fillAddress(t, env);
      expect(findPlaceholders(filled)).toEqual([]);
      expect(() => assertNoPlaceholders(filled, 'https://mitlio.de')).not.toThrow();
    }
    expect(flat(fillAddress(legalTexts.de.imprint, env))).toContain('Teststraße 1');
    expect(flat(fillAddress(legalTexts.en.privacy, env))).toContain('12345 Teststadt');
  });

  test('a missing or blank variable keeps the placeholder, so the production build still fails', () => {
    for (const t of ALL_TEXTS) {
      expect(findPlaceholders(fillAddress(t, {}))).toEqual(findPlaceholders(t));
      const onlyStreet = fillAddress(t, { LEGAL_STREET: 'Teststraße 1', LEGAL_CITY: '   ' });
      expect(findPlaceholders(onlyStreet)).toEqual(['[[PLZ ORT]]']);
      expect(() => assertNoPlaceholders(onlyStreet, 'https://mitlio.de')).toThrow(/PLZ ORT/);
    }
    expect(() => assertNoPlaceholders(fillAddress(legalTexts.de.imprint, {}), 'https://mitlio.de')).toThrow();
  });
});

test.describe('retention numbers come from supabase/retention.json', () => {
  const de = flat(legalTexts.de.privacy) + flat({ sections: futurePrivacySectionsDe });
  const en = flat(legalTexts.en.privacy) + flat({ sections: futurePrivacySectionsEn });
  const days = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

  test('German text', () => {
    expect(de).toContain(`älter als ${days(retention.rate_limits_days, 'Tag', 'Tage')}`);
    expect(de).toContain(`nach ${days(retention.sentry_days, 'Tag', 'Tagen')}`);
    expect(de).toContain(`höchstens ${days(retention.platform_logs_max_days, 'Tag', 'Tage')}`);
    expect(de).toContain(`${retention.email_months} Monate nach der letzten Nachricht`);
    expect(de).toContain(`${retention.privacy_request_years} Jahre`);
    expect(de).toContain(`nach ${retention.join_audit_days} Tagen`);
    expect(de).toContain(`${retention.expired_invites_days_after_expiry} Tagen nach Ablauf`);
  });

  test('English text', () => {
    expect(en).toContain(`older than ${days(retention.rate_limits_days, 'day', 'days')}`);
    expect(en).toContain(`after ${days(retention.sentry_days, 'day', 'days')}`);
    expect(en).toContain(`${days(retention.platform_logs_max_days, 'day', 'days')} at most`);
    expect(en).toContain(`${retention.email_months} months after the last message`);
    expect(en).toContain(`${retention.privacy_request_years} years`);
    expect(en).toContain(`after ${retention.join_audit_days} days`);
    expect(en).toContain(`${retention.expired_invites_days_after_expiry} days after they expire`);
  });

  test('join audit and invites only appear in the not-yet-live sections', () => {
    for (const t of [legalTexts.de.privacy, legalTexts.en.privacy]) {
      expect(flat(t)).not.toMatch(new RegExp(`${retention.join_audit_days} (Tagen|days)`));
    }
  });
});

test.describe('contacts and authority', () => {
  test('imprint, controller, contact form and BayLDA', () => {
    expect(flat(legalTexts.de.imprint)).toContain('contact@mitlio.de');
    expect(flat(legalTexts.de.imprint)).toContain('mitlio.de/kontakt/');
    expect(flat(legalTexts.en.imprint)).toContain('contact@mitlio.de');
    expect(flat(legalTexts.en.imprint)).toContain('mitlio.de/en/contact/');
    for (const t of [legalTexts.de.privacy, legalTexts.en.privacy]) {
      expect(flat(t)).toContain('privacy@mitlio.de');
      expect(flat(t)).toContain('BayLDA');
      expect(flat(t)).toContain('Promenade 18, 91522 Ansbach');
      expect(flat(t)).toContain('Resend');
    }
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
      // Headings may appear in running text ("Push-Nachrichten gibt es noch nicht"), so compare the bodies.
      for (const s of future) for (const p of s.paragraphs ?? []) expect(body).not.toContain(p);
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
