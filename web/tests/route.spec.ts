// From-to route field (PW-T12, #207). Runs against the build with a fake FUEL_API_URL and ROUTE_WEB=1
// (scripts/serve-fuel-fixture.mjs); the route-distance API is mocked with page.route, no real network.
import AxeBuilder from '@axe-core/playwright';
import { expect, test, type Page, type Route } from '@playwright/test';

import { buildLegalTexts, legalTexts } from '../src/i18n/legal';
import { findPlaceholders } from '../src/lib/legal';
import { metersToKm, normalizeQuery, parseDistance, parseRetryAfter, parseSuggestions, ROUTE_ATTRIBUTION } from '../src/lib/route';

const API_ORIGIN = 'https://fuel.mitlio.test';
const API = `${API_ORIGIN}/functions/v1/route-distance`;
const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'apikey, authorization, content-type',
  'access-control-expose-headers': 'Retry-After',
};

type Body = Record<string, unknown>;
type Reply = { status: number; body: unknown; headers?: Record<string, string> } | 'abort';
type Handler = (body: Body) => Reply;

const KARLSRUHE = { label: 'Karlsruhe, Baden-Württemberg, Deutschland', lat: 49.0069, lng: 8.4037 };
const STUTTGART = { label: 'Stuttgart, Baden-Württemberg, Deutschland', lat: 48.7758, lng: 9.1829 };

const defaultHandler: Handler = (body) => {
  if (body['action'] === 'suggest') {
    const text = String(body['text']).toLowerCase();
    const suggestions = text.startsWith('karls') ? [KARLSRUHE] : text.startsWith('stutt') ? [STUTTGART] : [];
    return { status: 200, body: { suggestions, attribution: ROUTE_ATTRIBUTION } };
  }
  return { status: 200, body: { meters: 81234, attribution: ROUTE_ATTRIBUTION } };
};

/** Mocks the API; returns the parsed request bodies it served. */
async function mockApi(page: Page, handler: Handler = defaultHandler) {
  const seen: { body: Body; headers: Record<string, string> }[] = [];
  await page.route(`${API_ORIGIN}/**`, async (route: Route) => {
    const req = route.request();
    if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
    if (!req.url().startsWith(API)) return route.fulfill({ status: 404, headers: CORS, body: '{}' });
    const body = JSON.parse(req.postData() ?? '{}') as Body;
    seen.push({ body, headers: req.headers() });
    const reply = handler(body);
    if (reply === 'abort') return route.abort('failed');
    return route.fulfill({
      status: reply.status,
      contentType: 'application/json',
      headers: { ...CORS, ...reply.headers },
      body: JSON.stringify(reply.body),
    });
  });
  return seen;
}

async function open(page: Page, path = '/') {
  await page.goto(path);
  await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
}

const km = (page: Page) => page.locator('#calc-km');
const status = (page: Page) => page.locator('#calc-route-status');
const from = (page: Page) => page.locator('#calc-route-from');
const to = (page: Page) => page.locator('#calc-route-to');

async function expand(page: Page) {
  await page.locator('#calc-route > summary').click();
  await expect(from(page)).toBeVisible();
}

/** Types in a field and picks the first suggestion. */
async function choose(page: Page, field: 'from' | 'to', text: string) {
  const input = field === 'from' ? from(page) : to(page);
  await input.fill(text);
  await page.locator(`#calc-route-${field}-list .route-option`).first().click();
}

async function pickBoth(page: Page) {
  await choose(page, 'from', 'Karlsruhe');
  await choose(page, 'to', 'Stuttgart');
}

test.describe('route lib', () => {
  test('normalizes and validates', () => {
    expect(normalizeQuery('  Karls   ruhe ')).toBe('Karls ruhe');
    expect(normalizeQuery('ab')).toBeNull();
    expect(normalizeQuery('x'.repeat(121))).toBeNull();
    expect(metersToKm(81234)).toBe(81.2);
    expect(metersToKm(81250)).toBe(81.3);
    expect(parseRetryAfter('60')).toBe(60);
    expect(parseRetryAfter('Wed, 21 Oct')).toBeNull();
    expect(parseRetryAfter(null)).toBeNull();
    expect(parseDistance({ meters: -1 })).toBeNull();
    expect(parseDistance({ meters: 5 })?.attribution).toBe(ROUTE_ATTRIBUTION);
    expect(parseSuggestions({ suggestions: [{ label: 'A', lat: 91, lng: 0 }, { label: 'B', lat: 1, lng: 2 }] })?.places).toEqual([
      { label: 'B', lat: 1, lng: 2 },
    ]);
    expect(parseSuggestions({ nope: 1 })).toBeNull();
  });
});

test.describe('privacy text gate', () => {
  test('the route section is in both languages, and only rendered with the flag', () => {
    const on = buildLegalTexts(true, true);
    for (const locale of ['de', 'en'] as const) {
      const privacy = on[locale].privacy;
      const section = privacy.sections.find((s) => s.heading.startsWith(locale === 'de' ? 'Strecke berechnen' : 'Calculating a route'));
      expect(section, locale).toBeDefined();
      expect(JSON.stringify(section)).toContain('openrouteservice');
      expect(findPlaceholders(privacy)).toEqual([]);
      expect(JSON.stringify(privacy)).toContain('HeiGIT');
      // The default text (flag off) does not name the provider.
      expect(JSON.stringify(buildLegalTexts(true)[locale].privacy)).not.toContain('openrouteservice');
    }
    expect(on.de.privacy.sections.length).toBe(on.en.privacy.sections.length);
    expect(legalTexts.de.privacy.sections.length).toBe(buildLegalTexts(true).de.privacy.sections.length);
  });
});

test.describe('route field (de)', () => {
  test('is collapsed and sends nothing on load or on expanding', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expect(page.locator('#calc-route')).not.toHaveAttribute('open', '');
    await expect(page.locator('#calc-route > summary')).toHaveText('Start und Ziel eingeben, Strecke berechnen');
    await expand(page);
    await expect(page.locator('.route-note').first()).toContainText('openrouteservice');
    await page.waitForTimeout(500);
    expect(seen).toEqual([]);
  });

  test('does not call below 3 characters, debounces, then fills the km field with the road distance', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expand(page);
    await from(page).pressSequentially('Ka', { delay: 20 });
    await page.waitForTimeout(500);
    expect(seen).toEqual([]);
    // Typing fast sends one request for the final text, not one per letter.
    await from(page).pressSequentially('rlsruhe', { delay: 30 });
    await expect(page.locator('#calc-route-from-list .route-option')).toHaveText([KARLSRUHE.label]);
    expect(seen.map((s) => s.body)).toEqual([{ action: 'suggest', text: 'Karlsruhe', lang: 'de' }]);
    expect(seen[0]?.headers['apikey']).toBe('test-anon-key');
    await page.locator('#calc-route-from-list .route-option').click();
    await expect(from(page)).toHaveValue(KARLSRUHE.label);
    // One side picked: no distance call yet.
    expect(seen.filter((s) => s.body['action'] === 'distance')).toEqual([]);

    await choose(page, 'to', 'Stuttgart');
    await expect(km(page)).toHaveValue('81,2');
    await expect(status(page)).toContainText('Einfache Strecke: 81,2 km');
    await expect(page.locator('#calc-route-attribution')).toHaveText(ROUTE_ATTRIBUTION);
    const distance = seen.filter((s) => s.body['action'] === 'distance');
    expect(distance.map((s) => s.body)).toEqual([
      { action: 'distance', from: { lat: KARLSRUHE.lat, lng: KARLSRUHE.lng }, to: { lat: STUTTGART.lat, lng: STUTTGART.lng } },
    ]);
    expect(page.url()).toContain('km=81.2');
    // The result recalculates live from the filled value.
    await expect(page.locator('#calc-result-amount')).not.toHaveText('–');
  });

  test('the round-trip switch doubles the filled one-way distance in the result', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await page.locator('#calc-cons').fill('10');
    await page.locator('#calc-price').fill('2');
    await page.locator('#calc-persons').fill('1');
    await expand(page);
    await pickBoth(page);
    await expect(km(page)).toHaveValue('81,2');
    const one = await page.locator('#calc-result-amount').textContent();
    await page.locator('#calc-round-trip').check();
    await expect(page.locator('#calc-result-amount')).not.toHaveText(one ?? '');
    await expect(km(page)).toHaveValue('81,2');
  });

  test('overtyping the km field wins, also over an answer that is still on its way', async ({ page }) => {
    let release: () => void = () => undefined;
    const gate = new Promise<void>((r) => (release = r));
    const seen: Body[] = [];
    await page.route(`${API_ORIGIN}/**`, async (route) => {
      const req = route.request();
      if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
      const body = JSON.parse(req.postData() ?? '{}') as Body;
      seen.push(body);
      if (body['action'] === 'distance') await gate;
      const reply = defaultHandler(body) as Exclude<Reply, 'abort'>;
      return route.fulfill({ status: reply.status, contentType: 'application/json', headers: CORS, body: JSON.stringify(reply.body) });
    });
    await open(page);
    await expand(page);
    await pickBoth(page);
    await expect(status(page)).toHaveText('Strecke wird berechnet …');
    await km(page).fill('120');
    release();
    await page.waitForTimeout(300);
    await expect(km(page)).toHaveValue('120');
    await expect(status(page)).toHaveText('');

    // After a finished fill, a later hand edit stays until "Neu berechnen" is tapped.
    await page.locator('#calc-route-recalc').click();
    await expect(km(page)).toHaveValue('81,2');
    await km(page).fill('75');
    await page.waitForTimeout(400);
    await expect(km(page)).toHaveValue('75');
  });

  test('retyping a place forgets the earlier pick and uses the new one', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expand(page);
    await pickBoth(page);
    await expect(km(page)).toHaveValue('81,2');
    await expect(page.locator('#calc-route-recalc')).toBeVisible();
    await to(page).fill('Stuttg');
    await expect(page.locator('#calc-route-recalc')).toBeHidden();
    await page.waitForTimeout(500);
    // No second distance call until the new place is picked.
    expect(seen.filter((s) => s.body['action'] === 'distance')).toHaveLength(1);
  });

  test('shows the empty-result message and keeps km untouched', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await km(page).fill('42');
    await expand(page);
    await from(page).fill('Nirgendwo');
    await expect(status(page)).toHaveText('Keine Treffer. Prüfe die Schreibweise oder gib die Kilometer selbst ein.');
    await expect(km(page)).toHaveValue('42');
  });

  const failures: { name: string; reply: Reply; message: string | RegExp }[] = [
    { name: 'offline', reply: 'abort', message: /^Keine Verbindung zum Dienst\./ },
    {
      name: 'rate limit with retry time',
      reply: { status: 429, body: { error: 'rate_limited' }, headers: { 'Retry-After': '600' } },
      message: 'Zu viele Anfragen. Versuch es in etwa 10 Minuten noch einmal.',
    },
    {
      name: 'rate limit without a readable retry time',
      reply: { status: 429, body: { error: 'rate_limited' } },
      message: 'Zu viele Anfragen. Versuch es später noch einmal.',
    },
    {
      name: 'daily limit in hours',
      reply: { status: 429, body: { error: 'rate_limited' }, headers: { 'Retry-After': '7300' } },
      message: 'Zu viele Anfragen. Versuch es in etwa 3 Stunden noch einmal.',
    },
    { name: 'provider unconfigured', reply: { status: 503, body: { error: 'provider_unconfigured' } }, message: /^Die Streckenberechnung ist noch nicht eingerichtet\./ },
    { name: 'provider unavailable', reply: { status: 503, body: { error: 'provider_unavailable' } }, message: /^Die Streckenberechnung geht gerade nicht\./ },
    { name: 'unusable body', reply: { status: 200, body: { nope: true } }, message: /^Die Streckenberechnung geht gerade nicht\./ },
  ];

  for (const f of failures) {
    test(`suggest failure: ${f.name}`, async ({ page }) => {
      await mockApi(page, () => f.reply);
      await open(page);
      await km(page).fill('42');
      await expand(page);
      await from(page).fill('Karlsruhe');
      await expect(status(page)).toHaveText(f.message);
      await expect(page.locator('#calc-route-from-list')).toBeHidden();
      await expect(km(page)).toHaveValue('42');
    });
  }

  test('distance failure: no route', async ({ page }) => {
    await mockApi(page, (body) => (body['action'] === 'distance' ? { status: 404, body: { error: 'no_route' } } : defaultHandler(body)));
    await open(page);
    await km(page).fill('42');
    await expand(page);
    await pickBoth(page);
    await expect(status(page)).toHaveText(
      'Zwischen diesen Orten gibt es keine Strecke mit dem Auto. Wähle andere Orte oder gib die Kilometer selbst ein.',
    );
    await expect(km(page)).toHaveValue('42');
    await expect(page.locator('#calc-route-attribution')).toBeHidden();
  });

  test('distance failure: rate limited with minutes, then recalculate works', async ({ page }) => {
    let limited = true;
    await mockApi(page, (body) =>
      body['action'] === 'distance' && limited
        ? { status: 429, body: { error: 'rate_limited' }, headers: { 'Retry-After': '60' } }
        : defaultHandler(body),
    );
    await open(page);
    await expand(page);
    await pickBoth(page);
    await expect(status(page)).toHaveText('Zu viele Anfragen. Versuch es in etwa einer Minute noch einmal.');
    limited = false;
    await page.locator('#calc-route-recalc').click();
    await expect(km(page)).toHaveValue('81,2');
  });

  test('has no axe violations, collapsed, expanded, with suggestions and with an error', async ({ page }) => {
    await mockApi(page);
    await open(page);
    const scan = async () => expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
    await scan();
    await expand(page);
    await scan();
    await from(page).fill('Karlsruhe');
    await expect(page.locator('#calc-route-from-list .route-option')).toBeVisible();
    await scan();
    await page.locator('#calc-route-from-list .route-option').click();
    await choose(page, 'to', 'Stuttgart');
    await expect(status(page)).toContainText('Einfache Strecke');
    await scan();
    await from(page).fill('Nirgendwo');
    await expect(status(page)).toContainText('Keine Treffer');
    await scan();
  });

  test('result stays first on the page', async ({ page }) => {
    await mockApi(page);
    await open(page);
    const result = await page.locator('#calc-result').boundingBox();
    const row = await page.locator('#calc-route').boundingBox();
    expect(result!.y).toBeLessThan(row!.y);
  });
});

test.describe('route field (en)', () => {
  test('uses English text, lang=en and a one-way label', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page, '/en/');
    await expect(page.locator('#calc-route > summary')).toHaveText('Enter start and destination, calculate distance');
    await expand(page);
    await pickBoth(page);
    await expect(km(page)).toHaveValue('81.2');
    await expect(status(page)).toContainText('One-way distance: 81.2 km');
    expect(seen[0]?.body['lang']).toBe('en');
  });
});
