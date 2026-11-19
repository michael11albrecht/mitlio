-- app_config (P6-T16a): anon-readable minimum app version, no client writes, version format check,
-- and the retry hint on the join_group rate limit (P0429).
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

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

-- Returns the hint of the error join_group raises (null if it raises nothing).
create function tests.join_hint(tok text) returns text
language plpgsql as $$
declare
  h text;
begin
  perform public.join_group(tok);
  return null;
exception when sqlstate 'P0429' then
  get stacked diagnostics h = pg_exception_hint;
  return h;
end;
$$;

-- seed rows ---------------------------------------------------------------------------------------
select is((select count(*) from public.app_config), 2::bigint, 'ios and android are seeded');
select is((select count(*) from public.app_config
           where min_supported_version = '0.0.0' and store_url is null), 2::bigint,
  'both seeds block nobody and have no store url');

-- reads and writes by role ------------------------------------------------------------------------
set local role anon;
select is((select count(*) from public.app_config), 2::bigint, 'anon can select app_config');
select throws_ok($q$insert into public.app_config (platform, min_supported_version) values ('ios', '1.0.0')$q$,
  '42501', null, 'anon cannot insert');
select throws_ok($q$update public.app_config set min_supported_version = '9.9.9'$q$,
  '42501', null, 'anon cannot update');
select throws_ok($q$delete from public.app_config$q$, '42501', null, 'anon cannot delete');

set local role authenticated;
select is((select count(*) from public.app_config), 2::bigint, 'authenticated can select app_config');
select throws_ok($q$insert into public.app_config (platform, min_supported_version) values ('ios', '1.0.0')$q$,
  '42501', null, 'authenticated cannot insert');
select throws_ok($q$update public.app_config set min_supported_version = '9.9.9'$q$,
  '42501', null, 'authenticated cannot update');
select throws_ok($q$delete from public.app_config$q$, '42501', null, 'authenticated cannot delete');

-- version format ----------------------------------------------------------------------------------
reset role;
select throws_ok($q$update public.app_config set min_supported_version = '1.2' where platform = 'ios'$q$,
  '23514', null, 'check constraint rejects 1.2');
select throws_ok($q$update public.app_config set min_supported_version = 'v1.2.3' where platform = 'ios'$q$,
  '23514', null, 'check constraint rejects v1.2.3');
select lives_ok($q$update public.app_config set min_supported_version = '1.2.3' where platform = 'ios'$q$,
  'check constraint accepts 1.2.3');

-- join_group retry hint ---------------------------------------------------------------------------
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test'),
  ('00000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'erin@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select set_config('t.tok', public.create_invite('00000000-0000-0000-0001-000000000001'), true);

-- One transaction: now() is fixed, the bucket does not refill, 10 tokens.
select tests.as_user('00000000-0000-0000-0000-000000000006');
select is((select count(*) from generate_series(1, 10) g
           where public.join_group(current_setting('t.tok')) is not null), 10::bigint,
  'attempts 1 to 10 are allowed');
select matches(tests.join_hint(current_setting('t.tok')), '^retry_after_seconds=\d+$',
  'the 11th attempt raises P0429 with a retry_after_seconds hint');

select * from finish();
rollback;
