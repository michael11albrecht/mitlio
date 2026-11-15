-- squawk-ignore-file prefer-robust-stmts, require-concurrent-index-creation
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the table
-- and its indexes are created here on a table that does not exist yet, so nothing is re-run and
-- no write can be blocked. join_group is replaced with `create or replace` (same signature).
-- 0009_join_hardening: invite abuse hardening for join_group (#89).
--
-- Changes:
--   * Per-user rate limit inside join_group: a token bucket (public.consume_rate_limit, 0005)
--     keyed 'join:' || hex(sha256(auth.uid())), capacity 10, refill 10 per hour. Consumed before
--     the token lookup, so valid, idempotent and invalid attempts all cost one token. When empty
--     the call raises 'rate_limited' with SQLSTATE P0429 (distinct from every other error).
--     Caveat: an attempt that raises (invalid token, claim errors) aborts the surrounding
--     transaction, which also rolls back its own token consumption; Postgres has no autonomous
--     transaction. The limit therefore bounds attempts that complete; see the PR for the
--     follow-up options.
--   * public.group_join_audit: one row per successful join that changed membership (new
--     membership or a claim on an existing unlinked one); an idempotent repeat writes none.
--     Group members may select; clients have no insert/update/delete grant and no such policy
--     (rls_coverage keeps it that way). Only join_group (SECURITY DEFINER) writes it.
--     user_id cascades with auth.users, so delete_my_data (0008) removes the user's audit rows.
--
-- Errors (unchanged from 0003): 42501 not authenticated; 22023 invite_invalid, member_not_found;
--   23505 member_already_claimed; 23514 membership_already_linked. New: P0429 rate_limited.

set lock_timeout = '1s';
set statement_timeout = '5s';

create table public.group_join_audit (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- The member the joiner claimed, if any.
  member_id uuid,
  joined_at timestamptz not null default now(),
  foreign key (member_id, group_id) references public.members (id, group_id)
);

create index group_join_audit_group_id on public.group_join_audit (group_id);
create index group_join_audit_user_id on public.group_join_audit (user_id);
create index group_join_audit_member_id on public.group_join_audit (member_id);

alter table public.group_join_audit enable row level security;
grant select on public.group_join_audit to authenticated;
create policy group_join_audit_select on public.group_join_audit for select to authenticated
  using (public.is_group_member(group_id));

-- Same body as 0003 plus the rate limit and the audit insert.
create or replace function public.join_group(token text, claim_member_id uuid default null)
returns jsonb
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

  -- 10 attempts per hour per user. The key is a hash so no user id sits in rate_limits.
  if not public.consume_rate_limit(
    'join:' || encode(sha256(convert_to(v_uid::text, 'UTF8')), 'hex'), 10, 10.0 / 3600.0
  ) then
    raise exception 'rate_limited' using errcode = 'P0429';
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

    insert into public.group_join_audit (group_id, user_id, member_id)
    values (v_mem.group_id, v_uid, v_mem.member_id);
  end if;

  return jsonb_build_object(
    'group_id', v_mem.group_id,
    'membership_id', v_mem.id,
    'member_id', v_mem.member_id,
    'already_member', v_already);
end;
$$;

revoke all on function public.join_group(text, uuid) from public;
revoke all on function public.join_group(text, uuid) from anon;
grant execute on function public.join_group(text, uuid) to authenticated;
