-- 0003_invites: create / revoke / join via invite token (P6-T05, plan §8).
--
-- Security model:
--   * The token is 32 random bytes (base64url, 43 chars). Only sha256(token) is stored; the
--     plaintext is returned once by create_invite and never persisted or logged.
--   * group_invites has no insert/update grant for clients, group_memberships only the bootstrap
--     insert. All three functions below are therefore SECURITY DEFINER with search_path = '' and
--     each gates itself on auth.uid() / is_group_member() as its first action. anon/PUBLIC have no
--     EXECUTE (deny by default).
--   * Invalid, unknown, expired and revoked tokens are indistinguishable ('invite_invalid',
--     SQLSTATE 22023) so the function is not an oracle.
--
-- Errors: 42501 not authenticated / not a member; 22023 invite_invalid, member_not_found;
--   23505 member_already_claimed; 23514 membership_already_linked.
--
-- Rate limiting (documented, NOT implemented here): the token has 256 bits of entropy, so online
-- guessing is infeasible; the realistic abuse is hammering join_group/create_invite. Planned
-- mitigation is at the edge (Supabase/PostgREST rate limits per IP and per user, auth rate limits
-- for anonymous sign-ins); if needed later, add a per-user attempt counter table checked in
-- join_group.

set lock_timeout = '1s';
set statement_timeout = '5s';

create extension if not exists pgcrypto with schema extensions;

-- Members only. Returns the plaintext token once.
create function public.create_invite(gid uuid) returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token text;
begin
  if not public.is_group_member(gid) then
    raise exception 'not a member of this group' using errcode = 'insufficient_privilege';
  end if;
  v_token := rtrim(translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'), '=');
  insert into public.group_invites (group_id, token_hash, created_by, expires_at)
  values (gid, sha256(convert_to(v_token, 'UTF8')), (select auth.uid()), now() + interval '7 days');
  return v_token;
end;
$$;

-- Members only; idempotent. Unknown invite and foreign invite look the same (42501).
create function public.revoke_invite(invite_id uuid) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_gid uuid;
begin
  select gi.group_id into v_gid from public.group_invites gi where gi.id = invite_id;
  if v_gid is null or not public.is_group_member(v_gid) then
    raise exception 'not a member of this group' using errcode = 'insufficient_privilege';
  end if;
  update public.group_invites gi set revoked_at = coalesce(gi.revoked_at, now())
  where gi.id = invite_id;
end;
$$;

-- Validates the token, adds the caller to the group, optionally claims an unclaimed member.
-- Joining again with the same token is idempotent (returns the existing membership).
create function public.join_group(token text, claim_member_id uuid default null) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_invite public.group_invites;
  v_mem public.group_memberships;
  v_member public.members;
  v_already boolean := false;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'insufficient_privilege';
  end if;

  select gi.* into v_invite
  from public.group_invites gi
  join public.groups g on g.id = gi.group_id
  where gi.token_hash = sha256(convert_to(coalesce(token, ''), 'UTF8'))
    and gi.revoked_at is null
    and gi.expires_at > now()
    and g.deleted_at is null;
  if not found then
    raise exception 'invite_invalid' using errcode = 'invalid_parameter_value';
  end if;

  select gm.* into v_mem
  from public.group_memberships gm
  where gm.group_id = v_invite.group_id and gm.user_id = v_uid
  for update;

  if found then
    if claim_member_id is null or v_mem.member_id = claim_member_id then
      v_already := true;
    elsif v_mem.member_id is not null then
      raise exception 'membership_already_linked' using errcode = 'check_violation';
    end if;
  end if;

  if not v_already and claim_member_id is not null then
    select m.* into v_member
    from public.members m
    where m.id = claim_member_id and m.group_id = v_invite.group_id and m.deleted_at is null
    for update;
    if not found then
      raise exception 'member_not_found' using errcode = 'invalid_parameter_value';
    end if;
    if v_member.user_id is not null or exists (
      select 1 from public.group_memberships gm
      where gm.group_id = v_invite.group_id and gm.member_id = claim_member_id
    ) then
      raise exception 'member_already_claimed' using errcode = 'unique_violation';
    end if;
    -- user_id is non-authoritative display data; the trigger bumps server_seq so peers pull it.
    update public.members m set user_id = v_uid where m.id = claim_member_id;
  end if;

  if not v_already then
    if v_mem.id is not null then
      update public.group_memberships gm set member_id = claim_member_id
      where gm.id = v_mem.id returning gm.* into v_mem;
    else
      insert into public.group_memberships (group_id, user_id, member_id)
      values (v_invite.group_id, v_uid, claim_member_id)
      returning * into v_mem;
    end if;
  end if;

  return jsonb_build_object(
    'group_id', v_mem.group_id,
    'membership_id', v_mem.id,
    'member_id', v_mem.member_id,
    'already_member', v_already);
end;
$$;

revoke all on function public.create_invite(uuid) from public;
revoke all on function public.revoke_invite(uuid) from public;
revoke all on function public.join_group(text, uuid) from public;
revoke all on function public.create_invite(uuid) from anon;
revoke all on function public.revoke_invite(uuid) from anon;
revoke all on function public.join_group(text, uuid) from anon;
grant execute on function public.create_invite(uuid) to authenticated;
grant execute on function public.revoke_invite(uuid) to authenticated;
grant execute on function public.join_group(text, uuid) to authenticated;
