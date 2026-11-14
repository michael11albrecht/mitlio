-- delete_my_data RPC (P7-T07).
-- Actors: alice (member of A and B, linked to member m1 in A), bob (member of A, linked to m2),
-- mallory (member of nothing, no data).
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

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
  ('00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'mallory@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1'),
  ('00000000-0000-0000-0001-000000000002', 'Group B', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.members (id, group_id, updated_at, name, position, user_id) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0,
   '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 1,
   '00000000-0000-0000-0000-000000000002'),
  ('00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0001-000000000002', 'h1', 'mb', 0, null);
insert into public.group_memberships (group_id, user_id, member_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0002-000000000001'),
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0002-000000000002'),
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000001', null);
insert into public.group_invites (group_id, token_hash, created_by, expires_at) values
  ('00000000-0000-0000-0001-000000000001', sha256('a'::bytea),
   '00000000-0000-0000-0000-000000000001', now() + interval '1 day');

-- Access control ------------------------------------------------------------------------------------------
select tests.as_anon();
select throws_ok($q$select public.delete_my_data()$q$, '42501', null, 'anon cannot call it');

reset role;
select is_empty(
  $q$select p.proname from pg_proc p
     where p.pronamespace = 'public'::regnamespace and p.proname = 'delete_my_data'
       and (has_function_privilege('anon', p.oid, 'execute')
            or not has_function_privilege('authenticated', p.oid, 'execute'))$q$,
  'no EXECUTE for anon/PUBLIC, EXECUTE for authenticated');
select is(
  (select count(*) from pg_proc p
   where p.pronamespace = 'public'::regnamespace and p.proname = 'delete_my_data'
     and p.prosecdef and p.proconfig @> array['search_path=""']),
  1::bigint, 'security definer with an empty search_path');

-- A user without data: nothing happens to anyone else ------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is(public.delete_my_data() ->> 'memberships_deleted', '0', 'mallory has nothing to delete');
reset role;
select is((select count(*) from public.group_memberships), 3::bigint,
  'mallory deleting nothing leaves all memberships');
select is((select count(*) from auth.users), 2::bigint, 'only mallory''s auth user is gone');

-- Alice deletes her data ----------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(
  public.delete_my_data(),
  jsonb_build_object(
    'memberships_deleted', 2, 'members_unlinked', 1,
    'device_tokens_deleted', 0, 'notification_prefs_deleted', 0,
    'auth_user_deleted', true),
  'alice: report counts her own rows only');

reset role;
select is((select count(*) from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000001'), 0::bigint,
  'alice has no memberships left');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-000000000001'), 0::bigint,
  'alice''s auth user is deleted');
select is((select user_id from public.members where id = '00000000-0000-0000-0002-000000000001'), null,
  'her member row is unlinked');
select is((select count(*) from public.group_invites), 0::bigint,
  'invites she created went with her auth user');

-- Bob and the shared data are untouched --------------------------------------------------------------
select is((select count(*) from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'bob keeps his membership');
select is((select user_id from public.members where id = '00000000-0000-0000-0002-000000000002'),
  '00000000-0000-0000-0000-000000000002'::uuid, 'bob''s member link is untouched');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'bob''s auth user is untouched');
select is((select count(*) from public.members), 3::bigint, 'no member row was deleted');
select is((select count(*) from public.groups), 2::bigint, 'shared groups stay');

-- Idempotent ----------------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is(
  public.delete_my_data(),
  jsonb_build_object(
    'memberships_deleted', 0, 'members_unlinked', 0,
    'device_tokens_deleted', 0, 'notification_prefs_deleted', 0,
    'auth_user_deleted', false),
  'calling it twice is a no-op');

select * from finish();
rollback;
