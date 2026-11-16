// Runs after `astro build` (npm postbuild): writes firebase.json (CSP depends on FUEL_API_URL) and the
// /.well-known app-link files into dist/. firebase.json is committed for the default env; do not hand-edit it.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { ANDROID_SHA256_CERT_FINGERPRINTS, APPLE_TEAM_ID, FUEL_API_URL } from '../site.config.mjs';
import { firebaseConfig, wellKnownFiles } from './hosting.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, process.env['ASTRO_OUT_DIR'] ?? 'dist');

writeFileSync(join(root, 'firebase.json'), `${JSON.stringify(firebaseConfig(FUEL_API_URL), null, 2)}\n`);

const files = wellKnownFiles(APPLE_TEAM_ID, ANDROID_SHA256_CERT_FINGERPRINTS);
const dir = join(outDir, '.well-known');
if (Object.keys(files).length > 0) mkdirSync(dir, { recursive: true });
for (const [name, content] of Object.entries(files)) writeFileSync(join(dir, name), `${JSON.stringify(content)}\n`);
console.log(`hosting: firebase.json, .well-known: ${Object.keys(files).join(', ') || 'none (ids not configured)'}`);
