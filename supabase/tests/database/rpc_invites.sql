-- Invite RPCs (P6-T05): create_invite, revoke_invite, join_group.
-- Actors: alice (member of A, unlinked), bob/carol/dave (joiners), mallory (nobody).
begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

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
  ('00000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'carol@example.test'),
  ('00000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'dave@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1'),
  ('00000000-0000-0000-0001-000000000002', 'Group B', 'EUR', '00000000-0000-0000-0000-000000000003', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 1),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'h1', 'm3', 2),
  ('00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0001-000000000002', 'h1', 'mb', 0);

-- create_invite ------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok($q$select public.create_invite('00000000-0000-0000-0001-000000000001')$q$,
  '42501', null, 'a non-member cannot create an invite');
select tests.as_anon();
select throws_ok($q$select public.create_invite('00000000-0000-0000-0001-000000000001')$q$,
  '42501', null, 'anon cannot create an invite');

select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$select set_config('t.tok', public.create_invite('00000000-0000-0000-0001-000000000001'), true)$q$,
  'a member can create an invite');
select is(length(current_setting('t.tok')), 43, 'token is 32 bytes base64url (43 chars)');
select matches(current_setting('t.tok'), '^[A-Za-z0-9_-]{43}$', 'token is url-safe');
select is(
  (select count(*) from public.group_invites
   where group_id = '00000000-0000-0000-0001-000000000001'
     and token_hash = sha256(convert_to(current_setting('t.tok'), 'UTF8'))
     and expires_at = now() + interval '7 days'),
  1::bigint, 'only sha256(token) is stored, expiry is 7 days');

reset role;
select is_empty(
  $q$select t.tablename from pg_tables t
     where t.schemaname = 'public'
       and (xpath('/row/c/text()', query_to_xml(
              format('select count(*) as c from %I.%I x where x::text like %L',
                     'public', t.tablename, '%' || current_setting('t.tok') || '%'),
              false, true, '')))[1]::text::int > 0$q$,
  'the plaintext token appears in no table');

-- join_group: invalid tokens -------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$select public.join_group('no-such-token')$q$,
  '22023', 'invite_invalid', 'an unknown token fails');
select throws_ok($q$select public.join_group(null)$q$,
  '22023', 'invite_invalid', 'a null token fails');

reset role;
insert into public.group_invites (group_id, token_hash, created_by, expires_at)
values ('00000000-0000-0000-0001-000000000001', sha256(convert_to('expired-token', 'UTF8')),
        '00000000-0000-0000-0000-000000000001', now() - interval '1 second');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok($q$select public.join_group('expired-token')$q$,
  '22023', 'invite_invalid', 'an expired token fails');

-- join_group: join + idempotency -----------------------------------------------------------------
select is((public.join_group(current_setting('t.tok')) ->> 'already_member'), 'false',
  'a valid token adds the caller to the group');
select is((select count(*) from public.group_memberships
           where group_id = '00000000-0000-0000-0001-000000000001'
             and user_id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'membership row exists for the joiner');
select is((public.join_group(current_setting('t.tok')) ->> 'already_member'), 'true',
  'joining a second time is idempotent');
select is((public.join_group(current_setting('t.tok')) ->> 'membership_id'),
  (select id::text from public.group_memberships
   where group_id = '00000000-0000-0000-0001-000000000001'
     and user_id = '00000000-0000-0000-0000-000000000002'),
  'the second join returns the existing membership');
select is((select count(*) from public.group_memberships
           where group_id = '00000000-0000-0000-0001-000000000001'
             and user_id = '00000000-0000-0000-0000-000000000002'), 1::bigint,
  'no duplicate membership after the second join');
select lives_ok($q$select public.create_invite('00000000-0000-0000-0001-000000000001')$q$,
  'a joined member can create invites');

-- join_group: claiming -----------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000004');
select is((public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000001')
           ->> 'member_id'), '00000000-0000-0000-0002-000000000001',
  'join with claim links the membership to the member');
reset role;
select is((select user_id from public.members where id = '00000000-0000-0000-0002-000000000001'),
  '00000000-0000-0000-0000-000000000004'::uuid, 'claimed member records the user');
select tests.as_user('00000000-0000-0000-0000-000000000005');
select throws_ok(
  $q$select public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000001')$q$,
  '23505', 'member_already_claimed', 'a member cannot be claimed twice');
select throws_ok(
  $q$select public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-00000000000b')$q$,
  '22023', 'member_not_found', 'cannot claim a member of another group');
select is((select count(*) from public.group_memberships
           where user_id = '00000000-0000-0000-0000-000000000005'), 0::bigint,
  'a failed claim does not leave a membership behind');
select tests.as_user('00000000-0000-0000-0000-000000000004');
select is((public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000001')
           ->> 'already_member'), 'true', 'repeating the same claim is idempotent');
select throws_ok(
  $q$select public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000003')$q$,
  '23514', 'membership_already_linked', 'an already linked membership cannot claim another member');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((public.join_group(current_setting('t.tok'), '00000000-0000-0000-0002-000000000002')
           ->> 'member_id'), '00000000-0000-0000-0002-000000000002',
  'an existing unlinked member can claim via the invite');
select is((select count(*) from public.group_memberships
           where group_id = '00000000-0000-0000-0001-000000000001'
             and user_id = '00000000-0000-0000-0000-000000000001'), 1::bigint,
  'claiming from an existing membership does not duplicate it');

-- revoke_invite ----------------------------------------------------------------------------------------
select lives_ok(
  $q$select set_config('t.tok2', public.create_invite('00000000-0000-0000-0001-000000000001'), true)$q$,
  'create a second invite');
select lives_ok(
  $q$select set_config('t.inv',
       (select id::text from public.group_invites
        where token_hash = sha256(convert_to(current_setting('t.tok2'), 'UTF8'))), true)$q$,
  'a member can read the invite id');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok($q$select public.revoke_invite(current_setting('t.inv')::uuid)$q$,
  '42501', null, 'a non-member cannot revoke an invite');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$select public.revoke_invite(current_setting('t.inv')::uuid)$q$,
  'a member can revoke an invite');
select tests.as_user('00000000-0000-0000-0000-000000000005');
select throws_ok($q$select public.join_group(current_setting('t.tok2'))$q$,
  '22023', 'invite_invalid', 'a revoked token fails');

-- Access control -----------------------------------------------------------------------------------------
select tests.as_anon();
select throws_ok($q$select public.join_group('x')$q$, '42501', null, 'anon cannot join');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok(
  $q$insert into public.group_invites (group_id, token_hash, created_by, expires_at)
     values ('00000000-0000-0000-0001-000000000001', sha256('z'::bytea),
             '00000000-0000-0000-0000-000000000001', now() + interval '1 day')$q$,
  '42501', null, 'clients cannot insert invites directly');

reset role;
select is(
  (select count(*) from pg_proc p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('create_invite', 'revoke_invite', 'join_group')
     and p.prosecdef and p.proconfig @> array['search_path=""']),
  3::bigint, 'all invite functions are security definer with an empty search_path');
select is_empty(
  $q$select p.proname from pg_proc p
     where p.pronamespace = 'public'::regnamespace
       and p.proname in ('create_invite', 'revoke_invite', 'join_group', 'upsert_expense')
       and (has_function_privilege('anon', p.oid, 'execute')
            or not has_function_privilege('authenticated', p.oid, 'execute'))$q$,
  'RPCs: no EXECUTE for anon/PUBLIC, EXECUTE for authenticated');

select * from finish();
rollback;
