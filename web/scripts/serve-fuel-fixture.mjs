// Test fixture for the fuel price chips: builds a second copy of the site with a fake FUEL_API_URL into
// dist-fuel/ and serves it on the given port. The real dist/ (built without a URL) stays the "no API" case.
// Playwright mocks the fake origin with page.route; nothing here talks to a real server.
import { spawnSync, spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const port = process.argv[2] ?? '4322';
const cwd = fileURLToPath(new URL('..', import.meta.url));
const env = {
  ...process.env,
  ASTRO_OUT_DIR: './dist-fuel',
  FUEL_API_URL: 'https://fuel.mitlio.test/functions/v1/fuel-prices',
  FUEL_API_ANON_KEY: 'test-anon-key',
  ASTRO_TELEMETRY_DISABLED: '1',
};

const astro = ['node_modules/astro/bin/astro.mjs'];
const build = spawnSync(process.execPath, [...astro, 'build'], { cwd, env, stdio: 'inherit' });
if (build.status !== 0) process.exit(build.status ?? 1);

const preview = spawn(
  process.execPath,
  [...astro, 'preview', '--ignore-lock', '--host', '127.0.0.1', '--port', port],
  { cwd, env, stdio: 'inherit' },
);
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => preview.kill(sig));
preview.on('exit', (code) => process.exit(code ?? 0));
