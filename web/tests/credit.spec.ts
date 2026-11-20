import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const GITHUB = 'https://github.com/michael11albrecht';

for (const [path, text] of [
  ['/', 'Mit gemacht von Michael Albrecht'],
  ['/en/', 'Made with by Michael Albrecht'],
  ['/impressum/', 'Mit gemacht von Michael Albrecht'],
  ['/en/privacy/', 'Made with by Michael Albrecht'],
] as const) {
  test(`footer credit on ${path}`, async ({ page }) => {
    await page.goto(path);
    const credit = page.locator('.site-footer .credit');
    await expect(credit).toBeVisible();
    // The decorative heart is hidden from assistive tech, so the accessible text has none.
    await expect(credit.locator('[aria-hidden="true"]')).toHaveText('♥');
    const link = credit.getByRole('link', { name: 'Michael Albrecht' });
    await expect(link).toHaveAttribute('href', GITHUB);
    await expect(link).toHaveAttribute('target', '_blank');
    await expect(link).toHaveAttribute('rel', /noopener/);
    const spoken = await credit.evaluate((el) => {
      const clone = el.cloneNode(true) as HTMLElement;
      clone.querySelectorAll('[aria-hidden="true"]').forEach((n) => n.remove());
      return (clone.textContent ?? '').replace(/\s+/g, ' ').trim();
    });
    expect(spoken).toBe(text);
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });
}
