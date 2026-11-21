-- squawk-ignore-file prefer-robust-stmts, require-concurrent-index-creation
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the tables,
-- indexes and functions are created here on tables that do not exist yet, so nothing is re-run and
-- no write can be blocked.
-- 0015_push_notifications: tables for push notifications (P6b-T02, ADR-13, plan §7 P6b).
--
--   * device_tokens: one row per FCM token (unique), owned by one account. Clients may only READ
--     their own rows. Register / unregister go through the two RPCs below (security definer),
--     because a token can move to another account on a shared device, which row-level security on
--     the table could not allow, and because clients have no delete grant anywhere (rls_coverage).
--     Per account the newest 20 tokens are kept.
--   * notification_prefs: per account and group; level all (default when no row) / mine / none,
--     optional quiet hours {start 'HH:MM', end 'HH:MM', utc_offset_minutes}, hide_amounts for a
--     generic lock-screen body. Own rows only, select / insert / update; "reset" = write all.
--   * notification_outbox: written only by the trigger of 0016 and read only by the `notify` Edge
--     Function (service role). RLS is enabled and there is no policy and no grant, so anon and
--     authenticated have no access at all.
--
-- Both group references cascade, so the inactive-group cleanup (0014) can delete a group without
-- knowing about these tables.
-- delete_account_data (0010) already deletes device_tokens and notification_prefs rows of an
-- account; the foreign keys to auth.users cascade as a second line of defence.

set lock_timeout = '1s';
set statement_timeout = '5s';

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique check (char_length(token) between 1 and 4096),
  platform text not null check (platform in ('android', 'ios')),
  locale text not null default 'en' check (char_length(locale) between 2 and 35),
  app_version text check (char_length(app_version) <= 50),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index device_tokens_user_id on public.device_tokens (user_id, last_seen_at desc);

create table public.notification_prefs (
  user_id uuid not null references auth.users (id) on delete cascade,
  group_id uuid not null references public.groups (id) on delete cascade,
  level text not null default 'all' check (level in ('all', 'mine', 'none')),
  quiet_hours jsonb check (
    jsonb_typeof(quiet_hours) = 'object' and octet_length(quiet_hours::text) <= 200),
  hide_amounts boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, group_id)
);

create index notification_prefs_group_id on public.notification_prefs (group_id);

-- dedupe_key makes the trigger idempotent: one row per logical change (see 0016).
-- processed_at is set by the Edge Function when it claimed the row (SKIP LOCKED).
create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  actor_user_id uuid,
  event text not null check (event in (
    'expense_added', 'expense_changed', 'expense_deleted', 'settlement_added', 'member_joined')),
  entity_id uuid not null,
  payload jsonb not null default '{}' check (octet_length(payload::text) <= 8192),
  dedupe_key text not null unique check (char_length(dedupe_key) <= 200),
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

-- The claim query: oldest unprocessed first.
create index notification_outbox_pending on public.notification_outbox (created_at)
  where processed_at is null;
create index notification_outbox_group_id on public.notification_outbox (group_id);

alter table public.device_tokens enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.notification_outbox enable row level security;

grant select on public.device_tokens to authenticated;
create policy device_tokens_select on public.device_tokens for select to authenticated
  using (user_id = (select auth.uid()));

grant select, insert, update on public.notification_prefs to authenticated;
create policy notification_prefs_select on public.notification_prefs for select to authenticated
  using (user_id = (select auth.uid()));
create policy notification_prefs_insert on public.notification_prefs for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_group_member(group_id));
create policy notification_prefs_update on public.notification_prefs for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_group_member(group_id));

-- notification_outbox: deliberately no grant and no policy.

-- ---------------------------------------------------------------------------
-- RPCs. SECURITY DEFINER because they write device_tokens, where clients have no write grant. Each
-- needs a signed-in caller (42501 otherwise) and only ever touches rows of auth.uid().
-- ---------------------------------------------------------------------------
create function public.register_device_token(
  p_token text, p_platform text, p_locale text default 'en', p_app_version text default null
) returns void
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
  if p_token is null or char_length(p_token) not between 1 and 4096
     or p_platform is null or p_platform not in ('android', 'ios')
     or p_locale is null or char_length(p_locale) not between 2 and 35
     or char_length(p_app_version) > 50 then
    raise exception 'invalid_token' using errcode = 'check_violation';
  end if;

  -- A token that already belongs to someone else (shared device, no sign-out) moves to the caller.
  insert into public.device_tokens (user_id, token, platform, locale, app_version)
  values (v_uid, p_token, p_platform, p_locale, p_app_version)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, locale = excluded.locale,
        app_version = excluded.app_version, last_seen_at = now();

  -- Keep the newest 20 tokens per account.
  delete from public.device_tokens t
  where t.user_id = v_uid
    and t.id in (
      select o.id from public.device_tokens o
      where o.user_id = v_uid
      order by o.last_seen_at desc, o.id
      offset 20);
end;
$$;

create function public.unregister_device_token(p_token text) returns void
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
  delete from public.device_tokens t where t.token = p_token and t.user_id = v_uid;
end;
$$;

revoke all on function public.register_device_token(text, text, text, text) from public, anon;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text, text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;
