-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the function
-- is created here and nothing else defines it.
-- 0019_notification_health: outbox health for the `notify` monitor (P6b-T10, plan §7 P6b).
--
-- notification_outbox_health() answers two questions the function cannot know from one run:
--   * oldest_due_age_seconds: how long the oldest due, still pending row has been waiting. Grows
--     when the cron job, the function or the claim stops working, although every run "succeeds".
--   * failed_last_hour: rows that hit the max attempts (failed_at set) in the last hour.
-- It returns counts only, never ids, names or payloads. service_role only.

set lock_timeout = '1s';
set statement_timeout = '5s';

create function public.notification_outbox_health()
returns table (oldest_due_age_seconds bigint, failed_last_hour bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(
      extract(epoch from now() - min(o.created_at)
        filter (where o.processed_at is null and o.next_attempt_at <= now())),
      0)::bigint,
    count(*) filter (where o.failed_at > now() - interval '1 hour')
  from public.notification_outbox o;
$$;

revoke all on function public.notification_outbox_health() from public, anon, authenticated;
grant execute on function public.notification_outbox_health() to service_role;
