// Parity: the compiled JS must reproduce every shared fixture exactly.
// Run via `make domain-web-test` (builds build/domain_web/mitlio_domain.js first).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const bundle = readFileSync(resolve(root, 'build/domain_web/mitlio_domain.js'), 'utf8');
const fixtures = JSON.parse(readFileSync(resolve(root, 'tool/fixtures/trip_web.json'), 'utf8'));

// dart2js output runs in plain Node and installs globalThis.mitlio.
vm.runInThisContext(bundle);
const { mitlio } = globalThis;

test('exposes version and calculateTrip on globalThis.mitlio', () => {
  assert.equal(typeof mitlio.calculateTrip, 'function');
  assert.equal(mitlio.version, 1);
});

for (const c of fixtures) {
  test(c.name, () => {
    assert.deepEqual(mitlio.calculateTrip(c.input), c.expected);
  });
}

test('NaN and Infinity are rejected with a structured error', () => {
  const base = fixtures[0].input;
  const nan = { ...base, distanceKm: NaN };
  const inf = { ...base, pricePerUnit: Infinity };
  assert.deepEqual(mitlio.calculateTrip(nan), {
    ok: false,
    error: 'InvalidNumber',
    field: 'distanceKm',
  });
  assert.deepEqual(mitlio.calculateTrip(inf), {
    ok: false,
    error: 'InvalidNumber',
    field: 'pricePerUnit',
  });
});

test('non-object input is rejected, not thrown', () => {
  const r = mitlio.calculateTrip(null);
  assert.equal(r.ok, false);
});
