import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

import {
  buildLegalTexts,
  futurePrivacySectionsDe,
  futurePrivacySectionsEn,
  legalTexts,
  SYNC_PRIVACY_RENDERED,
  syncPrivacySections,
  withSync,
} from '../src/i18n/legal';
import {
  assertNoPlaceholders,
  assertSyncDisclosed,
  fillAddress,
  findPlaceholders,
  isProductionSite,
} from '../src/lib/legal';
import prodConfig from '../../app/config/prod.json' with { type: 'json' };
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
        // Strict mode (set by web-deploy.yml) arms the gate on the stand-in origin that deploy publishes live.
        expect(() => assertNoPlaceholders(text, 'https://mitlio.web.app', true)).toThrow(/placeholders/);
        expect(() => assertNoPlaceholders(fillAddress(text, {}), 'https://mitlio.web.app', true)).toThrow(/placeholders/);
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
  const de = flat(buildLegalTexts(false).de.privacy) + flat(buildLegalTexts(true).de.privacy);
  const en = flat(buildLegalTexts(false).en.privacy) + flat(buildLegalTexts(true).en.privacy);
  const days = (n: number, one: string, many: string) => `${n} ${n === 1 ? one : many}`;

  test('German text', () => {
    expect(de).toContain(`höchstens etwa ${days(retention.rate_limits_days + 1, 'Tag', 'Tage')}`);
    expect(de).toContain(`älter als ${days(retention.rate_limits_days, 'Tag', 'Tage')}`);
    expect(de).toContain(`nach ${days(retention.sentry_days, 'Tag', 'Tagen')}`);
    expect(de).toContain(`höchstens ${days(retention.platform_logs_max_days, 'Tag', 'Tage')}`);
    expect(de).toContain(`${retention.email_months} Monate nach der letzten Nachricht`);
    expect(de).toContain(`${retention.privacy_request_years} Jahre`);
    expect(de).toContain(`nach ${retention.join_audit_days} Tagen`);
    expect(de).toContain(`${retention.expired_invites_days_after_expiry} Tagen nach Ablauf`);
    expect(de).toContain(`${retention.inactive_account_months} Monate ohne Aktivität`);
    expect(de).toContain(`die letzten ${retention.expense_revisions_per_expense} Stände`);
  });

  test('English text', () => {
    expect(en).toContain(`about ${days(retention.rate_limits_days + 1, 'day', 'days')} at most`);
    expect(en).toContain(`older than ${days(retention.rate_limits_days, 'day', 'days')}`);
    expect(en).toContain(`after ${days(retention.sentry_days, 'day', 'days')}`);
    expect(en).toContain(`${days(retention.platform_logs_max_days, 'day', 'days')} at most`);
    expect(en).toContain(`${retention.email_months} months after the last message`);
    expect(en).toContain(`${retention.privacy_request_years} years`);
    expect(en).toContain(`after ${retention.join_audit_days} days`);
    expect(en).toContain(`${retention.expired_invites_days_after_expiry} days after they expire`);
    expect(en).toContain(`${retention.inactive_account_months} months without activity`);
    expect(en).toContain(`the last ${retention.expense_revisions_per_expense} versions`);
  });

  test('join audit and invites appear exactly when the sync sections are rendered', () => {
    for (const t of [legalTexts.de.privacy, legalTexts.en.privacy]) {
      const re = new RegExp(`${retention.join_audit_days} (Tagen|days)`);
      if (SYNC_PRIVACY_RENDERED) expect(flat(t)).toMatch(re);
      else expect(flat(t)).not.toMatch(re);
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

test.describe('structure and DE/EN parity', () => {
  const shape = (t: (typeof ALL_TEXTS)[number]) =>
    t.sections.map((s) => [(s as { emphasis?: boolean }).emphasis === true, s.paragraphs?.length ?? 0, s.items?.length ?? 0]);

  test('DE and EN have the same sections, paragraph counts and emphasis flags', () => {
    for (const key of ['imprint', 'privacy'] as const) {
      expect(shape(legalTexts.en[key]), key).toEqual(shape(legalTexts.de[key]));
    }
    expect(futurePrivacySectionsEn.length).toBe(futurePrivacySectionsDe.length);
  });

  test('the sync variant has the same sections, paragraph counts and items in DE and EN', () => {
    const sync = buildLegalTexts(true);
    expect(shape(sync.en.privacy)).toEqual(shape(sync.de.privacy));
    for (const [d, e] of futurePrivacySectionsDe.map((s, i) => [s, futurePrivacySectionsEn[i]] as const)) {
      expect([d.paragraphs?.length, d.items?.length], d.heading).toEqual([e?.paragraphs?.length, e?.items?.length]);
    }
  });

  test('the right to object is its own emphasised section, with Art. 6(1)(f) and no marketing', () => {
    for (const [locale, heading, f, marketing] of [
      ['de', 'Widerspruchsrecht (Art. 21 DSGVO)', 'Art. 6 Abs. 1 lit. f DSGVO', 'keine Direktwerbung'],
      ['en', 'Right to object (Art. 21 GDPR)', 'Art. 6(1)(f) GDPR', 'no direct marketing'],
    ] as const) {
      const sections = legalTexts[locale].privacy.sections;
      const emphasised = sections.filter((s) => (s as { emphasis?: boolean }).emphasis);
      expect(emphasised.map((s) => s.heading)).toEqual([heading]);
      const text = flat({ sections: emphasised });
      expect(text).toContain(f);
      expect(text).toContain(marketing);
      expect(text).toContain('privacy@mitlio.de');
    }
  });

  test('every provider is named by legal entity, with its transfer basis', () => {
    for (const locale of ['de', 'en'] as const) {
      const t = flat(legalTexts[locale].privacy);
      for (const entity of [
        'Google Ireland Limited',
        'Functional Software, Inc.',
        'Plus Five Five, Inc.',
        'Supabase Pte. Ltd.',
        'Tankerkönig UG (haftungsbeschränkt)',
        'Data Privacy Framework',
      ]) {
        expect(t, `${locale}: ${entity}`).toContain(entity);
      }
      expect(t).toContain('HTTPS/TLS');
      expect(t).toContain('Art. 22');
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

  test('sync sections are rendered exactly when SYNC_PRIVACY_RENDERED is true; push is never rendered', async ({ page }) => {
    for (const [path, future] of [
      ['/datenschutz/', futurePrivacySectionsDe],
      ['/en/privacy/', futurePrivacySectionsEn],
    ] as const) {
      await page.goto(path);
      const body = await page.locator('main').innerText();
      expect(future.length).toBeGreaterThan(0);
      // Headings may appear in running text ("Push-Nachrichten gibt es noch nicht"), so compare the bodies.
      for (const s of future) {
        for (const p of s.paragraphs ?? []) {
          if (SYNC_PRIVACY_RENDERED) expect(body).toContain(p);
          else expect(body).not.toContain(p);
        }
      }
      // Push is not shipped with sync: its section was removed and must not reappear unnoticed.
      expect(body).not.toContain('Firebase Cloud Messaging');
    }
  });

  test('the right to object is rendered as a highlighted box', async ({ page }) => {
    for (const [path, heading] of [
      ['/datenschutz/', 'Widerspruchsrecht (Art. 21 DSGVO)'],
      ['/en/privacy/', 'Right to object (Art. 21 GDPR)'],
    ] as const) {
      await page.goto(path);
      const box = page.locator('section.legal-emphasis');
      await expect(box).toHaveCount(1);
      await expect(box.getByRole('heading', { level: 2, name: heading })).toBeVisible();
      await expect(box).toHaveCSS('border-top-width', '2px');
    }
    await page.goto('/impressum/');
    await expect(page.locator('section.legal-emphasis')).toHaveCount(0);
  });

  test('the privacy pages state that there are no cookies', async ({ page }) => {
    await page.goto('/datenschutz/');
    await expect(page.locator('main')).toContainText('keine Cookies');
    await page.goto('/en/privacy/');
    await expect(page.locator('main')).toContainText('no cookies');
  });
});

test.describe('sync privacy text (not rendered until sync ships)', () => {
  const sync = buildLegalTexts(true);
  const syncDe = flat(sync.de.privacy);
  const syncEn = flat(sync.en.privacy);

  test('lists what the server stores and what stays on the device', () => {
    for (const word of ['Änderungsverlauf', 'Fahrzeuge', 'Fahrtvorlagen', 'Einladungen', 'Ausgleichszahlungen', 'IBAN-Hinweis', 'vollständige IBAN', 'gespeicherte Orte', 'Absturzberichte']) {
      expect(syncDe, word).toContain(word);
    }
    for (const word of ['Edit history', 'Vehicles', 'ride templates', 'Invites', 'Settlements', 'IBAN hint', 'full IBAN', 'saved places', 'crash-report']) {
      expect(syncEn, word).toContain(word);
    }
  });

  test('informs people who do not use mitlio (Art. 14): source, categories, purpose, retention, rights, removal', () => {
    for (const [locale, heading, words] of [
      ['de', 'Personen in geteilten Gruppen, die mitlio nicht nutzen (Art. 14 DSGVO)', ['Quelle:', 'Kategorien:', 'Zweck und Rechtsgrundlage:', 'Speicherdauer:', 'Deine Rechte:', 'privacy@mitlio.de', 'Art. 6 Abs. 1 lit. f']],
      ['en', 'People in shared groups who do not use mitlio (Art. 14 GDPR)', ['Source:', 'Categories:', 'Purpose and legal basis:', 'Retention:', 'Your rights:', 'privacy@mitlio.de', 'Art. 6(1)(f)']],
    ] as const) {
      const section = sync[locale].privacy.sections.find((x) => x.heading === heading);
      expect(section, `${locale}: ${heading}`).toBeDefined();
      for (const w of words) expect(flat({ sections: [section!] }), `${locale}: ${w}`).toContain(w);
    }
  });

  test('explains what "delete all my data" does on the server and what stays', () => {
    for (const [locale, heading] of [['de', 'Alle meine Daten löschen und geteilte Gruppen'], ['en', 'Delete all my data and shared groups']] as const) {
      expect(sync[locale].privacy.sections.map((x) => x.heading)).toContain(heading);
    }
    expect(syncDe).toContain('Es bleiben die Gruppendaten');
    expect(syncEn).toContain('What stays is the group data');
  });

  test('no statement that is only true without sync survives in the sync variant', () => {
    for (const stale of ['Konten, Gruppen-Synchronisierung und Push-Nachrichten gibt es noch nicht', 'Weil die App keine Konten hat', 'Es gibt kein Konto und keine Werbung', 'speichert die App nur auf deinem Gerät']) {
      expect(syncDe, stale).not.toContain(stale);
    }
    for (const stale of ['There are no accounts, group sync or push notifications yet', 'Because the app has no accounts', 'There is no account and no ads', 'stored on your device only. We do not receive them']) {
      expect(syncEn, stale).not.toContain(stale);
    }
  });

  test('withSync fails loudly when a live heading it refers to is gone', () => {
    expect(() => withSync({ sections: [{ heading: 'Other' }] }, { insertAfter: 'Missing', sections: [], changes: {} })).toThrow(/Missing/);
    expect(() => withSync({ sections: [{ heading: 'A' }] }, { insertAfter: 'A', sections: [], changes: { B: (x) => x } })).toThrow(/"B"/);
  });
});

test.describe('release gate: SUPABASE_URL in app/config/prod.json needs the sync sections in the privacy text', () => {
  const live = buildLegalTexts(false);
  const withSyncText = buildLegalTexts(true);

  test('without a Supabase URL nothing is required, whatever is rendered', () => {
    for (const locale of ['de', 'en'] as const) {
      for (const url of ['', '   ', undefined]) {
        expect(() => assertSyncDisclosed(url, live[locale].privacy, syncPrivacySections[locale])).not.toThrow();
      }
    }
  });

  test('with a Supabase URL and the live (sync-less) text, the build fails and names the missing sections', () => {
    for (const locale of ['de', 'en'] as const) {
      expect(() => assertSyncDisclosed('https://abc.supabase.co', live[locale].privacy, syncPrivacySections[locale])).toThrow(
        new RegExp(syncPrivacySections[locale][0]!.heading.replace(/[()]/g, '\\$&')),
      );
    }
  });

  test('with a Supabase URL and the sync text rendered, it passes', () => {
    for (const locale of ['de', 'en'] as const) {
      expect(() => assertSyncDisclosed('https://abc.supabase.co', withSyncText[locale].privacy, syncPrivacySections[locale])).not.toThrow();
    }
  });

  test('a single missing sync section is enough to fail', () => {
    const partial = { sections: withSyncText.de.privacy.sections.filter((x) => x.heading !== 'Einladungslinks') };
    expect(() => assertSyncDisclosed('https://abc.supabase.co', partial, syncPrivacySections.de)).toThrow(/Einladungslinks/);
  });

  test('the shipped config and the shipped text agree (this is what the production build checks)', () => {
    for (const locale of ['de', 'en'] as const) {
      expect(() => assertSyncDisclosed(prodConfig.SUPABASE_URL, legalTexts[locale].privacy, syncPrivacySections[locale])).not.toThrow();
    }
    // The flag and the rendered text never disagree.
    const headings = legalTexts.de.privacy.sections.map((x) => x.heading);
    for (const s of syncPrivacySections.de) expect(headings.includes(s.heading)).toBe(SYNC_PRIVACY_RENDERED);
  });
});
