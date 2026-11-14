import AxeBuilder from '@axe-core/playwright';
import { expect, test, type Page } from '@playwright/test';

const amount = (page: Page) => page.locator('#calc-result-amount');

// Fixture "consumption, driver counts" of tool/fixtures/trip_web.json: 250 km, 6.5 l, 1.799, 3 persons.
async function typeFixtureTrip(page: Page) {
  await page.locator('#calc-km').fill('250');
  await page.locator('#calc-cons').fill('6,5');
  await page.locator('#calc-price').fill('1,799');
  await page.locator('#calc-persons').fill('3');
}

test.describe('calculator (de)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
  });

  test('shows a result immediately from smart defaults, no button press needed', async ({ page }) => {
    await expect(page.locator('#calc-result-lead')).toHaveText('Jede Person zahlt');
    await expect(amount(page)).toHaveText(/^6,30\s€$/);
    await expect(page.getByRole('button', { name: /berechnen/i })).toHaveCount(0);
  });

  test('typing updates the result live and keeps the URL in sync', async ({ page }) => {
    await typeFixtureTrip(page);
    await expect(amount(page)).toHaveText(/^9,75\s€$/);
    await expect(page.locator('#calc-result-extra')).toContainText('1 × 9,75');
    await expect(page.locator('#calc-result-extra')).toContainText('2 × 9,74');
    await expect.poll(() => new URL(page.url()).search).toBe(
      '?km=250&l100=6.5&p=1.799&n=3&d=1&rt=0',
    );
  });

  test('reload restores the state from the URL', async ({ page }) => {
    await typeFixtureTrip(page);
    await page.locator('#calc-round-trip').check();
    await page.locator('#calc-extras').fill('11,5');
    await expect.poll(() => page.url()).toContain('rt=1');
    await page.reload();
    await expect(page.locator('#calc-km')).toHaveValue('250');
    await expect(page.locator('#calc-cons')).toHaveValue('6,5');
    await expect(page.locator('#calc-price')).toHaveValue('1,799');
    await expect(page.locator('#calc-persons')).toHaveValue('3');
    await expect(page.locator('#calc-extras')).toHaveValue('11,5');
    await expect(page.locator('#calc-round-trip')).toBeChecked();
    // 250 km round trip: fuel 58.47 + tolls 11.50 = 69.97 over 3 people.
    await expect(page.locator('#calc-b-total')).toHaveText(/^69,97\s€$/);
    await expect(amount(page)).toHaveText(/^23,33\s€$/);
  });

  test('invalid or partial URL params fall back to defaults', async ({ page }) => {
    await page.goto('/?km=abc&n=0&d=0&x=-4');
    await expect(page.locator('#calc-km')).toHaveValue('100');
    await expect(page.locator('#calc-persons')).toHaveValue('2');
    await expect(page.locator('#calc-driver-pays')).not.toBeChecked();
    await expect(page.locator('#calc-extras')).toHaveValue('');
  });

  test('driver does not pay: passengers pay, driver receives the total', async ({ page }) => {
    await typeFixtureTrip(page);
    await page.locator('#calc-driver-pays').uncheck();
    await expect(page.locator('#calc-result-lead')).toHaveText('Jede mitfahrende Person zahlt');
    await expect(amount(page)).toHaveText(/^14,62\s€$/);
    await expect(page.locator('#calc-result-sub')).toHaveText(/^Fahrer bekommt 29,23\s€$/);
    await page.reload();
    await expect(page.locator('#calc-driver-pays')).not.toBeChecked();
    await expect(amount(page)).toHaveText(/^14,62\s€$/);
  });

  test('driver free with one person explains the problem calmly', async ({ page }) => {
    await page.locator('#calc-driver-pays').uncheck();
    await page.locator('#calc-persons-dec').click();
    await expect(page.locator('#calc-persons-error')).toHaveText(/mindestens 2 Personen/);
    await expect(page.locator('#calc-result-lead')).toHaveText('Noch kein Ergebnis');
  });

  test('EV mode switches units, defaults and label texts', async ({ page }) => {
    await page.getByLabel('Elektro').check();
    await expect(page.locator('#calc-cons')).toHaveValue('18');
    await expect(page.locator('#calc-price')).toHaveValue('0,35');
    await expect(page.locator('#calc-cons-label')).toContainText('kWh/100 km');
    await expect(page.locator('#calc-price-label')).toContainText('Preis pro kWh');
    await expect(page.locator('#calc-b-fuel-label')).toHaveText('Strom');
    // 100 km * 18 kWh/100 km * 0.35 = 6.30 over 2 people.
    await expect(amount(page)).toHaveText(/^3,15\s€$/);
    await expect.poll(() => page.url()).toContain('ev=1');
    await page.reload();
    await expect(page.getByLabel('Elektro')).toBeChecked();
    await expect(amount(page)).toHaveText(/^3,15\s€$/);
  });

  test('switching drive keeps values the user changed', async ({ page }) => {
    await page.locator('#calc-cons').fill('5,5');
    await page.getByLabel('Elektro').check();
    await expect(page.locator('#calc-cons')).toHaveValue('5,5');
  });

  test('stepper changes persons and clamps at 1', async ({ page }) => {
    await page.locator('#calc-persons-inc').click();
    await expect(page.locator('#calc-persons')).toHaveValue('3');
    await page.locator('#calc-persons-dec').click();
    await page.locator('#calc-persons-dec').click();
    await page.locator('#calc-persons-dec').click();
    await expect(page.locator('#calc-persons')).toHaveValue('1');
    await expect(amount(page)).toHaveText(/^12,60\s€$/);
  });

  test('breakdown is collapsible and shows fuel, extras and total', async ({ page }) => {
    await page.locator('#calc-extras').fill('10');
    const details = page.locator('details.breakdown');
    await expect(details).not.toHaveAttribute('open', '');
    await details.locator('summary').click();
    await expect(page.locator('#calc-b-fuel')).toHaveText(/^12,60\s€$/);
    await expect(page.locator('#calc-b-extras')).toHaveText(/^10,00\s€$/);
    await expect(page.locator('#calc-b-total')).toHaveText(/^22,60\s€$/);
  });

  test('inline validation is calm: no dialogs, messages tied to fields', async ({ page }) => {
    let dialogs = 0;
    page.on('dialog', (d) => {
      dialogs += 1;
      void d.dismiss();
    });
    const km = page.locator('#calc-km');
    await km.fill('abc');
    await expect(page.locator('#calc-km-error')).toHaveText('Das ist keine gültige Zahl.');
    await expect(km).toHaveAttribute('aria-invalid', 'true');
    await expect(km).toHaveAttribute('aria-describedby', 'calc-km-error');
    await expect(page.locator('#calc-result-lead')).toHaveText('Noch kein Ergebnis');
    await km.fill('0');
    await expect(page.locator('#calc-km-error')).toHaveText('Die Strecke muss größer als 0 sein.');
    await km.fill('-5');
    await expect(page.locator('#calc-km-error')).toHaveText('Bitte eine Zahl ab 0 eingeben.');
    await km.fill('80');
    await expect(page.locator('#calc-km-error')).toBeHidden();
    await expect(km).toHaveAttribute('aria-invalid', 'false');
    await expect(amount(page)).toHaveText(/^5,04\s€$/);
    expect(dialogs).toBe(0);
  });

  test('an emptied field only complains after leaving it', async ({ page }) => {
    const km = page.locator('#calc-km');
    await km.fill('');
    await expect(page.locator('#calc-km-error')).toBeHidden();
    await expect(page.locator('#calc-result-lead')).toHaveText('Noch kein Ergebnis');
    await page.locator('#calc-cons').focus();
    await expect(page.locator('#calc-km-error')).toHaveText('Bitte eine Zahl eingeben.');
  });

  test('result card is an aria-live region', async ({ page }) => {
    await expect(page.locator('#calc-result [aria-live="polite"]')).toHaveAttribute(
      'aria-atomic',
      'true',
    );
  });

  test('sets no cookies and makes no external requests', async ({ page, baseURL }) => {
    const external: string[] = [];
    page.on('request', (r) => {
      if (!r.url().startsWith(baseURL as string) && !r.url().startsWith('data:')) {
        external.push(r.url());
      }
    });
    await page.goto('/');
    await typeFixtureTrip(page);
    await expect(amount(page)).toHaveText(/^9,75\s€$/);
    expect(await page.evaluate(() => document.cookie)).toBe('');
    expect(await page.context().cookies()).toEqual([]);
    expect(external).toEqual([]);
  });

  test('is usable at 320 px without horizontal scrolling', async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 640 });
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    );
    expect(overflow).toBeLessThanOrEqual(0);
  });
});

test.describe('calculator (en)', () => {
  test('uses English labels and number formatting', async ({ page }) => {
    await page.goto('/en/');
    await expect(page.locator('#calc-result-lead')).toHaveText('Each person pays');
    await expect(amount(page)).toHaveText('€6.30');
    await page.locator('#calc-price').fill('2.5');
    await expect(amount(page)).toHaveText('€8.75');
    await page.reload();
    await expect(page.locator('#calc-price')).toHaveValue('2.50');
  });
});

test.describe('accessibility (axe)', () => {
  for (const path of ['/', '/en/']) {
    for (const scheme of ['light', 'dark'] as const) {
      test(`no violations on ${path} (${scheme})`, async ({ page }) => {
        await page.emulateMedia({ colorScheme: scheme });
        await page.goto(path);
        await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
        const results = await new AxeBuilder({ page }).analyze();
        expect(results.violations).toEqual([]);
      });
    }
  }

  test('no violations in the error state with breakdown open', async ({ page }) => {
    await page.goto('/?km=abc&x=zz');
    await page.locator('details.breakdown summary').click();
    await page.locator('#calc-km').focus();
    await page.locator('#calc-cons').focus();
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });
});

test.describe('screenshots', () => {
  const shots = [
    { name: 'de-mobile-light', path: '/', width: 390, height: 1000, scheme: 'light' },
    { name: 'de-mobile-dark', path: '/', width: 390, height: 1000, scheme: 'dark' },
    { name: 'en-desktop-light', path: '/en/', width: 1100, height: 900, scheme: 'light' },
    { name: 'de-mobile-driver-free', path: '/?d=0&n=4&km=250&x=12', width: 390, height: 1000, scheme: 'light' },
  ] as const;
  for (const s of shots) {
    test(s.name, async ({ page }, testInfo) => {
      await page.setViewportSize({ width: s.width, height: s.height });
      await page.emulateMedia({ colorScheme: s.scheme });
      await page.goto(s.path);
      await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
      const file = testInfo.outputPath(`${s.name}.png`);
      await page.screenshot({ path: file, fullPage: true });
      await testInfo.attach(s.name, { path: file, contentType: 'image/png' });
    });
  }
});
