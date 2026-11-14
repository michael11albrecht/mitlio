-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the table is
-- created here, so "enable row level security" cannot hit existing data or be re-run.
-- 0006_fx_rates: ECB reference rate cache and cron jobs (P7-T02; plan §7 P7, §2.5).
--
-- Privacy and abuse model (same as fuel_price_cache, see 0005_fuel_prices.sql):
--   * fx_rates holds public ECB reference rates only (via Frankfurter), no user data. Readable by
--     anon + authenticated; written by the Edge Function with the service role only. There is no
--     insert/update/delete policy and no write grant for client roles.
--   * `date` is the cache key: the day that was asked for (UTC today for "latest"). `source_date`
--     is the ECB working day the rate is from (Friday for a Saturday). rate_ppm is units of
--     `quote` major per 1 `base` major times 1e6 (docs/domain-rules.md "FX conversion").
--   * The daily cron job warms the common pairs through the Edge Function shortly after the ECB
--     publishes (~16:00 CET). It is inert until the owner stores the Vault secrets fx_rates_url,
--     fx_rates_anon_key and fx_rates_warm_token (without them warm_fx_rates() returns at once).

set lock_timeout = '1s';
set statement_timeout = '5s';

create table if not exists public.fx_rates (
  base text not null check (base ~ '^[A-Z]{3}$'),
  quote text not null check (quote ~ '^[A-Z]{3}$' and quote <> base),
  date date not null,
  rate_ppm bigint not null check (rate_ppm > 0),
  source_date date not null,
  fetched_at timestamptz not null default now(),
  primary key (base, quote, date)
);
alter table public.fx_rates enable row level security;
revoke all on public.fx_rates from anon, authenticated;
grant select on public.fx_rates to anon, authenticated;
grant select, insert, update, delete on public.fx_rates to service_role;
create policy fx_rates_public_read on public.fx_rates
  for select to anon, authenticated using (true);

-- Calls the Edge Function once per common currency (quoted in EUR) with the warm token, which
-- forces a refresh and skips the rate limit. Inert without the Vault secrets (no URL, no call).
create or replace function public.warm_fx_rates() returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_anon text;
  v_token text;
  v_base text;
begin
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_url using 'fx_rates_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_anon using 'fx_rates_anon_key';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_token using 'fx_rates_warm_token';
  if coalesce(v_url, '') = '' or coalesce(v_anon, '') = '' or coalesce(v_token, '') = '' then
    return;
  end if;
  foreach v_base in array array['USD', 'GBP', 'CHF', 'PLN', 'CZK', 'SEK', 'DKK', 'NOK', 'HUF', 'TRY'] loop
    perform net.http_get(
      url := v_url || '?base=' || v_base || '&quote=EUR',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || v_anon,
        'apikey', v_anon,
        'x-fx-warm', v_token));
  end loop;
end;
$$;
revoke all on function public.warm_fx_rates() from public, anon, authenticated;

create or replace function public.cleanup_fx_rates() returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.fx_rates where fetched_at < now() - interval '60 days';
$$;
revoke all on function public.cleanup_fx_rates() from public, anon, authenticated;

-- ECB publishes at about 16:00 CET (15:00 UTC in winter, 14:00 in summer) on working days.
select cron.schedule('fx-rates-warm', '20 15 * * 1-5', 'select public.warm_fx_rates()');
select cron.schedule('fx-rates-cleanup', '23 3 * * *', 'select public.cleanup_fx_rates()');
