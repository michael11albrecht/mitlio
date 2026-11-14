-- 0008_delete_my_data: "delete my data" on the server (P7-T07, plan §7 P7 row T07, §8).
--
-- public.delete_my_data() acts for auth.uid() only and returns a jsonb report of what it removed.
--
-- What is removed for the caller:
--   * their group_memberships (so they lose access to every group, is_group_member() turns false),
--   * the link members.user_id (set to null on the rows that pointed at them; the member rows
--     themselves stay, see below),
--   * their device_tokens and notification_prefs rows, if those tables exist yet (P6b adds them;
--     checked with to_regclass so this migration works before and after P6b),
--   * their auth.users row. group_invites.created_by cascades with it, sessions and identities are
--     removed by Supabase Auth's own foreign keys. Done from SQL because the function is owned by
--     the migration role, which can delete from auth.users on Supabase; the report says
--     'auth_user_deleted': true. If a deployment ever forbids that, change the one DELETE below to
--     a flag and add an Edge Function with the service role as follow-up (docs/data-deletion.md).
--
-- What deliberately stays: group data shared with other people (groups, members, expenses,
-- settlements, rides, revisions). It belongs to the group, not to one person; deleting it would
-- destroy the other members' records and balances. Members that were linked to the caller remain
-- as plain names without a user link, and groups.created_by keeps an id that no longer resolves
-- to anyone. The caller's own device wipes its local copy (app side of the same task).
--
-- Security model: SECURITY DEFINER with search_path = '' and everything schema-qualified, gated on
-- auth.uid() as the first action. anon/PUBLIC have no EXECUTE (deny by default); anon calls fail
-- with 42501 (not authenticated).
--
-- Idempotent: a second call finds nothing left and returns zero counts with
-- 'auth_user_deleted': false.
--
-- Errors: 42501 not authenticated.

set lock_timeout = '1s';
set statement_timeout = '5s';

create function public.delete_my_data() returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_memberships bigint;
  v_members bigint;
  v_tokens bigint := 0;
  v_prefs bigint := 0;
  v_auth bigint;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'insufficient_privilege';
  end if;

  -- The membership rows reference members (member_id), so they go before anything else.
  with d as (delete from public.group_memberships gm where gm.user_id = v_uid returning 1)
  select count(*) into v_memberships from d;

  -- Non-authoritative display link; the trigger bumps server_seq so peers pull the change.
  with u as (
    update public.members m set user_id = null where m.user_id = v_uid returning 1)
  select count(*) into v_members from u;

  if to_regclass('public.device_tokens') is not null then
    execute 'with d as (delete from public.device_tokens t where t.user_id = $1 returning 1)
             select count(*) from d' into v_tokens using v_uid;
  end if;
  if to_regclass('public.notification_prefs') is not null then
    execute 'with d as (delete from public.notification_prefs t where t.user_id = $1 returning 1)
             select count(*) from d' into v_prefs using v_uid;
  end if;

  with d as (delete from auth.users au where au.id = v_uid returning 1)
  select count(*) into v_auth from d;

  return jsonb_build_object(
    'memberships_deleted', v_memberships,
    'members_unlinked', v_members,
    'device_tokens_deleted', v_tokens,
    'notification_prefs_deleted', v_prefs,
    'auth_user_deleted', v_auth > 0);
end;
$$;

revoke all on function public.delete_my_data() from public;
revoke all on function public.delete_my_data() from anon;
grant execute on function public.delete_my_data() to authenticated;
