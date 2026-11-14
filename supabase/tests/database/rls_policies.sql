-- RLS matrix for every table in public (P6-T03). Generated shape, hand-reviewable:
-- per table: member allowed, non-member denied, anon denied, hard delete denied.
-- Actors: alice (member of group A), bob (member of group B only), mallory (member of nothing).
-- Keep the table list in sync with rls_coverage.sql (that test fails on any untested table).
begin;
create extension if not exists pgtap with schema extensions;
select plan(140);

create schema tests;
grant usage on schema tests to anon, authenticated;

create function tests.as_user(uid uuid) returns void
language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  set local role authenticated;
end;
$$;

create function tests.as_anon() returns void
language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;
end;
$$;

create function tests.rows_affected(stmt text) returns bigint
language plpgsql as $$
declare n bigint;
begin
  execute stmt;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Fixtures (as postgres, bypasses RLS).
reset role;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'mallory@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1'),
  ('00000000-0000-0000-0001-000000000002', 'Group B', 'EUR', '00000000-0000-0000-0000-000000000002', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001'), ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000002');
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm0', 0);
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 1);
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 2);
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0001-000000000002', 'h1', 'm0', 0);
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-00000000000c', '00000000-0000-0000-0001-000000000002', 'h1', 'm1', 1);
insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-00000000000d', '00000000-0000-0000-0001-000000000002', 'h1', 'm2', 2);
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode)
  values ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'e', 1000, 'EUR', 1000000, 1000, now(), 'regular', 'equal');
insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000001', 1000);
insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000001', 500, 1), ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000002', 500, 1);
insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method)
  values ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0002-000000000002', 500, 'EUR', now(), 'cash');
insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km)
  values ('00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'car', 'petrol', 6000);
insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id)
  values ('00000000-0000-0000-0006-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'work', 10000, '00000000-0000-0000-0005-000000000001');
insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli)
  values ('00000000-0000-0000-0007-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', now(), 10000, '00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0002-000000000001', 1700);
insert into public.group_invites (group_id, token_hash, created_by, expires_at)
  values ('00000000-0000-0000-0001-000000000001', sha256('A'::bytea), '00000000-0000-0000-0000-000000000001', now() + interval '7 days');
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode)
  values ('00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', 'e', 1000, 'EUR', 1000000, 1000, now(), 'regular', 'equal');
insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-00000000000b', 1000);
insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-00000000000b', 500, 1), ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-00000000000c', 500, 1);
insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method)
  values ('00000000-0000-0000-0004-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', '00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0002-00000000000c', 500, 'EUR', now(), 'cash');
insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km)
  values ('00000000-0000-0000-0005-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', 'car', 'petrol', 6000);
insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id)
  values ('00000000-0000-0000-0006-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', 'work', 10000, '00000000-0000-0000-0005-000000000002');
insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli)
  values ('00000000-0000-0000-0007-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', now(), 10000, '00000000-0000-0000-0005-000000000002', '00000000-0000-0000-0002-00000000000b', 1700);
insert into public.group_invites (group_id, token_hash, created_by, expires_at)
  values ('00000000-0000-0000-0001-000000000002', sha256('B'::bytea), '00000000-0000-0000-0000-000000000002', now() + interval '7 days');

-- ===== groups =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'groups: member sees own group rows');
select is((select count(*) from public.groups where id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'groups: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.groups), 0::bigint, 'groups: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.groups$q$, '42501'::char(5), null, 'groups: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.groups (id, name, currency, created_by, updated_at) values ('00000000-0000-0000-0001-000000000063', 'n', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1')$q$, '42501'::char(5), null, 'groups: cannot create a group on behalf of someone else');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.groups (id, name, currency, created_by, updated_at) values ('00000000-0000-0000-0001-000000000063', 'n', 'EUR', '00000000-0000-0000-0000-000000000002', 'h1')$q$, '42501'::char(5), null, 'groups: member cannot create a group owned by another user');
select tests.as_anon();
select throws_ok($q$insert into public.groups (id, name, currency, created_by, updated_at) values ('00000000-0000-0000-0001-000000000063', 'n', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1')$q$, '42501'::char(5), null, 'groups: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.groups (id, name, currency, created_by, updated_at) values ('00000000-0000-0000-0001-000000000063', 'n', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1')$q$, 'groups: user can create own group');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.groups set name = 'x', updated_at = 'h2' where id = '00000000-0000-0000-0001-000000000001' returning 1$q$), 1::bigint, 'groups: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.groups set name = 'x', updated_at = 'h2' where id = '00000000-0000-0000-0001-000000000001' returning 1$q$), 0::bigint, 'groups: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.groups set name = 'x', updated_at = 'h2' where id = '00000000-0000-0000-0001-000000000001' returning 1$q$, '42501'::char(5), null, 'groups: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.groups where id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'groups: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.groups where id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'groups: anon hard delete denied');

-- ===== members =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.members where group_id = '00000000-0000-0000-0001-000000000001'), 3::bigint, 'members: member sees own group rows');
select is((select count(*) from public.members where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'members: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.members), 0::bigint, 'members: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.members$q$, '42501'::char(5), null, 'members: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'n', 9)$q$, '42501'::char(5), null, 'members: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', 'n', 9)$q$, '42501'::char(5), null, 'members: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'n', 9)$q$, '42501'::char(5), null, 'members: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.members (id, group_id, updated_at, name, position) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'n', 9)$q$, 'members: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.members set updated_at = 'h2' where id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 1::bigint, 'members: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.members set updated_at = 'h2' where id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 0::bigint, 'members: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.members set updated_at = 'h2' where id = '00000000-0000-0000-0002-000000000001' returning 1$q$, '42501'::char(5), null, 'members: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.members where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'members: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.members where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'members: anon hard delete denied');

-- ===== expenses =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.expenses where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'expenses: member sees own group rows');
select is((select count(*) from public.expenses where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'expenses: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.expenses), 0::bigint, 'expenses: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.expenses$q$, '42501'::char(5), null, 'expenses: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'e', 100, 'EUR', 1000000, 100, now(), 'regular', 'equal')$q$, '42501'::char(5), null, 'expenses: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', 'e', 100, 'EUR', 1000000, 100, now(), 'regular', 'equal')$q$, '42501'::char(5), null, 'expenses: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'e', 100, 'EUR', 1000000, 100, now(), 'regular', 'equal')$q$, '42501'::char(5), null, 'expenses: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'e', 100, 'EUR', 1000000, 100, now(), 'regular', 'equal')$q$, 'expenses: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.expenses set updated_at = 'h2' where id = '00000000-0000-0000-0003-000000000001' returning 1$q$), 1::bigint, 'expenses: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.expenses set updated_at = 'h2' where id = '00000000-0000-0000-0003-000000000001' returning 1$q$), 0::bigint, 'expenses: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.expenses set updated_at = 'h2' where id = '00000000-0000-0000-0003-000000000001' returning 1$q$, '42501'::char(5), null, 'expenses: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.expenses where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expenses: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.expenses where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expenses: anon hard delete denied');

-- ===== expense_payers =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.expense_payers where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'expense_payers: member sees own group rows');
select is((select count(*) from public.expense_payers where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'expense_payers: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.expense_payers), 0::bigint, 'expense_payers: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.expense_payers$q$, '42501'::char(5), null, 'expense_payers: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000002', 100)$q$, '42501'::char(5), null, 'expense_payers: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-00000000000c', 100)$q$, '42501'::char(5), null, 'expense_payers: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000002', 100)$q$, '42501'::char(5), null, 'expense_payers: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000002', 100)$q$, 'expense_payers: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.expense_payers set paid_cents = 999 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 1::bigint, 'expense_payers: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.expense_payers set paid_cents = 999 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 0::bigint, 'expense_payers: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.expense_payers set paid_cents = 999 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$, '42501'::char(5), null, 'expense_payers: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.expense_payers where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expense_payers: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.expense_payers where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expense_payers: anon hard delete denied');

-- ===== expense_shares =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.expense_shares where group_id = '00000000-0000-0000-0001-000000000001'), 2::bigint, 'expense_shares: member sees own group rows');
select is((select count(*) from public.expense_shares where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'expense_shares: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.expense_shares), 0::bigint, 'expense_shares: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.expense_shares$q$, '42501'::char(5), null, 'expense_shares: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000003', 0, 0)$q$, '42501'::char(5), null, 'expense_shares: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0002-00000000000d', 0, 0)$q$, '42501'::char(5), null, 'expense_shares: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000003', 0, 0)$q$, '42501'::char(5), null, 'expense_shares: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000003', 0, 0)$q$, 'expense_shares: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.expense_shares set weight = 2 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 1::bigint, 'expense_shares: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.expense_shares set weight = 2 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$), 0::bigint, 'expense_shares: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.expense_shares set weight = 2 where expense_id = '00000000-0000-0000-0003-000000000001' and member_id = '00000000-0000-0000-0002-000000000001' returning 1$q$, '42501'::char(5), null, 'expense_shares: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.expense_shares where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expense_shares: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.expense_shares where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'expense_shares: anon hard delete denied');

-- ===== settlements =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.settlements where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'settlements: member sees own group rows');
select is((select count(*) from public.settlements where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'settlements: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.settlements), 0::bigint, 'settlements: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.settlements$q$, '42501'::char(5), null, 'settlements: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0002-000000000002', 100, 'EUR', now(), 'cash')$q$, '42501'::char(5), null, 'settlements: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', '00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0002-00000000000c', 100, 'EUR', now(), 'cash')$q$, '42501'::char(5), null, 'settlements: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0002-000000000002', 100, 'EUR', now(), 'cash')$q$, '42501'::char(5), null, 'settlements: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0002-000000000002', 100, 'EUR', now(), 'cash')$q$, 'settlements: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.settlements set updated_at = 'h2' where id = '00000000-0000-0000-0004-000000000001' returning 1$q$), 1::bigint, 'settlements: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.settlements set updated_at = 'h2' where id = '00000000-0000-0000-0004-000000000001' returning 1$q$), 0::bigint, 'settlements: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.settlements set updated_at = 'h2' where id = '00000000-0000-0000-0004-000000000001' returning 1$q$, '42501'::char(5), null, 'settlements: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.settlements where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'settlements: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.settlements where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'settlements: anon hard delete denied');

-- ===== vehicles =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.vehicles where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'vehicles: member sees own group rows');
select is((select count(*) from public.vehicles where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'vehicles: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.vehicles), 0::bigint, 'vehicles: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.vehicles$q$, '42501'::char(5), null, 'vehicles: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'v', 'diesel', 5000)$q$, '42501'::char(5), null, 'vehicles: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', 'v', 'diesel', 5000)$q$, '42501'::char(5), null, 'vehicles: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'v', 'diesel', 5000)$q$, '42501'::char(5), null, 'vehicles: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per100km) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 'v', 'diesel', 5000)$q$, 'vehicles: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.vehicles set updated_at = 'h2' where id = '00000000-0000-0000-0005-000000000001' returning 1$q$), 1::bigint, 'vehicles: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.vehicles set updated_at = 'h2' where id = '00000000-0000-0000-0005-000000000001' returning 1$q$), 0::bigint, 'vehicles: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.vehicles set updated_at = 'h2' where id = '00000000-0000-0000-0005-000000000001' returning 1$q$, '42501'::char(5), null, 'vehicles: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.vehicles where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'vehicles: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.vehicles where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'vehicles: anon hard delete denied');

-- ===== ride_templates =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.ride_templates where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'ride_templates: member sees own group rows');
select is((select count(*) from public.ride_templates where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'ride_templates: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.ride_templates), 0::bigint, 'ride_templates: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.ride_templates$q$, '42501'::char(5), null, 'ride_templates: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 't', 1, '00000000-0000-0000-0005-000000000001')$q$, '42501'::char(5), null, 'ride_templates: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', 't', 1, '00000000-0000-0000-0005-000000000002')$q$, '42501'::char(5), null, 'ride_templates: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 't', 1, '00000000-0000-0000-0005-000000000001')$q$, '42501'::char(5), null, 'ride_templates: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', 't', 1, '00000000-0000-0000-0005-000000000001')$q$, 'ride_templates: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.ride_templates set updated_at = 'h2' where id = '00000000-0000-0000-0006-000000000001' returning 1$q$), 1::bigint, 'ride_templates: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.ride_templates set updated_at = 'h2' where id = '00000000-0000-0000-0006-000000000001' returning 1$q$), 0::bigint, 'ride_templates: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.ride_templates set updated_at = 'h2' where id = '00000000-0000-0000-0006-000000000001' returning 1$q$, '42501'::char(5), null, 'ride_templates: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.ride_templates where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'ride_templates: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.ride_templates where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'ride_templates: anon hard delete denied');

-- ===== rides =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.rides where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'rides: member sees own group rows');
select is((select count(*) from public.rides where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'rides: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.rides), 0::bigint, 'rides: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.rides$q$, '42501'::char(5), null, 'rides: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', now(), 1, '00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0002-000000000001', 1)$q$, '42501'::char(5), null, 'rides: non-member insert into foreign group denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000002', 'h1', now(), 1, '00000000-0000-0000-0005-000000000002', '00000000-0000-0000-0002-00000000000b', 1)$q$, '42501'::char(5), null, 'rides: member insert into other group denied');
select tests.as_anon();
select throws_ok($q$insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', now(), 1, '00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0002-000000000001', 1)$q$, '42501'::char(5), null, 'rides: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$insert into public.rides (id, group_id, updated_at, date, distance_meters, vehicle_id, driver_id, price_per_unit_milli) values ('00000000-0000-0000-0002-000000000063', '00000000-0000-0000-0001-000000000001', 'h1', now(), 1, '00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0002-000000000001', 1)$q$, 'rides: member insert into own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(tests.rows_affected($q$update public.rides set updated_at = 'h2' where id = '00000000-0000-0000-0007-000000000001' returning 1$q$), 1::bigint, 'rides: member update in own group allowed');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(tests.rows_affected($q$update public.rides set updated_at = 'h2' where id = '00000000-0000-0000-0007-000000000001' returning 1$q$), 0::bigint, 'rides: non-member update affects no rows');
select tests.as_anon();
select throws_ok($q$update public.rides set updated_at = 'h2' where id = '00000000-0000-0000-0007-000000000001' returning 1$q$, '42501'::char(5), null, 'rides: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.rides where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'rides: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.rides where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'rides: anon hard delete denied');

-- ===== group_memberships =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.group_memberships where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'group_memberships: member sees own group rows');
select is((select count(*) from public.group_memberships where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'group_memberships: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.group_memberships), 0::bigint, 'group_memberships: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.group_memberships$q$, '42501'::char(5), null, 'group_memberships: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$insert into public.group_memberships (group_id, user_id) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002')$q$, '42501'::char(5), null, 'group_memberships: non-member cannot add self to foreign group');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.group_memberships (group_id, user_id) values ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000001')$q$, '42501'::char(5), null, 'group_memberships: member cannot add self to other group');
select throws_ok($q$insert into public.group_memberships (group_id, user_id) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001')$q$, '42501'::char(5), null, 'group_memberships: member cannot bootstrap an already populated group');
select tests.as_anon();
select throws_ok($q$insert into public.group_memberships (group_id, user_id) values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001')$q$, '42501'::char(5), null, 'group_memberships: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$update public.group_memberships set created_at = now() where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_memberships: member update denied (RPC only)');
select tests.as_anon();
select throws_ok($q$update public.group_memberships set created_at = now() where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_memberships: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.group_memberships where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_memberships: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.group_memberships where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_memberships: anon hard delete denied');

-- ===== group_invites =====
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.group_invites where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint, 'group_invites: member sees own group rows');
select is((select count(*) from public.group_invites where group_id = '00000000-0000-0000-0001-000000000002'), 0::bigint, 'group_invites: member does not see other group rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.group_invites), 0::bigint, 'group_invites: non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.group_invites$q$, '42501'::char(5), null, 'group_invites: anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$insert into public.group_invites (group_id, token_hash, created_by, expires_at) values ('00000000-0000-0000-0001-000000000001', sha256('z'::bytea), '00000000-0000-0000-0000-000000000001', now())$q$, '42501'::char(5), null, 'group_invites: member insert denied (RPC only)');
select tests.as_anon();
select throws_ok($q$insert into public.group_invites (group_id, token_hash, created_by, expires_at) values ('00000000-0000-0000-0001-000000000001', sha256('z'::bytea), '00000000-0000-0000-0000-000000000001', now())$q$, '42501'::char(5), null, 'group_invites: anon insert denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$update public.group_invites set created_at = now() where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_invites: member update denied (RPC only)');
select tests.as_anon();
select throws_ok($q$update public.group_invites set created_at = now() where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_invites: anon update denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$delete from public.group_invites where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_invites: member hard delete denied');
select tests.as_anon();
select throws_ok($q$delete from public.group_invites where group_id = '00000000-0000-0000-0001-000000000001'$q$, '42501'::char(5), null, 'group_invites: anon hard delete denied');

reset role;
select is_empty($q$
  select tablename from pg_tables where schemaname = 'public'
  except select unnest(array['groups', 'members', 'expenses', 'expense_payers', 'expense_shares', 'settlements', 'vehicles', 'ride_templates', 'rides', 'group_memberships', 'group_invites', 'fuel_price_cache', 'fx_rates', 'rate_limits', 'expense_revisions'])
$q$, 'every public table has a block in this matrix (fuel_price_cache, rate_limits: fuel_prices.sql; fx_rates: fx_rates.sql; expense_revisions: expense_revisions.sql)');
select * from finish();
rollback;
