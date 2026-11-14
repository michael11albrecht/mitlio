-- Schema invariants (P6-T02): no IBAN columns, constraints mirror the client, server_seq,
-- LWW guard, same-group foreign keys. Runs as postgres (RLS is covered by rls_*.sql).
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1'),
  ('00000000-0000-0000-0001-000000000002', 'B', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'a1', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000002', 'h1', 'b1', 0);
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date, type, split_mode)
  values ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'e', 1000, 'EUR', 1000000, 1000, now(), 'regular', 'equal');

-- Privacy: full IBANs never reach the server (plan §8).
select is_empty(
  $q$select table_name, column_name from information_schema.columns
     where table_schema = 'public'
       and column_name ~* '(iban|bic|account_name|account_number|swift)'
       and not (table_name = 'members' and column_name = 'iban_hint')$q$,
  'no IBAN/bank columns in public (only members.iban_hint)');
select throws_ok(
  $q$update public.members set iban_hint = 'DE89370400440532013000' where id = '00000000-0000-0000-0002-000000000001'$q$,
  '23514'::char(5), null, 'iban_hint cannot hold a full IBAN');
select lives_ok(
  $q$update public.members set iban_hint = 'DE89 …3000' where id = '00000000-0000-0000-0002-000000000001'$q$,
  'iban_hint accepts a masked hint');

-- server_seq: assigned by trigger from one global sequence, on insert and update.
select ok(
  (select server_seq > 0 from public.expenses where id = '00000000-0000-0000-0003-000000000001'),
  'server_seq is assigned on insert');
select lives_ok(
  $q$insert into public.members (id, group_id, updated_at, name, position, server_seq)
     values ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'h1', 'forged', 1, 999999999999)$q$,
  'insert with a client-supplied server_seq succeeds');
select ok(
  (select server_seq < 999999999999 from public.members where id = '00000000-0000-0000-0002-000000000003'),
  'client-supplied server_seq is overwritten by the trigger');
create temp table seq_before as
  select server_seq from public.expenses where id = '00000000-0000-0000-0003-000000000001';
update public.expenses set title = 'changed', updated_at = 'h2'
  where id = '00000000-0000-0000-0003-000000000001';
select ok(
  (select e.server_seq > b.server_seq from public.expenses e, seq_before b
   where e.id = '00000000-0000-0000-0003-000000000001'),
  'server_seq increases on update');

-- LWW guard and immutability.
select throws_ok(
  $q$update public.expenses set updated_at = 'h1' where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'updated_at going backwards is rejected');
select lives_ok(
  $q$update public.expenses set updated_at = 'h2' where id = '00000000-0000-0000-0003-000000000001'$q$,
  'replaying the same updated_at is accepted (idempotent)');
select lives_ok(
  $q$update public.expenses set updated_at = 'h3' where id = '00000000-0000-0000-0003-000000000001'$q$,
  'updated_at moving forward is accepted');
select throws_ok(
  $q$update public.expenses set id = '00000000-0000-0000-0003-0000000000ff' where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'id is immutable');
select throws_ok(
  $q$update public.members set group_id = '00000000-0000-0000-0001-000000000002'
     where id = '00000000-0000-0000-0002-000000000001'$q$,
  '23514'::char(5), null, 'group_id is immutable');

-- Constraints mirroring the client schema.
select throws_ok(
  $q$update public.expenses set amount_cents = 0 where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'expenses.amount_cents must be > 0');
select throws_ok(
  $q$update public.expenses set currency = 'eur' where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'currency must be an upper-case ISO code');
select throws_ok(
  $q$update public.expenses set type = 'other' where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'expenses.type is restricted');
select throws_ok(
  $q$update public.expenses set split_mode = 'random' where id = '00000000-0000-0000-0003-000000000001'$q$,
  '23514'::char(5), null, 'expenses.split_mode is restricted');
select throws_ok(
  $q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000001', 0)$q$,
  '23514'::char(5), null, 'expense_payers.paid_cents must be > 0');
select throws_ok(
  $q$insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000001', -1, 0)$q$,
  '23514'::char(5), null, 'expense_shares.share_cents must be >= 0');
select throws_ok(
  $q$insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents, currency, date, method)
     values ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-000000000001', 'h1',
             '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0002-000000000001', 1, 'EUR', now(), 'bitcoin')$q$,
  '23514'::char(5), null, 'settlements.method is restricted');
select throws_ok(
  $q$insert into public.vehicles (id, group_id, updated_at, name, fuel_type, consumption_milli_per_100km)
     values ('00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'v', 'coal', 1)$q$,
  '23514'::char(5), null, 'vehicles.fuel_type is restricted');
select throws_ok(
  $q$insert into public.ride_templates (id, group_id, updated_at, name, distance_meters, vehicle_id, default_passenger_ids)
     values ('00000000-0000-0000-0006-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 't', 1,
             '00000000-0000-0000-0005-000000000001', '[]')$q$,
  '23503'::char(5), null, 'ride_templates reference an existing vehicle in the same group');

-- Same-group integrity via composite foreign keys.
select throws_ok(
  $q$insert into public.expense_payers (group_id, expense_id, member_id, paid_cents)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0002-000000000002', 100)$q$,
  '23503'::char(5), null, 'a payer must be a member of the expense''s group');
select throws_ok(
  $q$insert into public.group_memberships (group_id, user_id, member_id)
     values ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000002')$q$,
  '23503'::char(5), null, 'a membership can only claim a member of its own group');

select * from finish();
rollback;
