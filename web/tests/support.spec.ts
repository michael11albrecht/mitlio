// The footer support link is off by default (P7-T09, ADR-28): no PayPal.Me handle in the build, no link.
import { expect, test } from '@playwright/test';

import { supportUrl } from '../src/lib/support';

test.describe('supportUrl', () => {
  test('a valid handle gives the PayPal.Me link', () => {
    expect(supportUrl('michaelalbrecht')).toBe('https://paypal.me/michaelalbrecht');
    expect(supportUrl('a')).toBe('https://paypal.me/a');
  });

  test('empty means off', () => {
    expect(supportUrl('')).toBeNull();
  });

  for (const bad of ['paypal.me/x', 'https://paypal.me/x', 'a b', 'x/y', 'x?y=1', 'a'.repeat(21), 'ä']) {
    test(`not a handle: ${JSON.stringify(bad)}`, () => {
      expect(supportUrl(bad)).toBeNull();
    });
  }
});

for (const path of ['/', '/en/', '/impressum/']) {
  test(`default build: no support link in the footer of ${path}`, async ({ page }) => {
    await page.goto(path);
    await expect(page.locator('.site-footer')).toBeVisible();
    await expect(page.locator('.site-footer a[href*="paypal"]')).toHaveCount(0);
  });
}
