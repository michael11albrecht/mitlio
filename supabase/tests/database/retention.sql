-- Retention: every cleanup job is scheduled and deletes just past its threshold, keeps just inside it.
-- Thresholds are hard-coded here and must match supabase/retention.json (web/tests/retention.spec.ts
-- parses this file, the migrations and retention.json and fails on a mismatch).
-- retention: rate_limits_days=1
-- retention: fuel_cache_days=2
-- retention: fx_rates_days=60
-- retention: join_audit_days=90
-- retention: expired_invites_days_after_expiry=30
-- retention: inactive_account_months=13
-- retention: auth_audit_days=7
begin;
create extension if not exists pgtap with schema extensions;
select plan(37);

-- Scheduled ------------------------------------------------------------------------------------------
select ok(exists (select 1 from cron.job where jobname = 'fuel-prices-cleanup' and command like '%cleanup_fuel_tables%'),
  'fuel-prices-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'fx-rates-cleanup' and command like '%cleanup_fx_rates%'),
  'fx-rates-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'join-data-cleanup' and command like '%cleanup_join_data%'),
  'join-data-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'inactive-accounts-cleanup' and command like '%cleanup_inactive_accounts%'),
  'inactive-accounts-cleanup is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'auth-audit-cleanup' and command like '%cleanup_auth_audit_log%'),
  'auth-audit-cleanup is scheduled');

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

-- auth.audit_log_entries: 7 days (the empty-table no-op is covered in auth_audit_log.sql)
insert into auth.audit_log_entries (instance_id, id, payload, created_at) values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000a-000000000001',
    '{"actor_id":"00000000-0000-0000-0000-0000000000a1","action":"token_refreshed"}',
    now() - interval '7 days' - interval '1 hour'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000a-000000000002',
    '{"actor_id":"00000000-0000-0000-0000-0000000000a1","action":"token_refreshed"}',
    now() - interval '7 days' + interval '1 hour');

-- Inactive anonymous accounts (13 months) and groups without a linked account -------------------------
-- b1 anonymous, just past 13 months: deleted.        b2 anonymous, just inside: kept.
-- b3 anonymous, signed in 2 years ago but refreshed its token yesterday: kept.
-- b4 NOT anonymous (has an email), last sign-in 3 years ago: kept.
insert into auth.users (id, aud, role, email, is_anonymous, created_at, last_sign_in_at) values
  ('00000000-0000-0000-0000-0000000000b1', 'authenticated', 'authenticated', null, true,
    now() - interval '2 years', now() - interval '13 months' - interval '1 hour'),
  ('00000000-0000-0000-0000-0000000000b2', 'authenticated', 'authenticated', null, true,
    now() - interval '2 years', now() - interval '13 months' + interval '1 hour'),
  ('00000000-0000-0000-0000-0000000000b3', 'authenticated', 'authenticated', null, true,
    now() - interval '2 years', now() - interval '2 years'),
  ('00000000-0000-0000-0000-0000000000b4', 'authenticated', 'authenticated', 'plain@example.test', false,
    now() - interval '3 years', now() - interval '3 years');
insert into auth.refresh_tokens (token, user_id, revoked, created_at, updated_at) values
  ('retention-b3', '00000000-0000-0000-0000-0000000000b3', false, now() - interval '1 day', now() - interval '1 day');

-- Groups: go = only b1 (becomes an orphan once b1 is gone, with data in every dependent table),
-- gs = b1 (owner) and b2 (shared, must survive and hand ownership to b2), gk = b2, gp = b4,
-- gorph = old, nobody linked; gyoung = nobody linked but created now (bootstrap grace).
insert into public.groups (id, name, currency, created_by, created_at, updated_at) values
  ('00000000-0000-0000-0001-0000000000b1', 'go', 'EUR', '00000000-0000-0000-0000-0000000000b1', now() - interval '5 days', 'h1'),
  ('00000000-0000-0000-0001-0000000000b2', 'gs', 'EUR', '00000000-0000-0000-0000-0000000000b1', now() - interval '5 days', 'h1'),
  ('00000000-0000-0000-0001-0000000000b3', 'gk', 'EUR', '00000000-0000-0000-0000-0000000000b2', now() - interval '5 days', 'h1'),
  ('00000000-0000-0000-0001-0000000000b4', 'gp', 'EUR', '00000000-0000-0000-0000-0000000000b4', now() - interval '5 days', 'h1'),
  ('00000000-0000-0000-0001-0000000000b5', 'gorph', 'EUR', '00000000-0000-0000-0000-0000000000b1', now() - interval '2 days', 'h1'),
  ('00000000-0000-0000-0001-0000000000b6', 'gyoung', 'EUR', '00000000-0000-0000-0000-0000000000b1', now(), 'h1');
insert into public.members (id, group_id, updated_at, name, position, user_id) values
  ('00000000-0000-0000-0002-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1', 'Ann', 0, '00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0002-0000000000b2', '00000000-0000-0000-0001-0000000000b1', 'h1', 'Ben', 1, null),
  ('00000000-0000-0000-0002-0000000000b3', '00000000-0000-0000-0001-0000000000b2', 'h1', 'Ann', 0, '00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0002-0000000000b4', '00000000-0000-0000-0001-0000000000b2', 'h1', 'Cem', 1, '00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0002-0000000000b5', '00000000-0000-0000-0001-0000000000b3', 'h1', 'Cem', 0, '00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0002-0000000000b6', '00000000-0000-0000-0001-0000000000b4', 'h1', 'Dan', 0, '00000000-0000-0000-0000-0000000000b4'),
  ('00000000-0000-0000-0002-0000000000b7', '00000000-0000-0000-0001-0000000000b5', 'h1', 'Eve', 0, null);
-- Memberships: b1 first in gs, so b1 is its owner.
insert into public.group_memberships (group_id, user_id, member_id) values
  ('00000000-0000-0000-0001-0000000000b1', '00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0002-0000000000b1'),
  ('00000000-0000-0000-0001-0000000000b2', '00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0002-0000000000b3'),
  ('00000000-0000-0000-0001-0000000000b3', '00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0002-0000000000b5'),
  ('00000000-0000-0000-0001-0000000000b4', '00000000-0000-0000-0000-0000000000b4', '00000000-0000-0000-0002-0000000000b6');
insert into public.group_memberships (group_id, user_id, member_id) values
  ('00000000-0000-0000-0001-0000000000b2', '00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0002-0000000000b4');
-- Data in every dependent table of group go.
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents,
  date, type, split_mode) values
  ('00000000-0000-0000-0005-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1', 'x', 1000, 'EUR', 1000000, 1000,
   now(), 'regular', 'equal');
insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values
  ('00000000-0000-0000-0001-0000000000b1', '00000000-0000-0000-0005-0000000000b1', '00000000-0000-0000-0002-0000000000b1', 1000);
insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values
  ('00000000-0000-0000-0001-0000000000b1', '00000000-0000-0000-0005-0000000000b1', '00000000-0000-0000-0002-0000000000b1', 500, 1),
  ('00000000-0000-0000-0001-0000000000b1', '00000000-0000-0000-0005-0000000000b1', '00000000-0000-0000-0002-0000000000b2', 500, 1);
insert into public.expense_revisions (expense_id, group_id, revision, snapshot) values
  ('00000000-0000-0000-0005-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 1, '{}');
insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method) values
  ('00000000-0000-0000-0006-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1',
   '00000000-0000-0000-0002-0000000000b2', '00000000-0000-0000-0002-0000000000b1', 500, 'EUR', now(), 'cash');
insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km) values
  ('00000000-0000-0000-0007-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1', 'Car', 'petrol', 7000);
insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id) values
  ('00000000-0000-0000-0008-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1', 'Commute', 10000,
   '00000000-0000-0000-0007-0000000000b1');
insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli) values
  ('00000000-0000-0000-0009-0000000000b1', '00000000-0000-0000-0001-0000000000b1', 'h1', now(), 10000,
   '00000000-0000-0000-0007-0000000000b1', '00000000-0000-0000-0002-0000000000b1', 1700);
insert into public.group_invites (id, group_id, token_hash, created_by, expires_at) values
  ('00000000-0000-0000-0004-0000000000b1', '00000000-0000-0000-0001-0000000000b1', decode(repeat('dd', 32), 'hex'),
   '00000000-0000-0000-0000-0000000000a1', 'infinity');
insert into public.group_join_audit (group_id, user_id) values
  ('00000000-0000-0000-0001-0000000000b1', '00000000-0000-0000-0000-0000000000a1');

-- Run the jobs ----------------------------------------------------------------------------------------
select public.cleanup_fuel_tables();
select public.cleanup_fx_rates();
select public.cleanup_join_data();
select public.cleanup_auth_audit_log();
select public.cleanup_inactive_accounts();

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

select is((select count(*) from auth.audit_log_entries where id = '00000000-0000-0000-000a-000000000001'), 0::bigint,
  'auth.audit_log_entries: row just past 7 days is deleted');
select is((select count(*) from auth.audit_log_entries where id = '00000000-0000-0000-000a-000000000002'), 1::bigint,
  'auth.audit_log_entries: row just inside 7 days is kept');

-- Inactive anonymous accounts ---------------------------------------------------------------------------
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000b1'), 0::bigint,
  'anonymous account inactive just past 13 months is deleted');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000b2'), 1::bigint,
  'anonymous account inactive just inside 13 months is kept');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000b3'), 1::bigint,
  'anonymous account with a recent token refresh is kept');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000b4'), 1::bigint,
  'non-anonymous account is never deleted, however old');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000a1'), 1::bigint,
  'accounts without the anonymous flag from other fixtures are untouched');

-- Shared group: survives, ownership passes, the deleted account is unlinked from its member
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-0000000000b2'), 1::bigint,
  'shared group with a remaining account is kept');
select is((select role from public.group_memberships where group_id = '00000000-0000-0000-0001-0000000000b2'
   and user_id = '00000000-0000-0000-0000-0000000000b2'), 'owner',
  'ownership of the shared group passes to the remaining account');
select is((select user_id from public.members where id = '00000000-0000-0000-0002-0000000000b3'), null::uuid,
  'the deleted account is unlinked from its member entry, the entry stays');

-- Groups without a linked account
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-0000000000b1'), 0::bigint,
  'group left without any account is deleted');
select is(
  (select count(*) from (
     select 1 from public.members where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.expenses where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.expense_payers where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.expense_shares where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.expense_revisions where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.settlements where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.vehicles where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.ride_templates where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.rides where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.group_invites where group_id = '00000000-0000-0000-0001-0000000000b1'
     union all select 1 from public.group_join_audit where group_id = '00000000-0000-0000-0001-0000000000b1') x),
  0::bigint, 'every dependent row of the deleted group is gone');
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-0000000000b5'), 0::bigint,
  'old group that never had a linked account is deleted');
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-0000000000b6'), 1::bigint,
  'group younger than one day without a membership is kept (bootstrap grace)');
select is((select count(*) from public.groups where id in
   ('00000000-0000-0000-0001-0000000000b3', '00000000-0000-0000-0001-0000000000b4')), 2::bigint,
  'groups that still have a linked account (anonymous or not) are kept');
select is((select count(*) from public.members where group_id in
   ('00000000-0000-0000-0001-0000000000b3', '00000000-0000-0000-0001-0000000000b4')), 2::bigint,
  'members of kept groups are kept');

-- Client roles cannot call the job.
set local role authenticated;
select throws_ok($q$select public.cleanup_auth_audit_log()$q$, '42501', null,
  'authenticated cannot run the audit log purge');
select throws_ok($q$select public.cleanup_join_data()$q$, '42501', null, 'authenticated cannot run the join cleanup');
select throws_ok($q$select public.cleanup_inactive_accounts()$q$, '42501', null,
  'authenticated cannot run the inactive-accounts cleanup');
select throws_ok($q$select public.delete_account_data('00000000-0000-0000-0000-0000000000b4')$q$, '42501', null,
  'authenticated cannot delete another account through delete_account_data');

select * from finish();
rollback;
