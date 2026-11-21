-- squawk-ignore-file prefer-robust-stmts, require-concurrent-index-creation
-- Justification: the Supabase CLI applies each migration file once, in a transaction; columns and
-- functions are added here and nothing else defines them. The outbox is empty or tiny when this
-- runs (it only holds not yet sent pushes), so the ALTER cannot block anything noticeable.
-- 0017_notify_claim_and_cron: claim / retry functions for the `notify` Edge Function and its
-- pg_cron schedule (P6b-T05, ADR-13, plan §7 P6b).
--
--   * claim_notification_outbox(limit): marks due rows processed and returns them, in one
--     statement with FOR UPDATE SKIP LOCKED, so two overlapping runs never take the same row.
--   * retry_notification_outbox(ids, error, max_attempts): after a failed send the row goes back
--     to pending with a growing delay (attempts * 2 minutes). At max_attempts it stays processed
--     and gets failed_at + last_error, so it can be inspected and is never retried again.
--   * invoke_notify(): called by pg_cron every minute, POSTs to the Edge Function through pg_net.
--     URL, anon key (gateway) and a shared token are read from Vault, like the warm-up jobs of
--     fuel-prices and fx-rates (0005, 0006). Without them it does nothing, so a fresh project
--     or CI never fails. The service role key is not stored in the database.
--   * cleanup_notification_outbox(): removes rows processed more than 7 days ago.
--
-- A crash between claim and send loses those pushes. That is acceptable: a push is a hint and the
-- app always syncs from the server (plan P6b design rules).

set lock_timeout = '1s';
set statement_timeout = '5s';

alter table public.notification_outbox
  add column attempts bigint not null default 0,
  add column next_attempt_at timestamptz not null default now(),
  add column last_error text check (char_length(last_error) <= 200),
  add column failed_at timestamptz;

create function public.claim_notification_outbox(p_limit integer default 200)
returns table (
  id uuid, group_id uuid, actor_user_id uuid, event text, entity_id uuid, payload jsonb,
  created_at timestamptz, attempts bigint
)
language sql
security definer
set search_path = ''
as $$
  with due as (
    select o.id
    from public.notification_outbox o
    where o.processed_at is null and o.next_attempt_at <= now()
    order by o.created_at, o.id
    limit least(greatest(coalesce(p_limit, 200), 1), 1000)
    for update skip locked
  )
  update public.notification_outbox o
  set processed_at = now(), attempts = o.attempts + 1
  from due
  where o.id = due.id
  returning o.id, o.group_id, o.actor_user_id, o.event, o.entity_id, o.payload, o.created_at,
            o.attempts;
$$;

create function public.retry_notification_outbox(
  p_ids uuid[], p_error text, p_max_attempts integer default 5
) returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_requeued integer;
begin
  -- Only rows that were claimed and have not failed for good.
  update public.notification_outbox o
  set processed_at = null,
      next_attempt_at = now() + make_interval(mins => (o.attempts * 2)::integer),
      last_error = left(p_error, 200)
  where o.id = any (p_ids) and o.processed_at is not null and o.failed_at is null
    and o.attempts < p_max_attempts;
  get diagnostics v_requeued = row_count;

  update public.notification_outbox o
  set failed_at = now(), last_error = left(p_error, 200)
  where o.id = any (p_ids) and o.processed_at is not null and o.failed_at is null
    and o.attempts >= p_max_attempts;
  return v_requeued;
end;
$$;

create function public.cleanup_notification_outbox() returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.notification_outbox where processed_at < now() - interval '7 days';
$$;

create function public.invoke_notify() returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_anon text;
  v_token text;
begin
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_url using 'notify_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_anon using 'notify_anon_key';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_token using 'notify_token';
  if coalesce(v_url, '') = '' or coalesce(v_anon, '') = '' or coalesce(v_token, '') = '' then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_anon,
      'apikey', v_anon,
      'x-notify-token', v_token),
    timeout_milliseconds := 30000);
end;
$$;

revoke all on function public.claim_notification_outbox(integer) from public, anon, authenticated;
revoke all on function public.retry_notification_outbox(uuid[], text, integer)
  from public, anon, authenticated;
revoke all on function public.cleanup_notification_outbox() from public, anon, authenticated;
revoke all on function public.invoke_notify() from public, anon, authenticated;
grant execute on function public.claim_notification_outbox(integer) to service_role;
grant execute on function public.retry_notification_outbox(uuid[], text, integer) to service_role;

select cron.schedule('notify-outbox', '* * * * *', 'select public.invoke_notify()');
select cron.schedule('notify-outbox-cleanup', '37 3 * * *', 'select public.cleanup_notification_outbox()');
