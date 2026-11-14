// Makes build/domain_web/mitlio_domain.js (PW-T01) available to the site as
// public/mitlio_domain.js. Rebuilds it via tool/build_domain_web.sh when dart is
// available, otherwise reuses an existing build output. The calculator island
// (PW-T03) is the first consumer; until then a missing file is only a warning.
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const built = join(root, 'build', 'domain_web', 'mitlio_domain.js');
const target = join(root, 'web', 'public', 'mitlio_domain.js');

const dartOnPath = spawnSync('dart', ['--version'], { stdio: 'ignore' }).status === 0;
const dartInSdk = existsSync(join(homedir(), 'sdk', 'flutter', 'bin', 'dart'));

if (dartOnPath || dartInSdk) {
  execFileSync(join(root, 'tool', 'build_domain_web.sh'), { stdio: 'inherit' });
} else if (existsSync(built)) {
  console.log('dart not found, reusing existing', built);
} else {
  console.warn('dart not found and no existing domain_web build: skipping mitlio_domain.js');
  process.exit(0);
}

mkdirSync(dirname(target), { recursive: true });
copyFileSync(built, target);
console.log('copied mitlio_domain.js to web/public/');
