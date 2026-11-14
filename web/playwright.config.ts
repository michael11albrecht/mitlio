import { defineConfig, devices } from '@playwright/test';

// Runs against the built static site (`npm run build` first), served by `astro preview`.
// A second server (scripts/serve-fuel-fixture.mjs) serves a build with a fake FUEL_API_URL; only
// tests/fuel.spec.ts runs against it, with the API mocked via page.route.
const PORT = 4321;
const FUEL_PORT = 4322;

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env['CI'],
  retries: process.env['CI'] ? 1 : 0,
  reporter: process.env['CI'] ? [['list'], ['html', { open: 'never' }]] : 'list',
  outputDir: 'test-results',
  use: { trace: 'retain-on-failure' },
  projects: [
    {
      name: 'chromium',
      testIgnore: /fuel\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], baseURL: `http://127.0.0.1:${PORT}` },
    },
    {
      name: 'chromium-fuel',
      testMatch: /fuel\.spec\.ts/,
      use: { ...devices['Desktop Chrome'], baseURL: `http://127.0.0.1:${FUEL_PORT}` },
    },
  ],
  webServer: [
    {
      command: `npm run preview -- --ignore-lock --host 127.0.0.1 --port ${PORT}`,
      url: `http://127.0.0.1:${PORT}/`,
      reuseExistingServer: !process.env['CI'],
      timeout: 60_000,
    },
    {
      command: `node scripts/serve-fuel-fixture.mjs ${FUEL_PORT}`,
      url: `http://127.0.0.1:${FUEL_PORT}/`,
      reuseExistingServer: !process.env['CI'],
      timeout: 180_000,
    },
  ],
});
