-- Auth audit log (#206): delete_account_data removes the user's auth.audit_log_entries rows, other
-- users' rows stay, and the purge is a no-op when the table is empty. The 7-day threshold itself is
-- tested in retention.sql.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, aud, role, email, is_anonymous) values
  ('00000000-0000-0000-0000-0000000000c1', 'authenticated', 'authenticated', null, true),
  ('00000000-0000-0000-0000-0000000000c2', 'authenticated', 'authenticated', null, true);

-- Start from an empty table (also proves the purge below is a no-op on it).
delete from auth.audit_log_entries;
select lives_ok($q$select public.cleanup_auth_audit_log()$q$, 'purge on an empty audit table does not fail');
select is((select count(*) from auth.audit_log_entries), 0::bigint, 'purge on an empty audit table leaves it empty');

insert into auth.audit_log_entries (instance_id, id, payload, created_at) values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000c-000000000001',
    '{"actor_id":"00000000-0000-0000-0000-0000000000c1","action":"token_refreshed"}', now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000c-000000000002',
    '{"actor_id":"00000000-0000-0000-0000-0000000000c1","action":"logout"}', now() - interval '1 day'),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000c-000000000003',
    '{"actor_id":"00000000-0000-0000-0000-000000000000","action":"user_deleted","traits":{"user_id":"00000000-0000-0000-0000-0000000000c1"}}', now()),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-000c-000000000004',
    '{"actor_id":"00000000-0000-0000-0000-0000000000c2","action":"token_refreshed"}', now());

select is((public.delete_account_data('00000000-0000-0000-0000-0000000000c1')->>'auth_audit_entries_deleted')::bigint, 3::bigint,
  'delete_account_data reports the deleted audit rows');
select is((select count(*) from auth.audit_log_entries
   where payload->>'actor_id' = '00000000-0000-0000-0000-0000000000c1'
      or payload->'traits'->>'user_id' = '00000000-0000-0000-0000-0000000000c1'), 0::bigint,
  'audit rows of the deleted user (actor and traits) are gone');
select is((select count(*) from auth.audit_log_entries where id = '00000000-0000-0000-000c-000000000004'), 1::bigint,
  'audit rows of other users are kept');
select is((select count(*) from auth.users where id = '00000000-0000-0000-0000-0000000000c1'), 0::bigint,
  'the account itself is deleted as before');
select is((public.delete_account_data('00000000-0000-0000-0000-0000000000c1')->>'auth_audit_entries_deleted')::bigint, 0::bigint,
  'a second call finds no audit rows (idempotent)');

select * from finish();
rollback;
