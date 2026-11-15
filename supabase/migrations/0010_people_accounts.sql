-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction. Functions are
-- replaced with `create or replace` (same signatures); the new column has a constant default.
-- 0010_people_accounts: server side of ADR-24 (people vs. accounts, one rotating invite link,
-- owner role). Amends P6-T04/T05 (0001, 0003); supersedes the group lock idea of #89.
--
-- Changes:
--   * group_memberships.role in ('owner','member'), server-authoritative. Backfill: the oldest
--     membership of each group (created_at, then id) becomes 'owner'. A BEFORE INSERT trigger
--     (SECURITY DEFINER, so it sees all rows regardless of RLS) forces role = 'owner' iff the group
--     has no membership yet (the bootstrap case) and 'member' otherwise, ignoring the client value.
--     Clients have no UPDATE grant on group_memberships, so they cannot change a role afterwards.
--     `unique (group_id, user_id)` and `unique (group_id, member_id)` stay (one account per person;
--     several accounts per person is tbd, see ADR-24).
--   * create_invite(gid): owner only. Revokes every other active invite of the group in the same
--     transaction (creating a new link is the kill switch for a leaked one). Links no longer expire
--     (expires_at = 'infinity'), so join_group's `expires_at > now()` check keeps working unchanged.
--     join_group itself (0009: rate limit, audit, member_already_claimed) is not changed.
--   * revoke_invite(invite_id): owner only.
--   * connect_member(gid, member_id): a member of gid connects their own membership to a person
--     after joining, with the same rules as the claim in join_group. Writes a group_join_audit row.
--   * remove_membership(membership_id): owner only, never the owner's own membership. Deletes the
--     membership (access ends); the person row and all expenses stay. If members.user_id of that
--     person equals the removed user it is set to null.
--   * delete_my_data(): same as 0008, but if the caller owns a group, ownership passes to the oldest
--     remaining membership of that group before the caller's memberships are deleted.
--
-- Security model: all functions SECURITY DEFINER, search_path = '', fully qualified, gated on
-- auth.uid() first. anon/PUBLIC have no EXECUTE.
--
-- Errors: 42501 not authenticated / not a member / not the owner (also for unknown ids);
--   22023 invite_invalid, member_not_found; 23505 member_already_claimed;
--   23514 membership_already_linked, cannot remove own membership. join_group: P0429 rate_limited.

set lock_timeout = '1s';
set statement_timeout = '5s';

alter table public.group_memberships
  add column role text not null default 'member' check (role in ('owner', 'member'));

update public.group_memberships gm set role = 'owner'
where gm.id in (
  select distinct on (g.group_id) g.id
  from public.group_memberships g
  order by g.group_id, g.created_at, g.id);

create function public.set_membership_role() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.group_memberships gm where gm.group_id = new.group_id) then
    new.role := 'member';
  else
    new.role := 'owner';
  end if;
  return new;
end;
$$;

revoke all on function public.set_membership_role() from public;

create trigger set_membership_role before insert on public.group_memberships
  for each row execute function public.set_membership_role();

-- Owner only. Returns the plaintext token once; all other active invites of the group are revoked.
create or replace function public.create_invite(gid uuid) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_token text;
begin
  if v_uid is null or not exists (
    select 1 from public.group_memberships gm
    where gm.group_id = gid and gm.user_id = v_uid and gm.role = 'owner'
  ) then
    raise exception 'not the owner of this group' using errcode = 'insufficient_privilege';
  end if;
  update public.group_invites gi set revoked_at = now()
  where gi.group_id = gid and gi.revoked_at is null;
  v_token := rtrim(translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'), '=');
  insert into public.group_invites (group_id, token_hash, created_by, expires_at)
  values (gid, sha256(convert_to(v_token, 'UTF8')), v_uid, 'infinity');
  return v_token;
end;
$$;

-- Owner only; idempotent. Unknown invite and foreign invite look the same (42501).
create or replace function public.revoke_invite(invite_id uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_gid uuid;
begin
  select gi.group_id into v_gid from public.group_invites gi where gi.id = invite_id;
  if v_uid is null or v_gid is null or not exists (
    select 1 from public.group_memberships gm
    where gm.group_id = v_gid and gm.user_id = v_uid and gm.role = 'owner'
  ) then
    raise exception 'not the owner of this group' using errcode = 'insufficient_privilege';
  end if;
  update public.group_invites gi set revoked_at = coalesce(gi.revoked_at, now())
  where gi.id = invite_id;
end;
$$;

-- Connects the caller's own membership in gid to a person (same rules as the claim in join_group).
-- Repeating the same connection is idempotent and writes no audit row.
create function public.connect_member(gid uuid, member_id uuid) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_mem public.group_memberships;
  v_member public.members;
  v_already boolean := false;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'insufficient_privilege';
  end if;

  select gm.* into v_mem
  from public.group_memberships gm
  where gm.group_id = gid and gm.user_id = v_uid
  for update;
  if not found then
    raise exception 'not a member of this group' using errcode = 'insufficient_privilege';
  end if;

  if v_mem.member_id = connect_member.member_id then
    v_already := true;
  elsif v_mem.member_id is not null then
    raise exception 'membership_already_linked' using errcode = 'check_violation';
  else
    select m.* into v_member
    from public.members m
    where m.id = connect_member.member_id and m.group_id = gid and m.deleted_at is null
    for update;
    if not found then
      raise exception 'member_not_found' using errcode = 'invalid_parameter_value';
    end if;
    if v_member.user_id is not null or exists (
      select 1 from public.group_memberships gm
      where gm.group_id = gid and gm.member_id = connect_member.member_id
    ) then
      raise exception 'member_already_claimed' using errcode = 'unique_violation';
    end if;
    -- user_id is non-authoritative display data; the trigger bumps server_seq so peers pull it.
    update public.members m set user_id = v_uid where m.id = connect_member.member_id;
    update public.group_memberships gm set member_id = connect_member.member_id
    where gm.id = v_mem.id returning gm.* into v_mem;
    insert into public.group_join_audit (group_id, user_id, member_id)
    values (v_mem.group_id, v_uid, v_mem.member_id);
  end if;

  return jsonb_build_object(
    'group_id', v_mem.group_id,
    'membership_id', v_mem.id,
    'member_id', v_mem.member_id,
    'already_connected', v_already);
end;
$$;

-- Owner only; never the owner's own membership. The person and their expenses stay.
create function public.remove_membership(membership_id uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_mem public.group_memberships;
begin
  select gm.* into v_mem
  from public.group_memberships gm
  where gm.id = membership_id
  for update;
  if v_uid is null or not found or not exists (
    select 1 from public.group_memberships gm
    where gm.group_id = v_mem.group_id and gm.user_id = v_uid and gm.role = 'owner'
  ) then
    raise exception 'not the owner of this group' using errcode = 'insufficient_privilege';
  end if;
  if v_mem.user_id = v_uid then
    raise exception 'cannot remove own membership' using errcode = 'check_violation';
  end if;

  delete from public.group_memberships gm where gm.id = v_mem.id;
  if v_mem.member_id is not null then
    update public.members m set user_id = null
    where m.id = v_mem.member_id and m.user_id = v_mem.user_id;
  end if;
end;
$$;

-- Same as 0008, plus: groups the caller owns pass to their oldest remaining membership first.
create or replace function public.delete_my_data() returns jsonb
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

  update public.group_memberships gm set role = 'owner'
  where gm.id in (
    select distinct on (o.group_id) o.id
    from public.group_memberships o
    where o.user_id <> v_uid
      and o.group_id in (
        select mine.group_id from public.group_memberships mine
        where mine.user_id = v_uid and mine.role = 'owner')
    order by o.group_id, o.created_at, o.id);

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

revoke all on function public.create_invite(uuid) from public;
revoke all on function public.revoke_invite(uuid) from public;
revoke all on function public.connect_member(uuid, uuid) from public;
revoke all on function public.remove_membership(uuid) from public;
revoke all on function public.delete_my_data() from public;
revoke all on function public.create_invite(uuid) from anon;
revoke all on function public.revoke_invite(uuid) from anon;
revoke all on function public.connect_member(uuid, uuid) from anon;
revoke all on function public.remove_membership(uuid) from anon;
revoke all on function public.delete_my_data() from anon;
grant execute on function public.create_invite(uuid) to authenticated;
grant execute on function public.revoke_invite(uuid) to authenticated;
grant execute on function public.connect_member(uuid, uuid) to authenticated;
grant execute on function public.remove_membership(uuid) to authenticated;
grant execute on function public.delete_my_data() to authenticated;
