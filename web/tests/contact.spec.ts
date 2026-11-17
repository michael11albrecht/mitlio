// Contact page without a configured API (the default build): the e-mail address replaces the form.
import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

import { failureFromResponse, networkFailure, validateFields } from '../src/lib/contact';

const pages = [
  { path: '/kontakt/', lang: 'de-DE', h1: 'Kontakt', privacy: '/datenschutz/', other: '/en/contact/' },
  { path: '/en/contact/', lang: 'en', h1: 'Contact', privacy: '/en/privacy/', other: '/kontakt/' },
] as const;

for (const p of pages) {
  test(`${p.path}: no API shows the e-mail fallback, no form, no request`, async ({ page }) => {
    const requests: string[] = [];
    page.on('request', (r) => requests.push(new URL(r.url()).origin));
    await page.goto(p.path);
    await expect(page.locator('html')).toHaveAttribute('lang', p.lang);
    await expect(page.getByRole('heading', { level: 1, name: p.h1 })).toBeVisible();
    await expect(page.locator('#contact-form')).toHaveCount(0);
    await expect(page.locator('#contact-fallback')).toContainText('contact@mitlio.de');
    await expect(page.locator('main a[href="mailto:contact@mitlio.de"]')).toBeVisible();
    await expect(page.locator(`main a[href="${p.privacy}"]`)).toBeVisible();
    await expect(page.locator('link[rel="alternate"][hreflang]').first()).toBeAttached();
    await expect(page.locator(`a.lang`)).toHaveAttribute('href', p.other);
    expect(new Set(requests)).toEqual(new Set(['http://127.0.0.1:4321']));
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test(`${p.path}: is linked from the footer, noindex`, async ({ page }) => {
    await page.goto(p.path);
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', 'noindex');
    await page.goto(p.path === '/kontakt/' ? '/' : '/en/');
    await expect(page.locator(`footer a[href="${p.path}"]`)).toBeVisible();
  });
}

test('validation mirrors the server rules', () => {
  const ok = { name: '', email: 'a@b.de', message: 'x'.repeat(10) };
  expect(validateFields(ok)).toEqual({});
  expect(validateFields({ ...ok, email: 'nope' }).email).toBe('errorEmail');
  expect(validateFields({ ...ok, message: 'x'.repeat(9) }).message).toBe('errorMessageShort');
  expect(validateFields({ ...ok, message: 'x'.repeat(5001) }).message).toBe('errorMessageLong');
  expect(validateFields({ ...ok, name: 'n'.repeat(101) }).name).toBe('errorNameLong');
});

test('API errors map to what the user sees', () => {
  expect(failureFromResponse(429, { error: 'rate_limited', retryAfter: 720 }, null)).toEqual({ kind: 'rate_limited', minutes: 12 });
  expect(failureFromResponse(429, null, '61')).toEqual({ kind: 'rate_limited', minutes: 2 });
  expect(failureFromResponse(429, null, null)).toEqual({ kind: 'rate_limited', minutes: 60 });
  expect(failureFromResponse(400, { error: 'invalid_email' }, null)).toEqual({ kind: 'field', field: 'email', key: 'errorEmail' });
  expect(failureFromResponse(503, { error: 'not_configured' }, null)).toEqual({ kind: 'general', key: 'errorNotConfigured' });
  expect(failureFromResponse(502, { error: 'send_failed' }, null)).toEqual({ kind: 'general', key: 'errorSendFailed' });
  expect(failureFromResponse(429, { error: 'busy', retryAfter: 1728 }, '1728')).toEqual({ kind: 'general', key: 'errorBusy' });
  expect(networkFailure(false)).toEqual({ kind: 'general', key: 'errorNetwork' });
  expect(networkFailure(true)).toEqual({ kind: 'general', key: 'errorNotConfigured' });
  expect(failureFromResponse(500, 'junk', null)).toEqual({ kind: 'general', key: 'errorSendFailed' });
});
