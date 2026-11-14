-- squawk-ignore-file prefer-robust-stmts, require-concurrent-index-creation, require-lock-timeout, require-statement-timeout
-- Justification for the ignores above: this is the first migration. Every table and index is created
-- here on an empty database in one run (the Supabase CLI applies a migration file exactly once, in a
-- transaction), so idempotent statements, CONCURRENTLY and lock/statement timeouts protect nothing.
-- Later migrations that touch existing tables must NOT copy these ignores.
-- 0001_core: server schema (plan §2.4) + deny-by-default RLS (plan §8). P6-T02, P6-T03.
--
-- Rules this migration enforces:
--   * Server tables mirror the client Drift schema (app/lib/db/tables.dart, v2) with
--     snake_case names, uuid keys, bigint money, jsonb for JSON text columns.
--   * NO IBAN COLUMNS. Full IBANs are local-only (plan §8). `members.iban_hint` is a masked
--     hint only and is length-capped so it cannot hold a real IBAN (min length 15).
--   * RLS is enabled on every table; anon gets no privileges at all; authenticated gets only
--     select/insert/update (never delete: soft delete via `deleted_at`).
--   * Group membership is the only authorization source: public.group_memberships.
--   * Tables with `server_seq` get it from one global sequence via trigger (pull cursor).
--   * `updated_at` is an HLC string; updates may not move it backwards (LWW guard).

-- ---------------------------------------------------------------------------
-- Deny by default: strip implicit Supabase grants for client roles, now and for
-- tables created by later migrations. Each table below grants explicitly.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Global change cursor + trigger functions
-- ---------------------------------------------------------------------------
create sequence public.server_seq_seq as bigint;

-- security definer: client roles have no privilege on the sequence.
create function public.set_server_seq() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.server_seq := nextval('public.server_seq_seq');
  return new;
end;
$$;

-- LWW guard: id is immutable and `updated_at` (HLC, fixed-width, compared bytewise) must not
-- go backwards. Equal values are allowed so replays are idempotent.
create function public.enforce_lww() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id then
    raise exception 'id is immutable' using errcode = 'check_violation';
  end if;
  if new.updated_at collate "C" < old.updated_at collate "C" then
    raise exception 'updated_at must not go backwards (% < %)', new.updated_at, old.updated_at
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

-- A row never moves between groups (RLS would otherwise let a member of two groups do it).
create function public.enforce_group_id_immutable() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.group_id is distinct from old.group_id then
    raise exception 'group_id is immutable' using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

revoke all on function public.set_server_seq() from public;
revoke all on function public.enforce_lww() from public;
revoke all on function public.enforce_group_id_immutable() from public;

-- ---------------------------------------------------------------------------
-- Tables
-- Free text is capped at 500 chars (cheap abuse limit); currency is ISO 4217 upper case.
-- Composite (id, group_id) uniques let child tables prove "same group" with a foreign key.
-- ---------------------------------------------------------------------------
create table public.groups (
  id uuid primary key,
  name text not null check (char_length(name) <= 500),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  created_by uuid not null,
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null
);

create table public.members (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  name text not null check (char_length(name) <= 500),
  position bigint not null,
  paypal_me text check (char_length(paypal_me) <= 500),
  -- Not authorization data: group_memberships is. Set by the join RPC (P6-T05).
  user_id uuid,
  -- Masked hint only (e.g. 'DE89 …3000'). Capped below the shortest real IBAN (15).
  iban_hint text check (char_length(iban_hint) <= 14),
  unique (id, group_id)
);

create table public.expenses (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  title text not null check (char_length(title) <= 500),
  amount_cents bigint not null check (amount_cents > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  -- Frozen FX rate in parts per million (1_000_000 == same currency).
  fx_rate_ppm bigint not null check (fx_rate_ppm > 0),
  group_amount_cents bigint not null check (group_amount_cents > 0),
  date timestamptz not null,
  category text check (char_length(category) <= 500),
  type text not null check (type in ('regular', 'trip', 'settlement')),
  split_mode text not null check (split_mode in ('equal', 'shares', 'percent', 'exact')),
  trip_meta jsonb check (octet_length(trip_meta::text) <= 16384),
  unique (id, group_id)
);

-- Aggregate children: no own sync metadata, replaced wholesale with the parent expense.
-- The sum invariants (payers/shares == amount) are enforced by the upsert RPC (P6-T04).
create table public.expense_payers (
  group_id uuid not null references public.groups (id),
  expense_id uuid not null,
  member_id uuid not null,
  paid_cents bigint not null check (paid_cents > 0),
  primary key (expense_id, member_id),
  foreign key (expense_id, group_id) references public.expenses (id, group_id),
  foreign key (member_id, group_id) references public.members (id, group_id)
);

create table public.expense_shares (
  group_id uuid not null references public.groups (id),
  expense_id uuid not null,
  member_id uuid not null,
  share_cents bigint not null check (share_cents >= 0),
  -- Weight / basis points for share and percent modes (re-editing).
  weight bigint not null check (weight >= 0),
  primary key (expense_id, member_id),
  foreign key (expense_id, group_id) references public.expenses (id, group_id),
  foreign key (member_id, group_id) references public.members (id, group_id)
);

create table public.settlements (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  from_member uuid not null,
  to_member uuid not null,
  amount_cents bigint not null check (amount_cents > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  date timestamptz not null,
  method text not null check (method in ('paypal', 'sepa', 'cash', 'other')),
  foreign key (from_member, group_id) references public.members (id, group_id),
  foreign key (to_member, group_id) references public.members (id, group_id)
);

create table public.vehicles (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  name text not null check (char_length(name) <= 500),
  fuel_type text not null check (fuel_type in ('petrol', 'diesel', 'electric', 'other')),
  -- Litres or kWh per 100 km times 1000.
  consumption_milli_per_100km bigint not null check (consumption_milli_per_100km > 0),
  -- Thousandths of the major currency unit per km.
  wear_milli_per_km bigint not null default 0 check (wear_milli_per_km >= 0),
  -- If set, rides with this vehicle default to km-rate mode.
  km_rate_milli_per_km bigint check (km_rate_milli_per_km >= 0),
  unique (id, group_id)
);

create table public.ride_templates (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  name text not null check (char_length(name) <= 500),
  -- One-way distance in metres.
  distance_meters bigint not null check (distance_meters >= 0),
  round_trip boolean not null default false,
  vehicle_id uuid not null,
  default_driver_id uuid,
  -- JSON array of member ids, sorted (aggregate-level sync, no child table).
  default_passenger_ids jsonb not null default '[]' check (jsonb_typeof(default_passenger_ids) = 'array'),
  tolls_cents bigint not null default 0 check (tolls_cents >= 0),
  foreign key (vehicle_id, group_id) references public.vehicles (id, group_id),
  foreign key (default_driver_id, group_id) references public.members (id, group_id)
);

create table public.rides (
  id uuid primary key,
  group_id uuid not null references public.groups (id),
  created_at timestamptz not null default now(),
  updated_at text not null check (char_length(updated_at) between 1 and 100),
  deleted_at timestamptz,
  server_seq bigint not null,
  -- Calendar date stored as UTC midnight.
  date timestamptz not null,
  -- One-way distance in metres.
  distance_meters bigint not null check (distance_meters >= 0),
  round_trip boolean not null default false,
  tolls_cents bigint not null default 0 check (tolls_cents >= 0),
  vehicle_id uuid not null,
  driver_id uuid not null,
  -- JSON array of member ids, sorted (aggregate-level sync, no child table).
  passenger_ids jsonb not null default '[]' check (jsonb_typeof(passenger_ids) = 'array'),
  driver_counts boolean not null default true,
  -- Fuel price per litre or kWh in thousandths, frozen when logged.
  price_per_unit_milli bigint not null check (price_per_unit_milli >= 0),
  use_km_rate boolean not null default false,
  -- Set when a period is settled (P3r-T06); the ride is then locked.
  settled_expense_id uuid,
  foreign key (vehicle_id, group_id) references public.vehicles (id, group_id),
  foreign key (driver_id, group_id) references public.members (id, group_id),
  foreign key (settled_expense_id, group_id) references public.expenses (id, group_id)
);

-- Server-only: which auth user belongs to which group (and, once claimed, which member).
-- This is the sole source of authorization (is_group_member). Not synced, no sync columns.
create table public.group_memberships (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Null until the join/claim RPC links a participant (P6-T05).
  member_id uuid,
  created_at timestamptz not null default now(),
  unique (group_id, user_id),
  unique (group_id, member_id),
  foreign key (member_id, group_id) references public.members (id, group_id)
);

-- Server-only, structure only; create/join logic is P6-T05 (security definer RPCs).
-- Only the SHA-256 hash of the token is stored (plan §8).
create table public.group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id),
  token_hash bytea not null unique check (octet_length(token_hash) = 32),
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Indexes (pull cursor per group, FK lookups)
-- ---------------------------------------------------------------------------
create index members_group_server_seq on public.members (group_id, server_seq);
create index expenses_group_server_seq on public.expenses (group_id, server_seq);
create index settlements_group_server_seq on public.settlements (group_id, server_seq);
create index vehicles_group_server_seq on public.vehicles (group_id, server_seq);
create index ride_templates_group_server_seq on public.ride_templates (group_id, server_seq);
create index rides_group_date on public.rides (group_id, date);
create index rides_group_server_seq on public.rides (group_id, server_seq);
create index groups_server_seq on public.groups (server_seq);
create index expense_payers_group_id on public.expense_payers (group_id);
create index expense_payers_member_id on public.expense_payers (member_id);
create index expense_shares_group_id on public.expense_shares (group_id);
create index expense_shares_member_id on public.expense_shares (member_id);
create index group_memberships_user_id on public.group_memberships (user_id);
create index group_invites_group_id on public.group_invites (group_id);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------
create trigger set_server_seq before insert or update on public.groups
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.members
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.expenses
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.settlements
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.vehicles
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.ride_templates
  for each row execute function public.set_server_seq();
create trigger set_server_seq before insert or update on public.rides
  for each row execute function public.set_server_seq();

create trigger enforce_lww before update on public.groups
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.members
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.expenses
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.settlements
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.vehicles
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.ride_templates
  for each row execute function public.enforce_lww();
create trigger enforce_lww before update on public.rides
  for each row execute function public.enforce_lww();

create trigger enforce_group_id_immutable before update on public.members
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.expenses
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.expense_payers
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.expense_shares
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.settlements
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.vehicles
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.ride_templates
  for each row execute function public.enforce_group_id_immutable();
create trigger enforce_group_id_immutable before update on public.rides
  for each row execute function public.enforce_group_id_immutable();

-- ---------------------------------------------------------------------------
-- RLS helpers (security definer, empty search_path, cached auth.uid())
-- ---------------------------------------------------------------------------
create function public.is_group_member(gid uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.group_memberships gm
    where gm.group_id = gid
      and gm.user_id = (select auth.uid())
  );
$$;

-- True only for the creator of a live group that has no memberships yet: lets the creator
-- add the first membership row (themselves). Everyone else joins through P6-T05 RPCs.
create function public.can_bootstrap_group(gid uuid) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.groups g
    where g.id = gid
      and g.created_by = (select auth.uid())
      and g.deleted_at is null
      and not exists (
        select 1 from public.group_memberships gm where gm.group_id = g.id
      )
  );
$$;

revoke all on function public.is_group_member(uuid) from public;
revoke all on function public.can_bootstrap_group(uuid) from public;
grant execute on function public.is_group_member(uuid) to authenticated;
grant execute on function public.can_bootstrap_group(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Privileges: select/insert/update only, authenticated only. No delete anywhere.
-- ---------------------------------------------------------------------------
grant select, insert, update on
  public.groups, public.members, public.expenses, public.expense_payers,
  public.expense_shares, public.settlements, public.vehicles, public.ride_templates,
  public.rides
  to authenticated;
-- Memberships: bootstrap insert by the group creator; every other change via RPC (P6-T05).
grant select, insert on public.group_memberships to authenticated;
-- Invites: read-only for members; created/revoked via RPC (P6-T05).
grant select on public.group_invites to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: enabled everywhere, policies for `authenticated` only (anon has no policy and no grant).
-- ---------------------------------------------------------------------------
alter table public.groups enable row level security;
alter table public.members enable row level security;
alter table public.expenses enable row level security;
alter table public.expense_payers enable row level security;
alter table public.expense_shares enable row level security;
alter table public.settlements enable row level security;
alter table public.vehicles enable row level security;
alter table public.ride_templates enable row level security;
alter table public.rides enable row level security;
alter table public.group_memberships enable row level security;
alter table public.group_invites enable row level security;

-- groups: the creator may read/insert their own row before the first membership exists.
create policy groups_select on public.groups for select to authenticated
  using (public.is_group_member(id) or created_by = (select auth.uid()));
create policy groups_insert on public.groups for insert to authenticated
  with check (created_by = (select auth.uid()));
create policy groups_update on public.groups for update to authenticated
  using (public.is_group_member(id))
  with check (public.is_group_member(id));

-- Group-scoped tables: members of the row's group only.
create policy members_select on public.members for select to authenticated
  using (public.is_group_member(group_id));
create policy members_insert on public.members for insert to authenticated
  with check (public.is_group_member(group_id));
create policy members_update on public.members for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy expenses_select on public.expenses for select to authenticated
  using (public.is_group_member(group_id));
create policy expenses_insert on public.expenses for insert to authenticated
  with check (public.is_group_member(group_id));
create policy expenses_update on public.expenses for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy expense_payers_select on public.expense_payers for select to authenticated
  using (public.is_group_member(group_id));
create policy expense_payers_insert on public.expense_payers for insert to authenticated
  with check (public.is_group_member(group_id));
create policy expense_payers_update on public.expense_payers for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy expense_shares_select on public.expense_shares for select to authenticated
  using (public.is_group_member(group_id));
create policy expense_shares_insert on public.expense_shares for insert to authenticated
  with check (public.is_group_member(group_id));
create policy expense_shares_update on public.expense_shares for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy settlements_select on public.settlements for select to authenticated
  using (public.is_group_member(group_id));
create policy settlements_insert on public.settlements for insert to authenticated
  with check (public.is_group_member(group_id));
create policy settlements_update on public.settlements for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy vehicles_select on public.vehicles for select to authenticated
  using (public.is_group_member(group_id));
create policy vehicles_insert on public.vehicles for insert to authenticated
  with check (public.is_group_member(group_id));
create policy vehicles_update on public.vehicles for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy ride_templates_select on public.ride_templates for select to authenticated
  using (public.is_group_member(group_id));
create policy ride_templates_insert on public.ride_templates for insert to authenticated
  with check (public.is_group_member(group_id));
create policy ride_templates_update on public.ride_templates for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

create policy rides_select on public.rides for select to authenticated
  using (public.is_group_member(group_id));
create policy rides_insert on public.rides for insert to authenticated
  with check (public.is_group_member(group_id));
create policy rides_update on public.rides for update to authenticated
  using (public.is_group_member(group_id))
  with check (public.is_group_member(group_id));

-- group_memberships: select (own row also, so INSERT ... RETURNING works) + bootstrap insert.
create policy group_memberships_select on public.group_memberships for select to authenticated
  using (public.is_group_member(group_id) or user_id = (select auth.uid()));
create policy group_memberships_insert on public.group_memberships for insert to authenticated
  with check (user_id = (select auth.uid()) and public.can_bootstrap_group(group_id));

-- group_invites: members can read; writes only through P6-T05 RPCs.
create policy group_invites_select on public.group_invites for select to authenticated
  using (public.is_group_member(group_id));
