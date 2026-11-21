-- Outbox claim / retry functions and cron jobs (P6b-T05): claim marks due rows processed once,
-- retry backs off and stops at the max attempts, clients cannot call any of it.
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

reset role;
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.notification_outbox (id, group_id, event, entity_id, dedupe_key, created_at) values
  ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000001', 'k1', now() - interval '3 minutes'),
  ('00000000-0000-0000-0004-000000000002', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000002', 'k2', now() - interval '2 minutes'),
  ('00000000-0000-0000-0004-000000000003', '00000000-0000-0000-0001-000000000001', 'expense_added',
   '00000000-0000-0000-0003-000000000003', 'k3', now() - interval '1 minute');
-- Not due yet.
update public.notification_outbox set next_attempt_at = now() + interval '1 hour'
  where id = '00000000-0000-0000-0004-000000000003';

select is((select count(*) from public.claim_notification_outbox(1)), 1::bigint,
  'claim honours the limit');
select is(
  (select processed_at is not null and attempts = 1 from public.notification_outbox
   where id = '00000000-0000-0000-0004-000000000001'),
  true, 'the oldest row is marked processed with attempts = 1');
select is((select count(*) from public.claim_notification_outbox(10)), 1::bigint,
  'a second claim only gets the remaining due row (not the claimed one, not the future one)');
select is((select count(*) from public.claim_notification_outbox(10)), 0::bigint,
  'nothing left to claim');
select is(
  (select processed_at is null from public.notification_outbox
   where id = '00000000-0000-0000-0004-000000000003'),
  true, 'a row that is not due yet stays pending');

-- retry -------------------------------------------------------------------------------------------
select is(
  public.retry_notification_outbox(array['00000000-0000-0000-0004-000000000001']::uuid[], 'HTTP_503', 5),
  1, 'retry re-queues a claimed row');
select is(
  (select processed_at is null and last_error = 'HTTP_503' and failed_at is null
          and next_attempt_at > now() + interval '1 minute 30 seconds'
   from public.notification_outbox where id = '00000000-0000-0000-0004-000000000001'),
  true, 're-queued: pending again, error stored, delayed attempts * 2 minutes');
select is(
  public.retry_notification_outbox(array['00000000-0000-0000-0004-000000000003']::uuid[], 'x', 5),
  0, 'a pending (unclaimed) row is not touched by retry');

update public.notification_outbox set next_attempt_at = now()
  where id = '00000000-0000-0000-0004-000000000001';
select is((select attempts from public.claim_notification_outbox(10)
           where id = '00000000-0000-0000-0004-000000000001'),
  2::bigint, 'the second claim counts attempts = 2');
select is(
  public.retry_notification_outbox(array['00000000-0000-0000-0004-000000000001']::uuid[], 'HTTP_500', 2),
  0, 'at the max attempts nothing is re-queued');
select is(
  (select processed_at is not null and failed_at is not null and last_error = 'HTTP_500'
   from public.notification_outbox where id = '00000000-0000-0000-0004-000000000001'),
  true, 'at the max attempts the row stays processed and is marked failed');
select is(
  public.retry_notification_outbox(array['00000000-0000-0000-0004-000000000001']::uuid[], 'again', 9),
  0, 'a failed row is never re-queued');
select is(
  public.retry_notification_outbox(
    array['00000000-0000-0000-0004-000000000002']::uuid[], repeat('e', 500), 5),
  1, 'retry with a long error text works');
select is(
  (select length(last_error) from public.notification_outbox
   where id = '00000000-0000-0000-0004-000000000002'),
  200, 'a long error text is truncated to 200 characters');

-- cleanup -----------------------------------------------------------------------------------------
update public.notification_outbox set processed_at = now() - interval '8 days'
  where id = '00000000-0000-0000-0004-000000000001';
select lives_ok($q$select public.cleanup_notification_outbox()$q$, 'cleanup runs');
select is((select count(*) from public.notification_outbox
           where id = '00000000-0000-0000-0004-000000000001'),
  0::bigint, 'rows processed more than 7 days ago are removed');
select is((select count(*) from public.notification_outbox), 2::bigint, 'newer rows are kept');

-- invoke_notify without Vault secrets is a no-op ------------------------------------------------------
select lives_ok($q$select public.invoke_notify()$q$, 'invoke_notify without secrets does nothing');

-- cron ----------------------------------------------------------------------------------------------
select is((select schedule from cron.job where jobname = 'notify-outbox'), '* * * * *',
  'notify runs every minute');
select is((select command from cron.job where jobname = 'notify-outbox'),
  'select public.invoke_notify()', 'the notify job calls invoke_notify');
select ok(exists (select 1 from cron.job where jobname = 'notify-outbox-cleanup'),
  'outbox cleanup is scheduled');

-- privileges ----------------------------------------------------------------------------------------
select ok(
  has_function_privilege('service_role', 'public.claim_notification_outbox(integer)', 'execute')
  and has_function_privilege('service_role', 'public.retry_notification_outbox(uuid[], text, integer)', 'execute'),
  'service_role may claim and retry');
select ok(
  not has_function_privilege('authenticated', 'public.claim_notification_outbox(integer)', 'execute')
  and not has_function_privilege('anon', 'public.claim_notification_outbox(integer)', 'execute')
  and not has_function_privilege('authenticated', 'public.retry_notification_outbox(uuid[], text, integer)', 'execute')
  and not has_function_privilege('anon', 'public.retry_notification_outbox(uuid[], text, integer)', 'execute'),
  'clients cannot claim or retry');
select ok(
  not has_function_privilege('authenticated', 'public.invoke_notify()', 'execute')
  and not has_function_privilege('anon', 'public.invoke_notify()', 'execute')
  and not has_function_privilege('authenticated', 'public.cleanup_notification_outbox()', 'execute'),
  'clients cannot call invoke_notify or the cleanup');

select * from finish();
rollback;
