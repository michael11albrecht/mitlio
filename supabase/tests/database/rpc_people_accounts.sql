-- ADR-24: owner role, one rotating non-expiring link, connect_member, remove_membership,
-- ownership hand-over in delete_my_data.
-- Actors: alice (creates group A, owner), bob/carol (joiners), mallory (nobody).
begin;
create extension if not exists pgtap with schema extensions;
select plan(37);

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

reset role;
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'carol@example.test'),
  ('00000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'mallory@example.test');

-- bootstrap: the creator becomes owner, whatever the client sends ----------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
select lives_ok(
  $q$insert into public.group_memberships (group_id, user_id, role)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', 'member')$q$,
  'the creator bootstraps the group');
reset role;
select is((select role from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000001'), 'owner',
  'the bootstrap membership is owner, the client value is ignored');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 1),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'h1', 'm3', 2);

-- links -----------------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select set_config('t.tok1', public.create_invite('00000000-0000-0000-0001-000000000001'), true)$q$,
  'the owner creates the first link');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((public.join_group(current_setting('t.tok1')) ->> 'already_member'), 'false', 'bob joins');
reset role;
select is((select role from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000002'), 'member', 'a joiner is a member');

select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok(
  $q$insert into public.group_memberships (group_id, user_id, role)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002', 'owner')$q$,
  '42501', null, 'a second member cannot self-insert as owner');
select throws_ok($q$update public.group_memberships set role = 'owner'$q$,
  '42501', null, 'a client cannot update role');
select throws_ok($q$select public.create_invite('00000000-0000-0000-0001-000000000001')$q$,
  '42501', null, 'a non-owner cannot create a link');
select throws_ok(
  $q$select public.revoke_invite((select id from public.group_invites limit 1))$q$,
  '42501', null, 'a non-owner cannot revoke a link');
select throws_ok(
  $q$select public.remove_membership((select id from public.group_memberships
     where user_id = '00000000-0000-0000-0000-000000000001'))$q$,
  '42501', null, 'a non-owner cannot remove a membership');

reset role;
insert into public.group_memberships (group_id, user_id, role)
values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000004', 'owner');
select is((select role from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000004'), 'member',
  'the trigger forces member on a populated group even for direct inserts');
delete from public.group_memberships where user_id = '00000000-0000-0000-0000-000000000004';

select is((select expires_at from public.group_invites
           where token_hash = sha256(convert_to(current_setting('t.tok1'), 'UTF8'))),
  'infinity'::timestamptz, 'links do not expire');

-- rotation ----------------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select set_config('t.tok2', public.create_invite('00000000-0000-0000-0001-000000000001'), true)$q$,
  'the owner creates a new link');
select is((select count(*) from public.group_invites
           where group_id = '00000000-0000-0000-0001-000000000001' and revoked_at is null),
  1::bigint, 'only the new link is active');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok($q$select public.join_group(current_setting('t.tok1'))$q$,
  '22023', 'invite_invalid', 'the old link no longer works');
select is((public.join_group(current_setting('t.tok2')) ->> 'already_member'), 'false',
  'the new link works (carol joins)');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select public.revoke_invite((select id from public.group_invites where revoked_at is null))$q$,
  'the owner can revoke the active link');
select throws_ok(
  $q$select public.remove_membership((select id from public.group_memberships
     where user_id = '00000000-0000-0000-0000-000000000001'))$q$,
  '23514', null, 'the owner cannot remove themselves');
select throws_ok($q$select public.remove_membership('00000000-0000-0000-0009-000000000009')$q$,
  '42501', null, 'an unknown membership looks like a missing right');

-- connect_member ----------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000004');
select throws_ok(
  $q$select public.connect_member('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0002-000000000001')$q$,
  '42501', null, 'a non-member cannot connect');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok(
  $q$select public.connect_member('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0002-000000000099')$q$,
  '22023', 'member_not_found', 'unknown person');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((public.connect_member('00000000-0000-0000-0001-000000000001',
           '00000000-0000-0000-0002-000000000001') ->> 'member_id'),
  '00000000-0000-0000-0002-000000000001', 'bob connects to m1');
select is((public.connect_member('00000000-0000-0000-0001-000000000001',
           '00000000-0000-0000-0002-000000000001') ->> 'already_connected'),
  'true', 'repeating the connection is idempotent');
select throws_ok(
  $q$select public.connect_member('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0002-000000000002')$q$,
  '23514', 'membership_already_linked', 'an account cannot connect to two persons');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok(
  $q$select public.connect_member('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0002-000000000001')$q$,
  '23505', 'member_already_claimed', 'a person already connected to another account cannot be connected');
select is((public.connect_member('00000000-0000-0000-0001-000000000001',
           '00000000-0000-0000-0002-000000000002') ->> 'member_id'),
  '00000000-0000-0000-0002-000000000002', 'carol connects to m2');
reset role;
select is((select count(*) from public.group_join_audit
           where user_id = '00000000-0000-0000-0000-000000000002'
             and member_id = '00000000-0000-0000-0002-000000000001'), 1::bigint,
  'connect_member writes one audit row (the repeat wrote none)');
select is((select user_id from public.members where id = '00000000-0000-0000-0002-000000000001'),
  '00000000-0000-0000-0000-000000000002'::uuid, 'the person records the connected account');

-- remove_membership -----------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select public.remove_membership((select id from public.group_memberships
     where user_id = '00000000-0000-0000-0000-000000000002'))$q$,
  'the owner removes bob');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(public.is_group_member('00000000-0000-0000-0001-000000000001'), false,
  'bob lost access');
reset role;
select is((select count(*) from public.members where id = '00000000-0000-0000-0002-000000000001'),
  1::bigint, 'the person row remains');
select is((select user_id from public.members where id = '00000000-0000-0000-0002-000000000001'), null,
  'the removed account is unlinked from the person');

-- delete_my_data hands ownership over --------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$select public.delete_my_data()$q$, 'the owner deletes their data');
reset role;
select is((select role from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000003'), 'owner',
  'ownership passed to the oldest remaining membership');
select is((select count(*) from public.group_memberships where role = 'owner'), 1::bigint,
  'exactly one owner remains');
select is(
  (select count(*) from pg_proc p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('connect_member', 'remove_membership', 'create_invite', 'revoke_invite',
                       'set_membership_role')
     and p.prosecdef and p.proconfig @> array['search_path=""']),
  5::bigint, 'ADR-24 functions are security definer with an empty search_path');
select is_empty(
  $q$select p.proname from pg_proc p
     where p.pronamespace = 'public'::regnamespace
       and p.proname in ('connect_member', 'remove_membership', 'create_invite', 'revoke_invite')
       and (has_function_privilege('anon', p.oid, 'execute')
            or not has_function_privilege('authenticated', p.oid, 'execute'))$q$,
  'new RPCs: no EXECUTE for anon/PUBLIC, EXECUTE for authenticated');

select * from finish();
rollback;
