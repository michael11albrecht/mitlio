import { readFileSync } from 'node:fs';
import { expect, test } from '@playwright/test';

import retention from '../../supabase/retention.json';

// supabase/retention.json is the single source of truth (docs/retention.md). The cleanup SQL and the pgTAP
// test hard-code the same numbers; this test fails when any of them drifts.
const read = (path: string): string => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8');
const interval = (n: number): string => `interval '${n} ${n === 1 ? 'day' : 'days'}'`;

const jobs = [
  { key: 'rate_limits_days', file: 'supabase/migrations/0005_fuel_prices.sql', stmt: /from public\.rate_limits where updated_at < now\(\) - (interval '[^']+')/ },
  { key: 'fuel_cache_days', file: 'supabase/migrations/0005_fuel_prices.sql', stmt: /from public\.fuel_price_cache where scope <> 'national' and fetched_at < now\(\) - (interval '[^']+')/ },
  { key: 'fx_rates_days', file: 'supabase/migrations/0006_fx_rates.sql', stmt: /from public\.fx_rates where fetched_at < now\(\) - (interval '[^']+')/ },
  { key: 'join_audit_days', file: 'supabase/migrations/0013_retention.sql', stmt: /from public\.group_join_audit where joined_at < now\(\) - (interval '[^']+')/ },
  { key: 'expired_invites_days_after_expiry', file: 'supabase/migrations/0013_retention.sql', stmt: /from public\.group_invites where expires_at < now\(\) - (interval '[^']+')/ },
] as const;

test.describe('retention.json matches the cleanup jobs', () => {
  for (const job of jobs) {
    test(`${job.key} in ${job.file}`, () => {
      const match = job.stmt.exec(read(job.file));
      expect(match, `cleanup statement not found in ${job.file}`).not.toBeNull();
      expect(match?.[1]).toBe(interval(retention[job.key]));
    });
  }

  test('the pgTAP test uses the same thresholds', () => {
    const sql = read('supabase/tests/database/retention.sql');
    for (const job of jobs) {
      expect(sql, job.key).toContain(`-- retention: ${job.key}=${retention[job.key]}\n`);
      expect(sql, job.key).toContain(`${interval(retention[job.key])} - interval '1 hour'`);
      expect(sql, job.key).toContain(`${interval(retention[job.key])} + interval '1 hour'`);
    }
  });

  test('every key is documented in docs/retention.md', () => {
    const doc = read('docs/retention.md');
    for (const key of Object.keys(retention)) expect(doc, key).toContain(key);
  });
});
