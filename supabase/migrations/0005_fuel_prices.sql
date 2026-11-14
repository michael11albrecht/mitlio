-- 0005_fuel_prices: fuel price cache, rate limiter and cron jobs (P6c-T02, T04, T06; plan §7 P6c, ADR-20).
--
-- Privacy and abuse model:
--   * fuel_price_cache holds public provider aggregates only (median price per fuel type and region
--     key: a geohash-6 cell + radius, a PLZ, 'de' for the Tankerkönig national average or
--     'de-bulletin' for the EU Weekly Oil Bulletin). No user data. Readable by anon + authenticated (the web
--     calculator and the app may read it directly); written by the Edge Function with the service
--     role only. There is no insert/update/delete policy and no write grant for client roles.
--   * rate_limits holds a token bucket per sha256(ip + salt). The hash is computed in the Edge
--     Function; raw IPs never reach the database. RLS is on, there is no policy and no grant for
--     client roles; only service_role may call consume_rate_limit().
--   * The hourly cron job warms the national averages through the Edge Function. It is inert until
--     the owner stores the Vault secrets fuel_prices_url, fuel_prices_anon_key and
--     fuel_prices_warm_token (without them warm_fuel_national() returns immediately).

set lock_timeout = '1s';
set statement_timeout = '5s';

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

create table if not exists public.fuel_price_cache (
  type text not null check (type in ('e5', 'e10', 'diesel')),
  scope text not null check (scope in ('nearby', 'plz', 'national')),
  scope_key text not null check (char_length(scope_key) between 1 and 32),
  price_milli integer not null check (price_milli > 0 and price_milli < 10000),
  stations integer not null check (stations >= 0),
  fetched_at timestamptz not null default now(),
  source text not null default 'tankerkoenig' check (source in ('tankerkoenig', 'eu-oil-bulletin')),
  -- Date the data is valid for when that differs from the fetch time (weekly bulletin).
  observed_at timestamptz,
  -- Set when the value stands in for another fuel type (national e10 from the bulletin's e5).
  approximation text check (approximation in ('e5')),
  primary key (type, scope, scope_key)
);
alter table public.fuel_price_cache enable row level security;
revoke all on public.fuel_price_cache from anon, authenticated;
grant select on public.fuel_price_cache to anon, authenticated;
grant select, insert, update, delete on public.fuel_price_cache to service_role;
create policy fuel_price_cache_public_read on public.fuel_price_cache
  for select to anon, authenticated using (true);

create table if not exists public.rate_limits (
  key_hash text primary key check (char_length(key_hash) between 16 and 128),
  tokens double precision not null,
  updated_at timestamptz not null default now()
);
alter table public.rate_limits enable row level security;
revoke all on public.rate_limits from anon, authenticated;
grant select, insert, update, delete on public.rate_limits to service_role;

-- Token bucket: refills p_refill_per_sec tokens per second up to p_capacity; takes one token.
-- Returns false when the bucket is empty.
create or replace function public.consume_rate_limit(
  p_key text, p_capacity integer, p_refill_per_sec double precision
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tokens double precision;
begin
  if p_capacity not between 1 and 10000 or p_refill_per_sec < 0 or p_refill_per_sec > 1000 then
    raise exception 'invalid rate limit parameters' using errcode = '22023';
  end if;
  insert into public.rate_limits (key_hash, tokens, updated_at)
  values (p_key, p_capacity, now())
  on conflict (key_hash) do nothing;
  update public.rate_limits r
    set tokens = least(p_capacity::double precision,
                       r.tokens + extract(epoch from (now() - r.updated_at)) * p_refill_per_sec),
        updated_at = now()
    where r.key_hash = p_key
    returning r.tokens into v_tokens;
  if v_tokens < 1 then
    return false;
  end if;
  update public.rate_limits r set tokens = r.tokens - 1 where r.key_hash = p_key;
  return true;
end;
$$;
revoke all on function public.consume_rate_limit(text, integer, double precision) from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, integer, double precision) to service_role;

-- Calls the Edge Function once per fuel type with the warm token so the national averages are
-- refreshed even when nobody asked (bulletin without a provider key, Tankerkönig average with one). Inert without the Vault secrets (no key, no URL, no call).
create or replace function public.warm_fuel_national() returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_anon text;
  v_token text;
  v_type text;
begin
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_url using 'fuel_prices_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_anon using 'fuel_prices_anon_key';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_token using 'fuel_prices_warm_token';
  if coalesce(v_url, '') = '' or coalesce(v_anon, '') = '' or coalesce(v_token, '') = '' then
    return;
  end if;
  foreach v_type in array array['e5', 'e10', 'diesel'] loop
    perform net.http_get(
      url := v_url || '?type=' || v_type,
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || v_anon,
        'apikey', v_anon,
        'x-fuel-warm', v_token));
  end loop;
end;
$$;
revoke all on function public.warm_fuel_national() from public, anon, authenticated;

create or replace function public.cleanup_fuel_tables() returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.rate_limits where updated_at < now() - interval '1 day';
  delete from public.fuel_price_cache where scope <> 'national' and fetched_at < now() - interval '2 days';
$$;
revoke all on function public.cleanup_fuel_tables() from public, anon, authenticated;

select cron.schedule('fuel-prices-warm-national', '0 * * * *', 'select public.warm_fuel_national()');
select cron.schedule('fuel-prices-cleanup', '17 3 * * *', 'select public.cleanup_fuel_tables()');
