-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the function and
-- the cron job are created here and nothing else touches them.
-- 0013_retention: daily cleanup of the join audit log and expired invites (P7-T07; docs/retention.md).
--
-- The periods come from supabase/retention.json (join_audit_days = 90,
-- expired_invites_days_after_expiry = 30). web/tests/retention.spec.ts fails when they drift.
--   * group_join_audit rows are kept 90 days after joined_at (abuse investigation window).
--   * group_invites rows are kept 30 days after expires_at, so a just-expired link still shows
--     "expired" instead of "not found"; after that the token hash is useless and is removed.
-- The existing jobs (rate_limits, fuel_price_cache in 0005; fx_rates in 0006) are unchanged.

set lock_timeout = '1s';
set statement_timeout = '5s';

create or replace function public.cleanup_join_data() returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.group_join_audit where joined_at < now() - interval '90 days';
  delete from public.group_invites where expires_at < now() - interval '30 days';
$$;
revoke all on function public.cleanup_join_data() from public, anon, authenticated;

select cron.schedule('join-data-cleanup', '29 3 * * *', 'select public.cleanup_join_data()');
