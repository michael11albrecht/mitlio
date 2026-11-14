// Live fuel price chips (PW-T04). Runs against the build with a fake FUEL_API_URL
// (scripts/serve-fuel-fixture.mjs); the API is mocked with page.route, no real network.
import AxeBuilder from '@axe-core/playwright';
import { expect, test, type Page, type Route } from '@playwright/test';

import { formatAsOf, formatChipPrice, fuelUrl, parseFuelPrice, parsePlz, roundCoord } from '../src/lib/fuel';

const API_ORIGIN = 'https://fuel.mitlio.test';
const API = `${API_ORIGIN}/functions/v1/fuel-prices`;
const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'apikey, authorization',
};

type Reply = { status: number; body: unknown };
type Handler = (url: URL) => Reply;

const nationalBody = (type: string, milli: number, approximation = false) => ({
  type,
  priceMilli: milli,
  source: 'eu-oil-bulletin',
  scope: 'national',
  fetchedAt: '2026-11-10T00:00:00.000Z',
  stations: 0,
  attribution: 'Quelle: EU Weekly Oil Bulletin',
  ...(approximation ? { approximation: 'e5' } : {}),
});

const nearbyBody = (type: string, milli: number) => ({
  type,
  priceMilli: milli,
  source: 'tankerkoenig',
  scope: 'nearby',
  fetchedAt: new Date().toISOString(),
  stations: 14,
  attribution: 'Daten: MTS-K via Tankerkönig (CC BY 4.0)',
});

const defaultHandler: Handler = (url) => {
  const type = url.searchParams.get('type') ?? '';
  const nearby = url.searchParams.has('lat') || url.searchParams.has('plz');
  if (nearby) {
    const body = { ...nearbyBody(type, type === 'diesel' ? 1649 : 1759), scope: url.searchParams.has('plz') ? 'plz' : 'nearby' };
    return { status: 200, body };
  }
  const milli = { e5: 1799, e10: 1799, diesel: 1689 }[type] ?? 1700;
  return { status: 200, body: nationalBody(type, milli, type === 'e10') };
};

/** Mocks the API; returns the list of requests it served. */
async function mockApi(page: Page, handler: Handler = defaultHandler) {
  const seen: { url: URL; headers: Record<string, string> }[] = [];
  await page.route(`${API_ORIGIN}/**`, async (route: Route) => {
    const req = route.request();
    if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
    const url = new URL(req.url());
    seen.push({ url, headers: req.headers() });
    const reply = handler(url);
    return route.fulfill({
      status: reply.status,
      contentType: 'application/json',
      headers: CORS,
      body: JSON.stringify(reply.body),
    });
  });
  return seen;
}

const amount = (page: Page) => page.locator('#calc-result-amount');
const chip = (page: Page, type: string) => page.locator(`.chip[data-fuel="${type}"]`);

async function open(page: Page, path = '/') {
  await page.goto(path);
  await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
}

test.describe('fuel lib', () => {
  test('rounds coordinates to 2 decimals and never emits exponents or -0', () => {
    expect(roundCoord(48.13743)).toBe('48.14');
    expect(roundCoord(11.57549)).toBe('11.58');
    expect(roundCoord(-0.001)).toBe('0.00');
    expect(roundCoord(1e-7)).toBe('0.00');
  });

  test('builds URLs per scope', () => {
    expect(fuelUrl(API, 'e5', { kind: 'national' })).toBe(`${API}?type=e5`);
    expect(fuelUrl(API, 'diesel', { kind: 'nearby', lat: 48.13743, lng: 11.57549 })).toBe(
      `${API}?type=diesel&lat=48.14&lng=11.58`,
    );
    expect(fuelUrl(API, 'e10', { kind: 'plz', plz: '80331' })).toBe(`${API}?type=e10&plz=80331`);
  });

  test('validates PLZ and API bodies', () => {
    expect(parsePlz(' 80331 ')).toBe('80331');
    expect(parsePlz('8033')).toBeNull();
    expect(parsePlz('80a31')).toBeNull();
    expect(parseFuelPrice(nationalBody('e5', 1799), 'e5')?.priceMilli).toBe(1799);
    expect(parseFuelPrice(nationalBody('e10', 1799, true), 'e10')?.approximation).toBe(true);
    expect(parseFuelPrice(nationalBody('e5', 1.799), 'e5')).toBeNull();
    expect(parseFuelPrice(nationalBody('e5', 1799), 'diesel')).toBeNull();
    expect(parseFuelPrice({ ...nationalBody('e5', 1799), source: 'x' }, 'e5')).toBeNull();
    expect(parseFuelPrice(null, 'e5')).toBeNull();
  });

  test('formats price and age', () => {
    expect(formatChipPrice(1799, 'de')).toBe('1,799 €');
    expect(formatChipPrice(1689, 'en')).toBe('1.689 €');
    const now = new Date('2026-11-14T12:00:00Z');
    expect(formatAsOf({ source: 'eu-oil-bulletin', fetchedAt: '2026-11-10T00:00:00Z' }, 'de', now)).toBe('10.11.');
    expect(formatAsOf({ source: 'eu-oil-bulletin', fetchedAt: '2026-11-10T00:00:00Z' }, 'en', now)).toBe('10 Nov');
    expect(formatAsOf({ source: 'tankerkoenig', fetchedAt: '2026-11-14T09:05:00Z' }, 'de', now)).toBe('10:05');
    expect(formatAsOf({ source: 'tankerkoenig', fetchedAt: '2026-11-13T09:05:00Z' }, 'de', now)).toBe('13.11.');
  });
});

test.describe('fuel chips (de)', () => {
  test('shows the national average with an honest label, one request per fuel type, no location', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toHaveText(/E5\s*1,799 €/);
    await expect(chip(page, 'e10')).toHaveText(/E10\s*≈1,799 €/);
    await expect(chip(page, 'diesel')).toHaveText(/Diesel\s*1,689 €/);
    const source = page.locator('#calc-fuel-source');
    await expect(source).toContainText('Ø Deutschland');
    await expect(source).toContainText('Stand 10.11.');
    await expect(source).toContainText('Quelle: EU Weekly Oil Bulletin');
    await expect(source).toContainText('geschätzt');
    expect(seen.map((s) => s.url.searchParams.get('type')).sort()).toEqual(['diesel', 'e10', 'e5']);
    for (const s of seen) {
      expect(s.url.searchParams.has('lat')).toBe(false);
      expect(s.url.searchParams.has('lng')).toBe(false);
      expect(s.url.searchParams.has('plz')).toBe(false);
      expect(s.headers['apikey']).toBe('test-anon-key');
    }
  });

  test('tapping a chip fills the price and the result updates live', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await page.locator('#calc-km').fill('250');
    await page.locator('#calc-cons').fill('6,5');
    await page.locator('#calc-persons').fill('3');
    await chip(page, 'e5').click();
    await expect(page.locator('#calc-price')).toHaveValue('1,799');
    await expect(amount(page)).toHaveText(/^9,75\s€$/);
    await expect(chip(page, 'e5')).toHaveAttribute('aria-pressed', 'true');
    await expect(chip(page, 'diesel')).toHaveAttribute('aria-pressed', 'false');

    await chip(page, 'diesel').click();
    await expect(page.locator('#calc-price')).toHaveValue('1,689');
    await expect(amount(page)).toHaveText(/^9,15\s€$/);
    expect(page.url()).toContain('p=1.689');

    await page.locator('#calc-price').fill('2');
    await expect(chip(page, 'diesel')).toHaveAttribute('aria-pressed', 'false');
  });

  test('the approximation chip is announced as an estimate', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await expect(chip(page, 'e10')).toHaveAttribute('aria-label', 'E10 ≈1,799 € übernehmen');
    await expect(chip(page, 'e5')).toHaveAttribute('aria-label', 'E5 1,799 € übernehmen');
    await chip(page, 'e10').click();
    await expect(page.locator('#calc-price')).toHaveValue('1,799');
  });

  test('chips hide for electric and return for fuel', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await expect(page.locator('#calc-fuel')).toBeVisible();
    await page.getByLabel('Elektro').check();
    await expect(page.locator('#calc-fuel')).toBeHidden();
    await page.getByLabel('Benzin / Diesel').check();
    await expect(page.locator('#calc-fuel')).toBeVisible();
  });

  test('a 503 on the national average leaves the page exactly as before', async ({ page }) => {
    await mockApi(page, () => ({ status: 503, body: { error: 'provider_unavailable' } }));
    await open(page);
    await expect(page.locator('#calc-fuel')).toBeHidden();
    await expect(amount(page)).toHaveText(/^6,30\s€$/);
    await page.locator('#calc-price').fill('1,95');
    await expect(amount(page)).not.toHaveText(/^6,30\s€$/);
  });

  test('a malformed body is treated as no live price', async ({ page }) => {
    await mockApi(page, () => ({ status: 200, body: { priceMilli: 1.8 } }));
    await open(page);
    await expect(page.locator('#calc-fuel')).toBeHidden();
  });

  test('does not touch geolocation or send a location on load', async ({ page, context }) => {
    await context.grantPermissions(['geolocation']);
    await context.setGeolocation({ latitude: 48.13743, longitude: 11.57549 });
    await page.addInitScript(() => {
      (window as unknown as { __geo: number }).__geo = 0;
      const orig = navigator.geolocation.getCurrentPosition.bind(navigator.geolocation);
      navigator.geolocation.getCurrentPosition = (...a) => {
        (window as unknown as { __geo: number }).__geo++;
        return orig(...a);
      };
    });
    const seen = await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    expect(await page.evaluate(() => (window as unknown as { __geo: number }).__geo)).toBe(0);
    expect(seen.every((s) => !s.url.searchParams.has('lat'))).toBe(true);
  });

  test('sets no cookies and only talks to the configured API origin', async ({ page, baseURL }) => {
    const foreign: string[] = [];
    page.on('request', (r) => {
      const u = r.url();
      if (!u.startsWith(baseURL as string) && !u.startsWith(`${API_ORIGIN}/`) && !u.startsWith('data:')) {
        foreign.push(u);
      }
    });
    await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    await chip(page, 'e5').click();
    expect(await page.evaluate(() => document.cookie)).toBe('');
    expect(await page.context().cookies()).toEqual([]);
    expect(foreign).toEqual([]);
  });

  test('is axe clean with chips and location controls shown', async ({ page }) => {
    await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    await chip(page, 'e5').click();
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test('chips fit at 320 px without horizontal scrolling', async ({ page }) => {
    await mockApi(page);
    await page.setViewportSize({ width: 320, height: 640 });
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    );
    expect(overflow).toBeLessThanOrEqual(0);
  });
});

test.describe('fuel chips, nearby (geolocation granted)', () => {
  test.use({ permissions: ['geolocation'], geolocation: { latitude: 48.13743, longitude: 11.57549 } });

  test('asks for the location only after the tap and sends rounded coordinates', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    const before = seen.length;
    await page.getByRole('button', { name: 'In meiner Nähe' }).click();
    await expect(page.locator('#calc-fuel-source')).toContainText('In deiner Nähe');
    await expect(page.locator('#calc-fuel-source')).toContainText('Daten: MTS-K via Tankerkönig (CC BY 4.0)');
    await expect(chip(page, 'diesel')).toHaveText(/Diesel\s*1,649 €/);
    const regional = seen.slice(before);
    expect(regional).toHaveLength(3);
    for (const s of regional) {
      expect(s.url.searchParams.get('lat')).toBe('48.14');
      expect(s.url.searchParams.get('lng')).toBe('11.58');
      expect(s.url.search).not.toContain('48.137');
    }
    await chip(page, 'diesel').click();
    await expect(page.locator('#calc-price')).toHaveValue('1,649');
  });

  test('hides the location controls when the API answers provider_unconfigured', async ({ page }) => {
    await mockApi(page, (url) =>
      url.searchParams.has('lat') || url.searchParams.has('plz')
        ? { status: 503, body: { error: 'provider_unconfigured' } }
        : defaultHandler(url),
    );
    await open(page);
    await page.getByRole('button', { name: 'In meiner Nähe' }).click();
    await expect(page.locator('#calc-fuel-where')).toBeHidden();
    await expect(page.locator('#calc-fuel-status')).toHaveText('Regionale Preise sind noch nicht verfügbar.');
    // National chips stay usable.
    await expect(chip(page, 'e5')).toBeVisible();
  });

  test('shows a message on 404 and keeps the national chips', async ({ page }) => {
    await mockApi(page, (url) =>
      url.searchParams.has('lat') ? { status: 404, body: { error: 'no_data' } } : defaultHandler(url),
    );
    await open(page);
    await page.getByRole('button', { name: 'In meiner Nähe' }).click();
    await expect(page.locator('#calc-fuel-status')).toContainText('keine Preise');
    await expect(page.locator('#calc-fuel-source')).toContainText('Ø Deutschland');
  });

  test('a postcode works as the alternative and is validated', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    await page.locator('#calc-fuel-plz').fill('803');
    await page.getByRole('button', { name: 'Preise zeigen' }).click();
    await expect(page.locator('#calc-fuel-status')).toHaveText('Bitte eine 5-stellige PLZ eingeben.');
    expect(seen.filter((s) => s.url.searchParams.has('plz'))).toHaveLength(0);
    await page.locator('#calc-fuel-plz').fill('80331');
    await page.getByRole('button', { name: 'Preise zeigen' }).click();
    await expect(page.locator('#calc-fuel-source')).toContainText('Region PLZ 80331');
    expect(seen.filter((s) => s.url.searchParams.get('plz') === '80331')).toHaveLength(3);
    expect(seen.every((s) => !s.url.searchParams.has('lat'))).toBe(true);
  });
});

test.describe('fuel chips, nearby (geolocation denied)', () => {
  test.use({ permissions: [] });

  test('explains the denial and offers the postcode instead', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page);
    await expect(chip(page, 'e5')).toBeVisible();
    await page.getByRole('button', { name: 'In meiner Nähe' }).click();
    await expect(page.locator('#calc-fuel-status')).toContainText('Standort nicht freigegeben');
    await expect(page.locator('#calc-fuel-plz')).toBeVisible();
    expect(seen.every((s) => !s.url.searchParams.has('lat'))).toBe(true);
  });
});

test.describe('fuel chips (en)', () => {
  test('localizes label, price format and the price field', async ({ page }) => {
    await mockApi(page);
    await open(page, '/en/');
    await expect(chip(page, 'e5')).toHaveText(/E5\s*1\.799 €/);
    await expect(page.locator('#calc-fuel-source')).toContainText('Germany average · as of 10 Nov');
    await chip(page, 'diesel').click();
    await expect(page.locator('#calc-price')).toHaveValue('1.689');
  });
});

test.describe('km-rate landing page', () => {
  test('has no fuel chips and makes no API request', async ({ page }) => {
    const seen = await mockApi(page);
    await open(page, '/kilometerpauschale-rechner/');
    await expect(page.locator('#calc-fuel')).toHaveCount(0);
    expect(seen).toHaveLength(0);
  });
});
