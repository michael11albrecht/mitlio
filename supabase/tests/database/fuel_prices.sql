-- fuel_price_cache, rate_limits, consume_rate_limit and the cron jobs (P6c-T02, T04, T06).
begin;
create extension if not exists pgtap with schema extensions;
select plan(24);

insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations)
values ('e5', 'national', 'de', 1799, 16);

-- Reads: anon and authenticated.
set local role anon;
select is((select price_milli from public.fuel_price_cache where scope_key = 'de'), 1799,
  'anon can read the cache');
set local role authenticated;
select is((select price_milli from public.fuel_price_cache where scope_key = 'de'), 1799,
  'authenticated can read the cache');

-- Writes: never from client roles.
set local role anon;
select throws_ok($q$insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations) values ('e10', 'national', 'de', 1700, 1)$q$,
  '42501', null, 'anon cannot insert');
select throws_ok($q$update public.fuel_price_cache set price_milli = 1$q$,
  '42501', null, 'anon cannot update');
select throws_ok($q$delete from public.fuel_price_cache$q$,
  '42501', null, 'anon cannot delete');
set local role authenticated;
select throws_ok($q$insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations) values ('e10', 'national', 'de', 1700, 1)$q$,
  '42501', null, 'authenticated cannot insert');
select throws_ok($q$update public.fuel_price_cache set price_milli = 1$q$,
  '42501', null, 'authenticated cannot update');
select throws_ok($q$delete from public.fuel_price_cache$q$,
  '42501', null, 'authenticated cannot delete');

-- service role writes (bypasses RLS).
set local role service_role;
select lives_ok($q$insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations) values ('e10', 'national', 'de', 1700, 1)$q$,
  'service_role can insert');
select throws_ok($q$insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations) values ('lpg', 'national', 'de', 1, 1)$q$,
  '23514', null, 'unknown fuel type rejected');
select throws_ok($q$insert into public.fuel_price_cache (type, scope, scope_key, price_milli, stations) values ('e5', 'nearby', 'u33dc1:5', 0, 1)$q$,
  '23514', null, 'non-positive price rejected');

-- rate_limits is invisible to clients.
set local role anon;
select throws_ok($q$select * from public.rate_limits$q$, '42501', null, 'anon cannot read rate_limits');
select throws_ok($q$select public.consume_rate_limit('0123456789abcdef', 2, 0)$q$, '42501', null, 'anon cannot call consume_rate_limit');
set local role authenticated;
select throws_ok($q$select * from public.rate_limits$q$, '42501', null, 'authenticated cannot read rate_limits');
select throws_ok($q$select public.consume_rate_limit('0123456789abcdef', 2, 0)$q$, '42501', null, 'authenticated cannot call consume_rate_limit');

-- Token bucket semantics (service role).
set local role service_role;
select is(public.consume_rate_limit('0123456789abcdef', 2, 0), true, 'bucket: first request passes');
select is(public.consume_rate_limit('0123456789abcdef', 2, 0), true, 'bucket: second request passes');
select is(public.consume_rate_limit('0123456789abcdef', 2, 0), false, 'bucket: third request is limited');
select throws_ok($q$select public.consume_rate_limit('0123456789abcdef', 0, 1)$q$, '22023', null, 'invalid capacity rejected');

reset role;
update public.rate_limits set updated_at = now() - interval '10 seconds' where key_hash = '0123456789abcdef';
set local role service_role;
select is(public.consume_rate_limit('0123456789abcdef', 2, 1), true, 'bucket refills over time');

-- Cron jobs exist and the warm job is inert without secrets.
reset role;
select ok(exists (select 1 from cron.job where jobname = 'fuel-prices-warm-national' and schedule = '0 * * * *'),
  'hourly national warm job is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'fuel-prices-cleanup'), 'cleanup job is scheduled');
select lives_ok($q$select public.warm_fuel_national()$q$, 'warm job is inert without vault secrets');

select * from finish();
rollback;
