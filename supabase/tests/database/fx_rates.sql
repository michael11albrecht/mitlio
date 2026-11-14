-- fx_rates and the cron jobs (P7-T02).
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

insert into public.fx_rates (base, quote, date, rate_ppm, source_date)
values ('USD', 'EUR', '2025-11-15', 920000, '2025-11-14');

set local role anon;
select is((select rate_ppm from public.fx_rates where base = 'USD'), 920000::bigint, 'anon can read the rates');
set local role authenticated;
select is((select rate_ppm from public.fx_rates where base = 'USD'), 920000::bigint, 'authenticated can read the rates');

set local role anon;
select throws_ok($q$insert into public.fx_rates (base, quote, date, rate_ppm, source_date) values ('GBP', 'EUR', '2025-11-14', 1, '2025-11-14')$q$,
  '42501', null, 'anon cannot insert');
select throws_ok($q$update public.fx_rates set rate_ppm = 1$q$, '42501', null, 'anon cannot update');
select throws_ok($q$delete from public.fx_rates$q$, '42501', null, 'anon cannot delete');
set local role authenticated;
select throws_ok($q$insert into public.fx_rates (base, quote, date, rate_ppm, source_date) values ('GBP', 'EUR', '2025-11-14', 1, '2025-11-14')$q$,
  '42501', null, 'authenticated cannot insert');
select throws_ok($q$update public.fx_rates set rate_ppm = 1$q$, '42501', null, 'authenticated cannot update');
select throws_ok($q$delete from public.fx_rates$q$, '42501', null, 'authenticated cannot delete');

set local role service_role;
select lives_ok($q$insert into public.fx_rates (base, quote, date, rate_ppm, source_date) values ('GBP', 'EUR', '2025-11-14', 1150000, '2025-11-14')$q$,
  'service_role can insert');
select throws_ok($q$insert into public.fx_rates (base, quote, date, rate_ppm, source_date) values ('EUR', 'EUR', '2025-11-14', 1000000, '2025-11-14')$q$,
  '23514', null, 'base = quote rejected');
select throws_ok($q$insert into public.fx_rates (base, quote, date, rate_ppm, source_date) values ('CHF', 'EUR', '2025-11-14', 0, '2025-11-14')$q$,
  '23514', null, 'non-positive rate rejected');

reset role;
select ok(exists (select 1 from cron.job where jobname = 'fx-rates-warm' and schedule = '20 15 * * 1-5'),
  'daily warm job is scheduled');
select ok(exists (select 1 from cron.job where jobname = 'fx-rates-cleanup'), 'cleanup job is scheduled');
select lives_ok($q$select public.warm_fx_rates()$q$, 'warm job is inert without vault secrets');

select * from finish();
rollback;
