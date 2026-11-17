-- Retention: every cleanup job is scheduled and deletes just past its threshold, keeps just inside it.
-- Thresholds are hard-coded here and must match supabase/retention.json (web/tests/retention.spec.ts
-- parses this file, the migrations and retention.json and fails on a mismatch).
-- retention: rate_limits_days=1
-- retention: fuel_cache_days=2
-- retention: fx_rates_days=60
-- retention: join_audit_days=90
-- retention: expired_invites_days_after_expiry=30
begin;
create extension if not exists pgtap with schema extensions;
select plan(16);

-- Scheduled ------------------------------------------------------------------------------------------
select ok(exists (select 1 from cron.job where jobname = 'fuel-prices-cleanup' and command like '%cleanup_fuel_tables%'),
  'fuel-prices-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'fx-rates-cleanup' and command like '%cleanup_fx_rates%'),
  'fx-rates-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'join-data-cleanup' and command like '%cleanup_join_data%'),
  'join-data-cleanup is scheduled');

-- Fixtures --------------------------------------------------------------------------------------------
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'authenticated', 'authenticated', 'retention@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-0000000000a1', 'Retention', 'EUR', '00000000-0000-0000-0000-0000000000a1', 'h1');

-- rate_limits: 1 day
insert into public.rate_limits (key_hash, tokens, updated_at) values
  ('retention-rl-old-0000', 1, now() - interval '1 day' - interval '1 hour'),
  ('retention-rl-new-0000', 1, now() - interval '1 day' + interval '1 hour');

-- fuel_price_cache: 2 days for non-national scopes; national rows are kept
insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations, fetched_at) values
  ('e5', 'plz', 'old', 1700, 1, now() - interval '2 days' - interval '1 hour'),
  ('e5', 'plz', 'new', 1700, 1, now() - interval '2 days' + interval '1 hour'),
  ('e5', 'national', 'de', 1700, 1, now() - interval '30 days');

-- fx_rates: 60 days
insert into public.fx_rates (base, quote, date, rate_ppm, source_date, fetched_at) values
  ('USD', 'EUR', '2025-01-01', 920000, '2025-01-01', now() - interval '60 days' - interval '1 hour'),
  ('CHF', 'EUR', '2025-01-02', 1060000, '2025-01-02', now() - interval '60 days' + interval '1 hour');

-- group_join_audit: 90 days
insert into public.group_join_audit (id, group_id, user_id, joined_at) values
  ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0001-0000000000a1', '00000000-0000-0000-0000-0000000000a1',
    now() - interval '90 days' - interval '1 hour'),
  ('00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0001-0000000000a1', '00000000-0000-0000-0000-0000000000a1',
    now() - interval '90 days' + interval '1 hour');

-- group_invites: 30 days after expiry
insert into public.group_invites (id, group_id, token_hash, created_by, created_at, expires_at) values
  ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-0000000000a1', decode(repeat('aa', 32), 'hex'),
    '00000000-0000-0000-0000-0000000000a1', now() - interval '60 days', now() - interval '30 days' - interval '1 hour'),
  ('00000000-0000-0000-0004-000000000002', '00000000-0000-0000-0001-0000000000a1', decode(repeat('bb', 32), 'hex'),
    '00000000-0000-0000-0000-0000000000a1', now() - interval '60 days', now() - interval '30 days' + interval '1 hour'),
  ('00000000-0000-0000-0004-000000000003', '00000000-0000-0000-0001-0000000000a1', decode(repeat('cc', 32), 'hex'),
    '00000000-0000-0000-0000-0000000000a1', now(), now() + interval '7 days');

-- Run the jobs ----------------------------------------------------------------------------------------
select public.cleanup_fuel_tables();
select public.cleanup_fx_rates();
select public.cleanup_join_data();

select is((select count(*) from public.rate_limits where key_hash = 'retention-rl-old-0000'), 0::bigint,
  'rate_limits: entry just past 1 day is deleted');
select is((select count(*) from public.rate_limits where key_hash = 'retention-rl-new-0000'), 1::bigint,
  'rate_limits: entry just inside 1 day is kept');

select is((select count(*) from public.fuel_price_cache where scope_key = 'old'), 0::bigint,
  'fuel_price_cache: row just past 2 days is deleted');
select is((select count(*) from public.fuel_price_cache where scope_key = 'new'), 1::bigint,
  'fuel_price_cache: row just inside 2 days is kept');
select is((select count(*) from public.fuel_price_cache where scope = 'national'), 1::bigint,
  'fuel_price_cache: national row is kept regardless of age');

select is((select count(*) from public.fx_rates where base = 'USD'), 0::bigint,
  'fx_rates: row just past 60 days is deleted');
select is((select count(*) from public.fx_rates where base = 'CHF'), 1::bigint,
  'fx_rates: row just inside 60 days is kept');

select is((select count(*) from public.group_join_audit where id = '00000000-0000-0000-0003-000000000001'), 0::bigint,
  'group_join_audit: row just past 90 days is deleted');
select is((select count(*) from public.group_join_audit where id = '00000000-0000-0000-0003-000000000002'), 1::bigint,
  'group_join_audit: row just inside 90 days is kept');

select is((select count(*) from public.group_invites where id = '00000000-0000-0000-0004-000000000001'), 0::bigint,
  'group_invites: invite expired more than 30 days ago is deleted');
select is((select count(*) from public.group_invites where id = '00000000-0000-0000-0004-000000000002'), 1::bigint,
  'group_invites: invite expired less than 30 days ago is kept');
select is((select count(*) from public.group_invites where id = '00000000-0000-0000-0004-000000000003'), 1::bigint,
  'group_invites: valid invite is kept');

-- Client roles cannot call the job.
set local role authenticated;
select throws_ok($q$select public.cleanup_join_data()$q$, '42501', null, 'authenticated cannot run the join cleanup');

select * from finish();
rollback;
