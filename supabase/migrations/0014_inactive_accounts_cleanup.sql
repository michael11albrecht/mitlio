-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the functions
-- are created or replaced (same signature) here and the cron job is scheduled by name (idempotent).
-- 0014_inactive_accounts_cleanup: retention for anonymous accounts and orphaned groups (#188;
-- docs/retention.md, docs/data-deletion.md).
--
-- The period comes from supabase/retention.json (inactive_account_months = 13).
-- web/tests/retention.spec.ts fails when they drift.
--
-- Rules, applied once a day by pg_cron:
--   1. An ANONYMOUS account (auth.users.is_anonymous) with no activity for 13 months is deleted with
--      exactly the semantics of "Alle meine Daten löschen": public.delete_account_data(uid), which
--      0010's delete_my_data() did inline and which now lives in one place so the user-triggered and
--      the automatic path cannot drift. Non-anonymous users are never touched.
--   2. A group with no linked account left (no group_memberships row) and all its rows are deleted.
--      Nobody can open such a group any more, so keeping it only keeps other people's names and amounts
--      for nothing. A group younger than one day is skipped: the client creates the group row and its
--      first membership in two calls, and the job must not catch a group between them.
--
-- Activity signal (decision): the latest of
--   * auth.users.last_sign_in_at (set when the anonymous account is created / signs in),
--   * auth.users.created_at (fallback when the above is null),
--   * auth.refresh_tokens.created_at / updated_at of the user (every token refresh of a running app
--     rotates the refresh token, so an app that is opened and syncs at least once per access-token
--     lifetime shows up here; this is the only per-user "the app talked to the server" trace, because
--     group rows carry no author column).
-- A group edit by someone else does not keep a dormant account alive. refresh_tokens.user_id is
-- compared as text because its column type differs between Supabase Auth versions.
--
-- delete_account_data(uid) is internal: no client may call it (acting for an arbitrary uid), only
-- delete_my_data() (uid = auth.uid()) and the cleanup job (security definer, owner role) do.
-- Idempotent: a second call finds nothing left.

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

  with d as (delete from auth.users au where au.id = p_uid returning 1)
  select count(*) into v_auth from d;

  return jsonb_build_object(
    'memberships_deleted', v_memberships,
    'members_unlinked', v_members,
    'device_tokens_deleted', v_tokens,
    'notification_prefs_deleted', v_prefs,
    'auth_user_deleted', v_auth > 0);
end;
$$;
revoke all on function public.delete_account_data(uuid) from public, anon, authenticated;

-- Same behaviour as 0010; only the body moved into delete_account_data.
create or replace function public.delete_my_data() returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'insufficient_privilege';
  end if;
  return public.delete_account_data(v_uid);
end;
$$;
revoke all on function public.delete_my_data() from public;
revoke all on function public.delete_my_data() from anon;
grant execute on function public.delete_my_data() to authenticated;

create or replace function public.cleanup_inactive_accounts() returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_gids uuid[];
begin
  for v_uid in
    select au.id
    from auth.users au
    where au.is_anonymous
      and greatest(
            coalesce(au.last_sign_in_at, au.created_at),
            au.created_at,
            (select max(greatest(rt.created_at, rt.updated_at))
             from auth.refresh_tokens rt where rt.user_id::text = au.id::text))
          < now() - interval '13 months'
  loop
    perform public.delete_account_data(v_uid);
  end loop;

  select array_agg(g.id) into v_gids
  from public.groups g
  where g.created_at < now() - interval '1 day'
    and not exists (select 1 from public.group_memberships gm where gm.group_id = g.id);

  if v_gids is not null then
    delete from public.rides where group_id = any (v_gids);
    delete from public.ride_templates where group_id = any (v_gids);
    delete from public.expense_revisions where group_id = any (v_gids);
    delete from public.expense_payers where group_id = any (v_gids);
    delete from public.expense_shares where group_id = any (v_gids);
    delete from public.settlements where group_id = any (v_gids);
    delete from public.expenses where group_id = any (v_gids);
    delete from public.vehicles where group_id = any (v_gids);
    delete from public.group_join_audit where group_id = any (v_gids);
    delete from public.group_invites where group_id = any (v_gids);
    delete from public.members where group_id = any (v_gids);
    delete from public.groups where id = any (v_gids);
  end if;
end;
$$;
revoke all on function public.cleanup_inactive_accounts() from public, anon, authenticated;

select cron.schedule('inactive-accounts-cleanup', '47 3 * * *', 'select public.cleanup_inactive_accounts()');
