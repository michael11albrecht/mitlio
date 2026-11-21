-- Push notification tables (P6b-T02): device_tokens, notification_prefs, notification_outbox.
-- Actors: alice (member of group A), bob (member of group B only), mallory (member of nothing).
begin;
create extension if not exists pgtap with schema extensions;
select plan(43);

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
  ('00000000-0000-0000-0001-000000000002', 'Group B', 'EUR', '00000000-0000-0000-0000-000000000002', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000002');

-- device_tokens: register, read, move, validate ------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$select public.register_device_token('tok-alice', 'android', 'de-DE', '1.0.0')$q$,
  'alice registers a token');
select is((select count(*) from public.device_tokens), 1::bigint, 'alice reads her token');
select is((select locale from public.device_tokens), 'de-DE', 'locale is stored');

select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((select count(*) from public.device_tokens), 0::bigint, 'bob cannot read alice''s token');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.device_tokens), 0::bigint, 'mallory cannot read alice''s token');

-- A token moves to the account that signs in on that device.
select tests.as_user('00000000-0000-0000-0000-000000000002');
select lives_ok($q$select public.register_device_token('tok-alice', 'ios')$q$,
  'bob registers the same token (shared device)');
select is((select count(*) from public.device_tokens), 1::bigint, 'the token is now bob''s');
select is((select platform from public.device_tokens), 'ios', 'platform updated, locale defaults');
select is((select locale from public.device_tokens), 'en', 'locale defaults to en');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select count(*) from public.device_tokens), 0::bigint, 'alice no longer sees it');

-- Validation (SQLSTATE 23514, stable message).
select throws_ok($q$select public.register_device_token('t', 'windows')$q$, '23514', 'invalid_token',
  'unknown platform is rejected');
select throws_ok($q$select public.register_device_token(null, 'ios')$q$, '23514', 'invalid_token',
  'null token is rejected');
select throws_ok($q$select public.register_device_token('', 'ios')$q$, '23514', 'invalid_token',
  'empty token is rejected');
select throws_ok($q$select public.register_device_token('t', 'ios', 'x')$q$, '23514', 'invalid_token',
  'too short locale is rejected');
select throws_ok($q$select public.register_device_token('t', 'ios', 'en', repeat('v', 51))$q$,
  '23514', 'invalid_token', 'too long app version is rejected');

-- Direct writes are denied for clients (select-only grant).
select throws_ok(
  $q$insert into public.device_tokens (user_id, token, platform)
     values ('00000000-0000-0000-0000-000000000001', 'direct', 'ios')$q$,
  '42501'::char(5), null, 'direct insert into device_tokens denied');
select throws_ok($q$update public.device_tokens set platform = 'ios'$q$, '42501'::char(5), null,
  'direct update of device_tokens denied');
select throws_ok($q$delete from public.device_tokens$q$, '42501'::char(5), null,
  'direct delete from device_tokens denied');

-- Anon cannot do anything.
select tests.as_anon();
select throws_ok($q$select public.register_device_token('anon', 'ios')$q$, '42501'::char(5), null,
  'anon cannot register');
select throws_ok($q$select public.unregister_device_token('tok-alice')$q$, '42501'::char(5), null,
  'anon cannot unregister');
select throws_ok($q$select 1 from public.device_tokens$q$, '42501'::char(5), null,
  'anon cannot read device_tokens');

-- Unregister only removes own tokens.
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok($q$select public.unregister_device_token('tok-alice')$q$,
  'alice unregistering bob''s token is a no-op');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((select count(*) from public.device_tokens), 1::bigint, 'bob''s token is still there');
select lives_ok($q$select public.unregister_device_token('tok-alice')$q$, 'bob unregisters it');
select is((select count(*) from public.device_tokens), 0::bigint, 'it is gone');

-- Newest 20 per account.
select lives_ok(
  $q$select public.register_device_token('bulk-' || i, 'android') from generate_series(1, 22) i$q$,
  'bob registers 22 tokens');
select is((select count(*) from public.device_tokens), 20::bigint, 'only 20 are kept');

-- notification_prefs ----------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select lives_ok(
  $q$insert into public.notification_prefs (user_id, group_id, level, quiet_hours, hide_amounts)
     values ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000001', 'mine',
             '{"start":"22:00","end":"07:00","utc_offset_minutes":60}', true)$q$,
  'alice sets prefs for her group');
select throws_ok(
  $q$insert into public.notification_prefs (user_id, group_id)
     values ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000002')$q$,
  '42501'::char(5), null, 'prefs for a group alice is not in are denied');
select throws_ok(
  $q$insert into public.notification_prefs (user_id, group_id)
     values ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0001-000000000001')$q$,
  '42501'::char(5), null, 'prefs for another user are denied');
select throws_ok(
  $q$update public.notification_prefs set level = 'bogus'$q$, '23514'::char(5), null,
  'unknown level is rejected');
select throws_ok(
  $q$update public.notification_prefs set quiet_hours = '"22:00"'$q$, '23514'::char(5), null,
  'quiet_hours must be an object');
select lives_ok($q$update public.notification_prefs set level = 'all', hide_amounts = false$q$,
  'alice updates her prefs');
select throws_ok($q$delete from public.notification_prefs$q$, '42501'::char(5), null,
  'prefs cannot be deleted by clients');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((select count(*) from public.notification_prefs), 0::bigint, 'bob cannot read alice''s prefs');
select lives_ok($q$update public.notification_prefs set level = 'none'$q$,
  'bob''s update matches none of alice''s rows');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((select level from public.notification_prefs), 'all', 'alice''s prefs are unchanged');

-- notification_outbox: no client access -----------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok($q$select 1 from public.notification_outbox$q$, '42501'::char(5), null,
  'authenticated cannot read the outbox');
select throws_ok(
  $q$insert into public.notification_outbox (group_id, event, entity_id, dedupe_key)
     values ('00000000-0000-0000-0001-000000000001', 'expense_added',
             '00000000-0000-0000-0003-000000000001', 'x')$q$,
  '42501'::char(5), null, 'authenticated cannot write the outbox');
select tests.as_anon();
select throws_ok($q$select 1 from public.notification_outbox$q$, '42501'::char(5), null,
  'anon cannot read the outbox');

-- Deleting a group takes its prefs and outbox rows with it (inactive-group cleanup, 0014).
reset role;
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000003', 'Group C', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.notification_prefs (user_id, group_id)
  values ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000003');
insert into public.notification_outbox (group_id, event, entity_id, dedupe_key)
  values ('00000000-0000-0000-0001-000000000003', 'expense_added',
          '00000000-0000-0000-0003-000000000001', 'cascade-test');
select lives_ok($q$delete from public.groups where id = '00000000-0000-0000-0001-000000000003'$q$,
  'deleting a group cascades to notification_prefs and notification_outbox');

-- Privileges on the functions ---------------------------------------------------------------------
reset role;
select ok(
  has_function_privilege('authenticated', 'public.register_device_token(text, text, text, text)', 'execute')
  and not has_function_privilege('anon', 'public.register_device_token(text, text, text, text)', 'execute')
  and not has_function_privilege('anon', 'public.unregister_device_token(text)', 'execute'),
  'only authenticated may call the token RPCs');
select ok(
  not has_function_privilege('authenticated', 'public.enqueue_notification(uuid, uuid, text, uuid, text, jsonb)', 'execute')
  and not has_function_privilege('anon', 'public.enqueue_notification(uuid, uuid, text, uuid, text, jsonb)', 'execute'),
  'clients cannot call enqueue_notification');

select * from finish();
rollback;
