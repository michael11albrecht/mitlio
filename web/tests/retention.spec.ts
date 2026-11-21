import { readFileSync } from 'node:fs';
import { expect, test } from '@playwright/test';

import retention from '../../supabase/retention.json' with { type: 'json' };

// supabase/retention.json is the single source of truth (docs/retention.md). The cleanup SQL and the pgTAP
// test hard-code the same numbers; this test fails when any of them drifts.
const read = (path: string): string => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8');
const interval = (n: number, unit = 'day'): string => `interval '${n} ${n === 1 ? unit : `${unit}s`}'`;

const jobs = [
  { key: 'rate_limits_days', file: 'supabase/migrations/0005_fuel_prices.sql', stmt: /from public\.rate_limits where updated_at < now\(\) - (interval '[^']+')/ },
  { key: 'fuel_cache_days', file: 'supabase/migrations/0005_fuel_prices.sql', stmt: /from public\.fuel_price_cache where scope <> 'national' and fetched_at < now\(\) - (interval '[^']+')/ },
  { key: 'fx_rates_days', file: 'supabase/migrations/0006_fx_rates.sql', stmt: /from public\.fx_rates where fetched_at < now\(\) - (interval '[^']+')/ },
  { key: 'join_audit_days', file: 'supabase/migrations/0013_retention.sql', stmt: /from public\.group_join_audit where joined_at < now\(\) - (interval '[^']+')/ },
  { key: 'expired_invites_days_after_expiry', file: 'supabase/migrations/0013_retention.sql', stmt: /from public\.group_invites where expires_at < now\(\) - (interval '[^']+')/ },
  { key: 'auth_audit_days', file: 'supabase/migrations/0017_auth_audit_purge.sql', stmt: /from auth\.audit_log_entries where created_at < now\(\) - (interval '[^']+')/ },
  { key: 'inactive_account_months', unit: 'month', file: 'supabase/migrations/0014_inactive_accounts_cleanup.sql', stmt: /< now\(\) - (interval '[^']+')\s*loop/ },
] as const;

test.describe('retention.json matches the cleanup jobs', () => {
  for (const job of jobs) {
    test(`${job.key} in ${job.file}`, () => {
      const match = job.stmt.exec(read(job.file));
      expect(match, `cleanup statement not found in ${job.file}`).not.toBeNull();
      expect(match?.[1]).toBe(interval(retention[job.key], 'unit' in job ? job.unit : 'day'));
    });
  }

  test('the pgTAP test uses the same thresholds', () => {
    const sql = read('supabase/tests/database/retention.sql');
    for (const job of jobs) {
      expect(sql, job.key).toContain(`-- retention: ${job.key}=${retention[job.key]}\n`);
      const iv = interval(retention[job.key], 'unit' in job ? job.unit : 'day');
      expect(sql, job.key).toContain(`${iv} - interval '1 hour'`);
      expect(sql, job.key).toContain(`${iv} + interval '1 hour'`);
    }
  });

  test('the edit history keeps the newest expense_revisions_per_expense revisions per expense', () => {
    const match = /r\.revision <= v_next - (\d+)/.exec(read('supabase/migrations/0007_expense_revisions.sql'));
    expect(match, 'prune statement not found in 0007').not.toBeNull();
    expect(Number(match?.[1])).toBe(retention.expense_revisions_per_expense);
  });

  test('the feedback cleanup default matches feedback_days', () => {
    const match = /DEFAULT_RETENTION_DAYS = (\d+)/.exec(read('supabase/functions/_shared/feedback.ts'));
    expect(Number(match?.[1])).toBe(retention.feedback_days);
  });

  test('every key is documented in docs/retention.md', () => {
    const doc = read('docs/retention.md');
    for (const key of Object.keys(retention)) expect(doc, key).toContain(key);
  });
});
