// Contact form. Runs against the build with a fake FUEL_API_URL (scripts/serve-fuel-fixture.mjs); the API is
// mocked with page.route, no real network.
import AxeBuilder from '@axe-core/playwright';
import { expect, test, type Page } from '@playwright/test';

const API_ORIGIN = 'https://fuel.mitlio.test';
const API = `${API_ORIGIN}/functions/v1/contact`;
const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'apikey, authorization, content-type',
  'access-control-expose-headers': 'Retry-After',
};

type Reply = { status: number; body: unknown; headers?: Record<string, string> } | 'abort';

async function mockApi(page: Page, reply: Reply) {
  const seen: { headers: Record<string, string>; body: Record<string, unknown> }[] = [];
  await page.route(`${API_ORIGIN}/**`, async (route) => {
    const req = route.request();
    if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
    seen.push({ headers: req.headers(), body: req.postDataJSON() as Record<string, unknown> });
    if (reply === 'abort') return route.abort('connectionrefused');
    return route.fulfill({
      status: reply.status,
      headers: { ...CORS, ...reply.headers },
      contentType: 'application/json',
      body: JSON.stringify(reply.body),
    });
  });
  return seen;
}

const fill = async (page: Page, over: { email?: string; message?: string } = {}) => {
  await page.getByLabel('Name (optional)').fill('Mia');
  await page.getByLabel('Deine E-Mail-Adresse').fill(over.email ?? 'mia@example.org');
  await page.getByLabel('Deine Nachricht').fill(over.message ?? 'Hallo, ich habe eine Frage zur App.');
};
const submit = (page: Page) => page.getByRole('button', { name: 'Nachricht senden' }).click();

test('success: posts the form once and shows the thanks inline', async ({ page }) => {
  const seen = await mockApi(page, { status: 200, body: { ok: true } });
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.getByText('Danke! Wir melden uns per E-Mail.')).toBeVisible();
  await expect(page.locator('#contact-form')).toBeHidden();
  expect(seen).toHaveLength(1);
  expect(seen[0]!.body).toEqual({
    name: 'Mia',
    email: 'mia@example.org',
    message: 'Hallo, ich habe eine Frage zur App.',
    locale: 'de',
    website: '',
  });
  expect(seen[0]!.headers['apikey']).toBe('test-anon-key');
  expect(seen[0]!.headers['authorization']).toBe('Bearer test-anon-key');
});

test('english page sends locale en and shows an english thanks', async ({ page }) => {
  const seen = await mockApi(page, { status: 200, body: { ok: true } });
  await page.goto('/en/contact/');
  await page.getByLabel('Your email address').fill('mia@example.org');
  await page.getByLabel('Your message').fill('Hello, I have a question.');
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect(page.getByText('Thanks! We will get back to you by email.')).toBeVisible();
  expect(seen[0]!.body['locale']).toBe('en');
});

test('validation error: inline, focused, nothing sent', async ({ page }) => {
  const seen = await mockApi(page, { status: 200, body: { ok: true } });
  await page.goto('/kontakt/');
  await fill(page, { email: 'kein-mail', message: 'kurz' });
  await submit(page);
  await expect(page.locator('#contact-email-error')).toHaveText(
    'Diese E-Mail-Adresse sieht nicht richtig aus. Prüf sie bitte noch einmal.',
  );
  await expect(page.locator('#contact-message-error')).toContainText('mindestens 10 Zeichen');
  await expect(page.getByLabel('Deine E-Mail-Adresse')).toBeFocused();
  await expect(page.getByLabel('Deine E-Mail-Adresse')).toHaveAttribute('aria-invalid', 'true');
  expect(seen).toHaveLength(0);
});

test('server field error is shown at the field', async ({ page }) => {
  await mockApi(page, { status: 400, body: { error: 'invalid_email' } });
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.locator('#contact-email-error')).toContainText('sieht nicht richtig aus');
  await expect(page.getByLabel('Deine Nachricht')).toHaveValue('Hallo, ich habe eine Frage zur App.');
});

test('429: says how long to wait, keeps the message', async ({ page }) => {
  await mockApi(page, { status: 429, body: { error: 'rate_limited', retryAfter: 720 }, headers: { 'retry-after': '720' } });
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.getByRole('alert')).toHaveText('Zu viele Nachrichten. Versuch es in 12 Minuten wieder.');
  await expect(page.getByLabel('Deine Nachricht')).toHaveValue('Hallo, ich habe eine Frage zur App.');
  await expect(page.getByRole('button', { name: 'Nachricht senden' })).toBeEnabled();
});

test('429 in english', async ({ page }) => {
  await mockApi(page, { status: 429, body: { error: 'rate_limited', retryAfter: 60 } });
  await page.goto('/en/contact/');
  await page.getByLabel('Your email address').fill('mia@example.org');
  await page.getByLabel('Your message').fill('Hello, I have a question.');
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect(page.getByRole('alert')).toHaveText('Too many messages. Try again in 1 minute.');
});

test('503 not_configured: points to the e-mail address', async ({ page }) => {
  await mockApi(page, { status: 503, body: { error: 'not_configured' } });
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.getByRole('alert')).toHaveText(
    'Das Formular ist gerade nicht erreichbar. Schreib uns an contact@mitlio.de.',
  );
});

test('502 send_failed: says it did not arrive and what to do', async ({ page }) => {
  await mockApi(page, { status: 502, body: { error: 'send_failed' } });
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.getByRole('alert')).toContainText('nicht angekommen');
  await expect(page.getByRole('alert')).toContainText('contact@mitlio.de');
});

test('network failure: says so and keeps the message', async ({ page }) => {
  await mockApi(page, 'abort');
  await page.goto('/kontakt/');
  await fill(page);
  await submit(page);
  await expect(page.getByRole('alert')).toContainText('Keine Verbindung zum Server');
  await expect(page.getByLabel('Deine Nachricht')).toHaveValue('Hallo, ich habe eine Frage zur App.');
});

test('honeypot is out of sight, out of the tab order and out of the accessibility tree', async ({ page }) => {
  await page.goto('/kontakt/');
  const hp = page.locator('input[name="website"]');
  await expect(hp).toHaveAttribute('tabindex', '-1');
  await expect(page.locator('.hp')).toHaveAttribute('aria-hidden', 'true');
  const box = await hp.boundingBox();
  expect(box!.x + box!.width).toBeLessThan(0);
  await expect(page.getByRole('textbox', { name: /website/i })).toHaveCount(0);
  // Keyboard: name -> email -> message -> submit, the honeypot is skipped.
  await page.getByLabel('Deine Nachricht').focus();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('button', { name: 'Nachricht senden' })).toBeFocused();
});

test('a filled honeypot is sent along (the server drops it)', async ({ page }) => {
  const seen = await mockApi(page, { status: 200, body: { ok: true } });
  await page.goto('/kontakt/');
  await fill(page);
  await page.locator('input[name="website"]').fill('http://spam.test', { force: true });
  await submit(page);
  await expect(page.getByText('Danke!')).toBeVisible();
  expect(seen[0]!.body['website']).toBe('http://spam.test');
});

test('keyboard accessible with labels, axe clean, privacy link, no cookies', async ({ page }) => {
  await page.goto('/kontakt/');
  for (const name of ['Name (optional)', 'Deine E-Mail-Adresse', 'Deine Nachricht']) {
    await expect(page.getByLabel(name)).toBeVisible();
  }
  await expect(page.getByLabel('Deine E-Mail-Adresse')).toHaveAttribute('type', 'email');
  await expect(page.getByLabel('Deine E-Mail-Adresse')).toHaveAttribute('autocomplete', 'email');
  await expect(page.locator('main a[href="/datenschutz/"]')).toBeVisible();
  await page.getByLabel('Name (optional)').focus();
  await page.keyboard.press('Tab');
  await expect(page.getByLabel('Deine E-Mail-Adresse')).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByLabel('Deine Nachricht')).toBeFocused();
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
  expect(await page.context().cookies()).toEqual([]);
});

test('the endpoint is the contact function next to the fuel one', async ({ page }) => {
  await page.goto('/kontakt/');
  await expect(page.locator('#contact-form')).toHaveAttribute('data-api', API);
});
