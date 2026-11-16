-- squawk-ignore-file prefer-robust-stmts
-- 0012_app_config: server-side minimum app version and a retry hint on the join rate limit (P6-T16a, ADR-27).
--
--   * app_config: one row per store platform. The app reads min_supported_version before it syncs and
--     stops syncing when it is older (ADR-27 §2.3). Readable by anon AND authenticated because the
--     gate must work before sign-in (same public-read pattern as fuel_price_cache, 0005). No write
--     grant and no write policy for client roles; the owner edits rows in the SQL editor.
--     Seeded with 0.0.0 (blocks nobody); store_url stays null until the owner sets it.
--   * join_group: replaced with `create or replace` (same signature). Body identical to 0009 except the
--     P0429 raise now carries hint = 'retry_after_seconds=<n>' so the app can say when to retry.
set lock_timeout = '1s';
set statement_timeout = '5s';

create table if not exists public.app_config (
  platform text primary key check (platform in ('ios', 'android')),
  min_supported_version text not null check (min_supported_version ~ '^\d+\.\d+\.\d+$'),
  store_url text,
  updated_at timestamptz not null default now()
);
alter table public.app_config enable row level security;
revoke all on public.app_config from anon, authenticated;
grant select on public.app_config to anon, authenticated;
grant select, insert, update, delete on public.app_config to service_role;
create policy app_config_public_read on public.app_config
  for select to anon, authenticated using (true);

insert into public.app_config (platform, min_supported_version) values
  ('ios', '0.0.0'),
  ('android', '0.0.0')
on conflict (platform) do nothing;

-- Same body as 0009; only the P0429 raise gains a retry hint.
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
    -- One token refills every 360 s (10/hour). The bucket state is not read here, so 360 is the
    -- worst case wait until the next attempt is allowed.
    raise exception 'rate_limited' using errcode = 'P0429', hint = 'retry_after_seconds=360';
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

