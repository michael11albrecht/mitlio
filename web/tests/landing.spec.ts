import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

// Every landing page embeds the calculator with the numbers of its own worked example.
const pages = [
  { slug: 'fahrtkostenrechner', km: '250', cons: '6,5', price: '1,80', persons: '3', driverPays: true },
  { slug: 'spritkosten-teilen', km: '400', cons: '6,8', price: '1,79', persons: '4', driverPays: true },
  { slug: 'fahrgemeinschaft-kosten-aufteilen', km: '320', cons: '7', price: '1,80', persons: '5', driverPays: true, extras: '18' },
  { slug: 'pendler-fahrgemeinschaft', km: '28', cons: '5,8', price: '1,80', persons: '3', driverPays: true, roundTrip: true },
  { slug: 'mitfahrer-kosten-berechnen', km: '150', cons: '7,5', price: '1,80', persons: '3', driverPays: false },
  { slug: 'kilometerpauschale-rechner', km: '120', price: '0,30', persons: '3', driverPays: true, rate: true },
  { slug: 'elektroauto-ladekosten-teilen', km: '200', cons: '19', price: '0,45', persons: '3', driverPays: true, ev: true },
] as const;

for (const p of pages) {
  test.describe(`/${p.slug}/`, () => {
    test.beforeEach(async ({ page }) => {
      await page.goto(`/${p.slug}/`);
      await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
    });

    test('renders the calculator with its preset', async ({ page }) => {
      await expect(page.locator('#calc-km')).toHaveValue(p.km);
      await expect(page.locator('#calc-price')).toHaveValue(p.price);
      await expect(page.locator('#calc-persons')).toHaveValue(p.persons);
      if ('cons' in p) await expect(page.locator('#calc-cons')).toHaveValue(p.cons);
      if ('extras' in p) await expect(page.locator('#calc-extras')).toHaveValue(p.extras);
      if (p.driverPays) await expect(page.locator('#calc-driver-pays')).toBeChecked();
      else await expect(page.locator('#calc-driver-pays')).not.toBeChecked();
      if ('roundTrip' in p) await expect(page.locator('#calc-round-trip')).toBeChecked();
      else await expect(page.locator('#calc-round-trip')).not.toBeChecked();
      const ev = page.locator('input[name="energy"][value="ev"]');
      if ('ev' in p) await expect(ev).toBeChecked();
      else await expect(ev).not.toBeChecked();
    });

    test('the result matches the worked example on the page', async ({ page }) => {
      const amount = (await page.locator('#calc-result-amount').textContent())?.trim() ?? '';
      expect(amount).toMatch(/€/);
      const example = await page.locator('article').textContent();
      // Intl uses a no-break space before the euro sign; compare with plain spaces.
      expect(example?.replace(/\s/g, ' ')).toContain(amount.replace(/\s/g, ' '));
    });

    test('has one h1, a FAQ and sibling links', async ({ page }) => {
      await expect(page.locator('h1')).toHaveCount(1);
      const faq = await page.locator('article h3').count();
      expect(faq).toBeGreaterThanOrEqual(4);
      expect(faq).toBeLessThanOrEqual(6);
      expect(await page.locator('nav.related a').count()).toBeGreaterThanOrEqual(3);
    });

    test('has no axe violations', async ({ page }) => {
      const results = await new AxeBuilder({ page }).analyze();
      expect(results.violations).toEqual([]);
    });
  });
}

test('km-rate page asks for a rate per km, not for consumption', async ({ page }) => {
  await page.goto('/kilometerpauschale-rechner/');
  await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
  await expect(page.locator('#calc-cons')).toBeHidden();
  await expect(page.locator('#calc-price-label')).toHaveText('Kilometersatz (€/km)');
  // 120 km x 0.30 EUR/km = 36 EUR over 3 people.
  await expect(page.locator('#calc-b-total')).toHaveText(/^36,00\s€$/);
  await expect(page.locator('#calc-result-amount')).toHaveText(/^12,00\s€$/);
  await expect(page.locator('#calc-b-fuel-label')).toHaveText('Kilometerkosten');
  await expect(page.locator('#calc-cta-open')).toHaveCount(0);
  await page.locator('#calc-price').fill('0,5');
  await expect(page.locator('#calc-result-amount')).toHaveText(/^20,00\s€$/);
});

test('EV page uses kWh units and the URL still wins over the preset', async ({ page }) => {
  await page.goto('/elektroauto-ladekosten-teilen/');
  await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
  await expect(page.locator('#calc-cons-unit')).toHaveText('kWh/100 km');
  await page.goto('/elektroauto-ladekosten-teilen/?ev=0&km=100&l100=7&p=1.8&n=2');
  await expect(page.locator('#calc-cons-unit')).toHaveText('l/100 km');
  await expect(page.locator('#calc-km')).toHaveValue('100');
  await expect(page.locator('#calc-cons')).toHaveValue('7');
});

test('landing pages are indexable, have a canonical, structured data and no language alternates', async ({ page }) => {
  await page.goto('/fahrtkostenrechner/');
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/fahrtkostenrechner\/$/);
  await expect(page.locator('link[rel="alternate"][hreflang]')).toHaveCount(0);
  await expect(page.locator('meta[name="robots"]')).toHaveCount(0);
  const types = await page
    .locator('script[type="application/ld+json"]')
    .evaluateAll((els) => els.map((e) => JSON.parse(e.textContent ?? '{}')['@type']));
  expect(types).toEqual(['Organization', 'WebApplication', 'FAQPage', 'HowTo']);
  await expect(page.locator('meta[property="og:image"]')).toHaveAttribute('content', /\/og\/fahrtkostenrechner\.png$/);
});

test('the home page links to every landing page', async ({ page }) => {
  await page.goto('/');
  for (const p of pages) await expect(page.locator(`nav.related a[href="/${p.slug}/"]`)).toHaveCount(1);
});
