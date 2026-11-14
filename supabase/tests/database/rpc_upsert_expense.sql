-- upsert_expense RPC (P6-T04): invariants, LWW, children replacement, soft delete, access.
-- Actors: alice (member of group A), bob (member of group B only), mallory (member of nothing).
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

create schema tests;
grant usage on schema tests to anon, authenticated;

create function tests.as_user(uid uuid) returns void
language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  set local role authenticated;
end;
$$;

create function tests.as_anon() returns void
language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;
end;
$$;

-- Payload builder. Defaults: expense X in group A, 1000 cents, alice-side members m1 pays all,
-- shares 500/500.
create function tests.pl(
  upd text,
  title text default 'dinner',
  amount bigint default 1000,
  payers jsonb default '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":1000}]',
  shares jsonb default '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":500,"weight":1}]',
  gid uuid default '00000000-0000-0000-0001-000000000001',
  deleted text default null
) returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', '00000000-0000-0000-0003-000000000010', 'group_id', gid, 'title', title,
    'amount_cents', amount, 'currency', 'EUR', 'fx_rate_ppm', 1000000,
    'group_amount_cents', amount, 'date', '2026-01-01T00:00:00Z', 'type', 'regular',
    'split_mode', 'equal', 'updated_at', upd, 'deleted_at', deleted,
    'payers', payers, 'shares', shares);
$$;

reset role;
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'alice@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test'),
  ('00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'mallory@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Group A', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1'),
  ('00000000-0000-0000-0001-000000000002', 'Group B', 'EUR', '00000000-0000-0000-0000-000000000002', 'h1');
insert into public.group_memberships (group_id, user_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000002');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 1),
  ('00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0001-000000000002', 'h1', 'mb', 0);

-- Insert -----------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((public.upsert_expense(tests.pl('h1')) ->> 'applied'), 'true',
  'first upsert inserts and reports applied=true');
select is((select count(*) from public.expense_payers
           where expense_id = '00000000-0000-0000-0003-000000000010'), 1::bigint, 'payers stored');
select is((select count(*) from public.expense_shares
           where expense_id = '00000000-0000-0000-0003-000000000010'), 2::bigint, 'shares stored');
select ok((public.upsert_expense(tests.pl('h1')) -> 'expense' ->> 'server_seq') is not null,
  'returned server row includes server_seq');

-- Replay is idempotent -----------------------------------------------------------------------
select lives_ok(
  $q$select set_config('t.seq',
       (select server_seq::text from public.expenses
        where id = '00000000-0000-0000-0003-000000000010'), true)$q$,
  'remember server_seq');
select is((public.upsert_expense(tests.pl('h1')) ->> 'applied'), 'false',
  'replaying the same payload (equal HLC) is ignored');
select is((select server_seq from public.expenses where id = '00000000-0000-0000-0003-000000000010'),
  current_setting('t.seq')::bigint, 'replay does not touch the row (server_seq unchanged)');

-- Stale HLC is ignored -----------------------------------------------------------------------
select is((public.upsert_expense(tests.pl('h0', title => 'stale', amount => 2000,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":2000}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":2000}]')) ->> 'applied'),
  'false', 'a stale HLC is ignored (applied=false)');
select is((select title from public.expenses where id = '00000000-0000-0000-0003-000000000010'),
  'dinner', 'stale payload did not change the row');
select is((select count(*) from public.expense_payers
           where expense_id = '00000000-0000-0000-0003-000000000010'
             and member_id = '00000000-0000-0000-0002-000000000001'), 1::bigint,
  'stale payload did not touch the children');

-- Newer HLC wins and children are replaced wholesale -------------------------------------------
select is((public.upsert_expense(tests.pl('h2', title => 'lunch', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000}]'))
    ->> 'applied'), 'true', 'a newer HLC wins');
select is((select title from public.expenses where id = '00000000-0000-0000-0003-000000000010'),
  'lunch', 'row updated by the newer payload');
select is((select array_agg(member_id::text) from public.expense_payers
           where expense_id = '00000000-0000-0000-0003-000000000010'),
  array['00000000-0000-0000-0002-000000000002'], 'payers replaced (old payer gone)');
select is((select sum(share_cents) from public.expense_shares
           where expense_id = '00000000-0000-0000-0003-000000000010'), 1500::numeric,
  'shares replaced');
select cmp_ok((select server_seq from public.expenses where id = '00000000-0000-0000-0003-000000000010'),
  '>', current_setting('t.seq')::bigint, 'server_seq advanced on a winning update');

-- Invariants (23514 check_violation, stable code in the message) -------------------------------
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9',
       payers => '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":999}]'))$q$,
  '23514', 'payers_sum_mismatch', 'payers sum must equal amount_cents');
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9',
       shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":400}]'))$q$,
  '23514', 'shares_sum_mismatch', 'shares sum must equal group_amount_cents');
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9', amount => 0,
       payers => '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":1}]'))$q$,
  '23514', 'amount_not_positive', 'amount must be positive');
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9',
       payers => '[{"member_id":"00000000-0000-0000-0002-00000000000b","paid_cents":1000}]'))$q$,
  '23514', 'member_not_in_group', 'payer from another group is rejected');
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9',
       shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500},{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500}]'))$q$,
  '23514', 'duplicate_member', 'duplicate member in shares is rejected');
select throws_ok($q$select public.upsert_expense(null)$q$,
  '23514', 'invalid_payload', 'null payload is rejected');
select is((select count(*) from public.expense_payers
           where expense_id = '00000000-0000-0000-0003-000000000010'), 1::bigint,
  'failed calls leave the stored children untouched');

-- Soft delete keeps the children -----------------------------------------------------------------
select is((public.upsert_expense(tests.pl('h3', title => 'lunch', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000}]',
    deleted => '2026-02-01T00:00:00Z')) -> 'expense' ->> 'deleted_at') is not null, true,
  'soft delete via deleted_at is applied');

-- Access ---------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000003');
select throws_ok($q$select public.upsert_expense(tests.pl('h9'))$q$,
  '42501', null, 'a non-member is denied');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select throws_ok(
  $q$select public.upsert_expense(tests.pl('h9', gid => '00000000-0000-0000-0001-000000000002',
       payers => '[{"member_id":"00000000-0000-0000-0002-00000000000b","paid_cents":1000}]',
       shares => '[{"member_id":"00000000-0000-0000-0002-00000000000b","share_cents":1000}]'))$q$,
  '42501', null, 'cannot hijack an expense id that lives in a group the caller is not in');
select tests.as_anon();
select throws_ok($q$select public.upsert_expense(tests.pl('h9'))$q$,
  '42501', null, 'anon is denied');

reset role;
select ok(
  (select p.prosecdef and p.proconfig @> array['search_path=""']
   from pg_proc p where p.oid = 'public.upsert_expense(jsonb)'::regprocedure),
  'upsert_expense is security definer with an empty search_path');
select ok(
  not has_function_privilege('anon', 'public.upsert_expense(jsonb)', 'execute')
  and has_function_privilege('authenticated', 'public.upsert_expense(jsonb)', 'execute'),
  'upsert_expense: no EXECUTE for anon/PUBLIC, EXECUTE for authenticated');

select * from finish();
rollback;
