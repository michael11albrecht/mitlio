-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the functions
-- are created or replaced (same signature) here and the cron job is scheduled by name (idempotent).
-- 0017_auth_audit_purge: Auth audit rows of a deleted account, and a daily purge as a safety net (#206).
--
-- Supabase Auth writes auth.audit_log_entries (user id in the JSON payload) on every token refresh and
-- logout. The table has no foreign key to auth.users, so rows outlive the account. The owner switches
-- off writing it to the database (supabase/README.md); this migration covers the rest:
--   1. delete_account_data(uid) (so "Alle meine Daten löschen" and the 13-month cleanup) also deletes
--      the user's audit rows. Same body as 0014 plus the audit step; skipped when the table does not
--      exist, a warning (not a silent skip) when it is not accessible.
--   2. cleanup_auth_audit_log(), daily by pg_cron, deletes audit rows older than 7 days
--      (supabase/retention.json auth_audit_days = 7, same as the platform log period).
--      web/tests/retention.spec.ts fails when they drift. A no-op when the table is empty or absent.

set lock_timeout = '1s';
set statement_timeout = '5s';

create or replace function public.delete_account_data(p_uid uuid) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owned uuid[];
  v_memberships bigint;
  v_members bigint;
  v_tokens bigint := 0;
  v_prefs bigint := 0;
  v_audit bigint := 0;
  v_auth bigint;
begin
  select array_agg(mine.group_id) into v_owned
  from public.group_memberships mine
  where mine.user_id = p_uid and mine.role = 'owner';

  -- The membership rows reference members (member_id), so they go before anything else.
  with d as (delete from public.group_memberships gm where gm.user_id = p_uid returning 1)
  select count(*) into v_memberships from d;

  update public.group_memberships gm set role = 'owner'
  where gm.id in (
    select distinct on (o.group_id) o.id
    from public.group_memberships o
    where o.group_id = any (coalesce(v_owned, '{}'))
    order by o.group_id, o.created_at, o.id);

  -- Non-authoritative display link; the trigger bumps server_seq so peers pull the change.
  with u as (
    update public.members m set user_id = null where m.user_id = p_uid returning 1)
  select count(*) into v_members from u;

  if to_regclass('public.device_tokens') is not null then
    execute 'with d as (delete from public.device_tokens t where t.user_id = $1 returning 1)
             select count(*) from d' into v_tokens using p_uid;
  end if;
  if to_regclass('public.notification_prefs') is not null then
    execute 'with d as (delete from public.notification_prefs t where t.user_id = $1 returning 1)
             select count(*) from d' into v_prefs using p_uid;
  end if;

  -- Auth's audit log has no foreign key to auth.users and survives the delete below (#206). The user id is
  -- in the JSON payload (actor_id for the user's own events, traits.user_id for events about the user).
  -- Dynamic SQL: the table is Supabase-managed; skip it when absent, and say so when it is not accessible.
  if to_regclass('auth.audit_log_entries') is not null then
    begin
      execute $q$with d as (delete from auth.audit_log_entries e
                            where e.payload->>'actor_id' = $1 or e.payload->'traits'->>'user_id' = $1
                            returning 1)
                 select count(*) from d$q$ into v_audit using p_uid::text;
    exception when insufficient_privilege then
      raise warning 'delete_account_data: auth.audit_log_entries not accessible, audit rows of % kept', p_uid;
    end;
  end if;

  with d as (delete from auth.users au where au.id = p_uid returning 1)
  select count(*) into v_auth from d;

  return jsonb_build_object(
    'memberships_deleted', v_memberships,
    'members_unlinked', v_members,
    'device_tokens_deleted', v_tokens,
    'notification_prefs_deleted', v_prefs,
    'auth_audit_entries_deleted', v_audit,
    'auth_user_deleted', v_auth > 0);
end;
$$;
revoke all on function public.delete_account_data(uuid) from public, anon, authenticated;

create or replace function public.cleanup_auth_audit_log() returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if to_regclass('auth.audit_log_entries') is null then
    return;
  end if;
  begin
    execute $q$delete from auth.audit_log_entries where created_at < now() - interval '7 days'$q$;
  exception when insufficient_privilege then
    raise warning 'cleanup_auth_audit_log: auth.audit_log_entries not accessible, nothing purged';
  end;
end;
$$;
revoke all on function public.cleanup_auth_audit_log() from public, anon, authenticated;

select cron.schedule('auth-audit-cleanup', '17 3 * * *', 'select public.cleanup_auth_audit_log()');
