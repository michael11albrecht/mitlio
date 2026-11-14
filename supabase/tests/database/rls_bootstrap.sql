-- Group bootstrap and RLS helper functions (P6-T03).
-- A user creates a group, then adds the first membership row for themselves. Nobody else can.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

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
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test');

-- alice creates a group and becomes its first member.
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$insert into public.groups (id, name, currency, created_by, updated_at)
     values ('00000000-0000-0000-0001-000000000001', 'G', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1')$q$,
  'user can create a group they own');
select is(
  (select count(*) from public.groups where id = '00000000-0000-0000-0001-000000000001'),
  1::bigint, 'creator can read the group before any membership exists');
select is(public.is_group_member('00000000-0000-0000-0001-000000000001'), false,
  'creator is not yet a member before bootstrapping');

select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok(
  $q$insert into public.group_memberships (group_id, user_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002')$q$,
  '42501'::char(5), null, 'a stranger cannot bootstrap someone else''s group');
select is(
  (select count(*) from public.groups where id = '00000000-0000-0000-0001-000000000001'),
  0::bigint, 'a stranger cannot read a group that has no membership for them');

select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok(
  $q$insert into public.group_memberships (group_id, user_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002')$q$,
  '42501'::char(5), null, 'creator cannot insert a membership for another user');
select lives_ok(
  $q$insert into public.group_memberships (group_id, user_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001')$q$,
  'creator can add themselves as first member');
select is(public.is_group_member('00000000-0000-0000-0001-000000000001'), true,
  'is_group_member is true after bootstrapping');
select throws_ok(
  $q$insert into public.group_memberships (group_id, user_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001')$q$,
  '42501'::char(5), null, 'bootstrap is one-shot: a populated group cannot be bootstrapped again');

select tests.as_user('00000000-0000-0000-0000-000000000002');
select is(public.is_group_member('00000000-0000-0000-0001-000000000001'), false,
  'is_group_member is false for a non-member');

select tests.as_anon();
select throws_ok(
  $q$select public.is_group_member('00000000-0000-0000-0001-000000000001')$q$,
  '42501'::char(5), null, 'anon cannot execute is_group_member');

reset role;
select ok(
  (select p.prosecdef and p.proconfig @> array['search_path=""']
   from pg_proc p where p.oid = 'public.is_group_member(uuid)'::regprocedure),
  'is_group_member is security definer with an empty search_path');

select * from finish();
rollback;
