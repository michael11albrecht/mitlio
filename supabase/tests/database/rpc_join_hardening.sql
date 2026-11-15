-- join_group hardening (#89): per-user rate limit and the group_join_audit table.
-- Actors: alice (member of A), bob (joins A and claims m1), erin (hits the rate limit),
-- mallory (member of nothing, then joins once to prove the limit is per user).
begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

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

reset role;
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'mallory@example.test'),
  ('00000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated', 'erin@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0);

select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select set_config('t.tok', public.create_invite('00000000-0000-0000-0001-000000000001'), true)$q$,
  'a member can create an invite');

-- audit rows --------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000001')
           ->> 'already_member'), 'false', 'bob joins and claims m1');
reset role;
select is((select count(*) from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'a successful join writes exactly one audit row');
select is((select member_id from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000002'),
  '00000000-0000-0000-0002-000000000001'::uuid, 'the audit row records the claimed member');
select is((select group_id from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000002'),
  '00000000-0000-0000-0001-000000000001'::uuid, 'the audit row records the group');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((public.join_group(current_setting('t.tok')) ->> 'already_member'), 'true',
  'joining again is idempotent');
reset role;
select is((select count(*) from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'an idempotent repeat writes no further audit row');

-- audit RLS ---------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.group_join_audit
           where group_id = '00000000-0000-0000-0001-000000000001'), 1::bigint,
  'a member of the group can read its audit rows');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.group_join_audit), 0::bigint,
  'a non-member cannot read audit rows');
select tests.as_anon();
select throws_ok($q$select count(*) from public.group_join_audit$q$,
  '42501', null, 'anon cannot read audit rows');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok(
  $q$insert into public.group_join_audit (group_id, user_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001')$q$,
  '42501', null, 'authenticated cannot insert audit rows directly');
select throws_ok(
  $q$update public.group_join_audit set joined_at = now()$q$,
  '42501', null, 'authenticated cannot update audit rows');
select throws_ok(
  $q$delete from public.group_join_audit$q$,
  '42501', null, 'authenticated cannot delete audit rows');

-- rate limit ---------------------------------------------------------------------------------------
-- All calls run in one transaction (now() is fixed), so the bucket does not refill: 10 tokens.
select tests.as_user('00000000-0000-0000-0000-000000000006');
select is((public.join_group(current_setting('t.tok')) ->> 'already_member'), 'false',
  'erin joins (attempt 1)');
select is((select count(*) from generate_series(1, 9) g
           where public.join_group(current_setting('t.tok')) is not null), 9::bigint,
  'attempts 2 to 10 are allowed');
select throws_ok($q$select public.join_group(current_setting('t.tok'))$q$,
  'P0429', 'rate_limited', 'the 11th attempt within the window fails with P0429');
reset role;
select is((select count(*) from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000006'), 1::bigint,
  'the rate-limited calls wrote no extra audit row');
select is((select count(*) from public.rate_limits
           where key_hash = 'join:' || encode(
             sha256(convert_to('00000000-0000-0000-0000-000000000006', 'UTF8')), 'hex')),
  1::bigint, 'the bucket is keyed by the hashed user id');
select is((select count(*) from public.rate_limits
           where key_hash like '%00000000-0000-0000-0000-000000000006%'), 0::bigint,
  'the plain user id is not stored in rate_limits');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select lives_ok($q$select public.join_group(current_setting('t.tok'))$q$,
  'the limit is per user: another user is not affected');

select * from finish();
rollback;
