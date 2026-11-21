-- Outbox health for the notify monitor (P6b-T10): age of the oldest due pending row and failures in
-- the last hour; only service_role may read it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

reset role;
select is((select oldest_due_age_seconds from public.notification_outbox_health()), 0::bigint,
  'an empty outbox has age 0');
select is((select failed_last_hour from public.notification_outbox_health()), 0::bigint,
  'an empty outbox has no failures');

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.notification_outbox (id, group_id, event, entity_id, dedupe_key, created_at) values
  ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000001', 'k1', now() - interval '10 minutes'),
  ('00000000-0000-0000-0004-000000000002', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000002', 'k2', now() - interval '1 minute'),
  ('00000000-0000-0000-0004-000000000003', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000003', 'k3', now() - interval '3 hours'),
  ('00000000-0000-0000-0004-000000000004', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000004', 'k4', now() - interval '2 hours'),
  ('00000000-0000-0000-0004-000000000005', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000005', 'k5', now() - interval '30 minutes');

-- Row 3: already processed (not pending). Row 4: failed 2 hours ago. Row 5: failed 5 minutes ago.
update public.notification_outbox set processed_at = now() - interval '2 hours'
  where id = '00000000-0000-0000-0004-000000000003';
update public.notification_outbox set processed_at = now() - interval '2 hours',
  failed_at = now() - interval '2 hours'
  where id = '00000000-0000-0000-0004-000000000004';
update public.notification_outbox set processed_at = now() - interval '5 minutes',
  failed_at = now() - interval '5 minutes'
  where id = '00000000-0000-0000-0004-000000000005';

select cmp_ok((select oldest_due_age_seconds from public.notification_outbox_health()),
  '>=', 595::bigint, 'oldest due age counts the oldest pending row (10 minutes)');
select cmp_ok((select oldest_due_age_seconds from public.notification_outbox_health()),
  '<', 900::bigint, 'processed and failed rows do not count towards the age');
select is((select failed_last_hour from public.notification_outbox_health()), 1::bigint,
  'only failures of the last hour are counted');

-- A row waiting for its retry backoff is not "due", so it does not make the backlog look stale.
update public.notification_outbox set next_attempt_at = now() + interval '1 hour'
  where id = '00000000-0000-0000-0004-000000000001';
select cmp_ok((select oldest_due_age_seconds from public.notification_outbox_health()),
  '<', 120::bigint, 'a row that is not due yet is ignored (only the 1 minute row is due)');

select ok(
  has_function_privilege('service_role', 'public.notification_outbox_health()', 'execute')
  and not has_function_privilege('authenticated', 'public.notification_outbox_health()', 'execute')
  and not has_function_privilege('anon', 'public.notification_outbox_health()', 'execute'),
  'only service_role may read the health');

select * from finish();
rollback;
