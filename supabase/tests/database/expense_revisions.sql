-- Expense edit history (P7-T03): trigger on expenses, RLS, retention, replay.
-- Actors: alice (member of group A, linked to member m1), bob (member of group B only),
-- mallory (member of nothing).
begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

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

-- Payload builder: expense X in group A, 1000 cents, m1 pays all, shares 500/500.
create function tests.pl(
  upd text,
  title text default 'dinner',
  amount bigint default 1000,
  payers jsonb default '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":1000}]',
  shares jsonb default '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":500,"weight":1}]',
  deleted text default null
) returns jsonb
language sql as $$
  select jsonb_build_object(
    'id', '00000000-0000-0000-0003-000000000010',
    'group_id', '00000000-0000-0000-0001-000000000001', 'title', title,
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
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'm1', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'm2', 1),
  ('00000000-0000-0000-0002-00000000000b', '00000000-0000-0000-0001-000000000002', 'h1', 'mb', 0);
insert into public.group_memberships (group_id, user_id, member_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0002-000000000001'),
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000002', null);

-- Structure ---------------------------------------------------------------------------------
select has_table('public', 'expense_revisions', 'expense_revisions exists');
select ok(not has_function_privilege('authenticated', 'public.record_expense_revision()', 'execute'),
  'clients cannot call the trigger function');
select ok(not has_function_privilege('anon', 'public.record_expense_revision()', 'execute'),
  'anon cannot call the trigger function');

-- Creation writes no revision ----------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((public.upsert_expense(tests.pl('h1')) ->> 'applied'), 'true', 'expense created');
select is((select count(*) from public.expense_revisions), 0::bigint, 'creation writes no revision');

-- A change of the amount fires the trigger ----------------------------------------------------
select is((public.upsert_expense(tests.pl('h2', title => 'lunch', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000,"weight":2}]'))
    ->> 'applied'), 'true', 'amount change applied');
select is((select count(*) from public.expense_revisions
           where expense_id = '00000000-0000-0000-0003-000000000010'), 1::bigint,
  'the amount change created one revision');
select is((select revision from public.expense_revisions), 1::bigint, 'first revision is number 1');
select is((select (snapshot ->> 'amount_cents')::bigint from public.expense_revisions
           where revision = 1), 1000::bigint, 'snapshot holds the amount before the change');
select is((select snapshot ->> 'title' from public.expense_revisions where revision = 1),
  'dinner', 'snapshot holds the title before the change');
select is((select snapshot -> 'payers' -> 0 ->> 'member_id' from public.expense_revisions
           where revision = 1), '00000000-0000-0000-0002-000000000001',
  'snapshot holds the payers before upsert_expense replaced them');
select is((select jsonb_array_length(snapshot -> 'shares') from public.expense_revisions
           where revision = 1), 2, 'snapshot holds the shares before the replacement');
select is((select (snapshot -> 'shares' -> 0 ->> 'weight')::int from public.expense_revisions
           where revision = 1), 1, 'snapshot shares carry the weight');
select is((select author_member_id from public.expense_revisions where revision = 1),
  '00000000-0000-0000-0002-000000000001'::uuid, 'author resolved from group_memberships.member_id');
select ok(not (select snapshot::text ~* 'iban|bic' from public.expense_revisions where revision = 1),
  'snapshots never contain bank data');

-- Replays and stale payloads create no duplicate -----------------------------------------------
select is((public.upsert_expense(tests.pl('h2', title => 'lunch', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000,"weight":2}]'))
    ->> 'applied'), 'false', 'replaying the same HLC is ignored');
select is((public.upsert_expense(tests.pl('h0')) ->> 'applied'), 'false', 'a stale HLC is ignored');
select is((select count(*) from public.expense_revisions), 1::bigint,
  'replay and stale payloads created no revision');

-- Second change and soft delete --------------------------------------------------------------
select is((public.upsert_expense(tests.pl('h3', title => 'lunch 2', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000,"weight":2}]'))
    ->> 'applied'), 'true', 'title change applied');
select is((select snapshot -> 'payers' -> 0 ->> 'member_id' from public.expense_revisions
           where revision = 2), '00000000-0000-0000-0002-000000000002',
  'revision 2 holds the payer set by the previous change');
select is((public.upsert_expense(tests.pl('h4', title => 'lunch 2', amount => 1500,
    payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":1000,"weight":2}]',
    deleted => '2026-02-01T00:00:00Z')) ->> 'applied'), 'true', 'soft delete applied');
select is((select count(*) from public.expense_revisions), 3::bigint, 'a soft delete adds a revision');

-- Access ----------------------------------------------------------------------------------------
select is((select count(*) from public.expense_revisions), 3::bigint, 'member can read the history');
select tests.as_user('00000000-0000-0000-0000-000000000002');
select is((select count(*) from public.expense_revisions), 0::bigint,
  'a member of another group sees nothing');
select tests.as_user('00000000-0000-0000-0000-000000000003');
select is((select count(*) from public.expense_revisions), 0::bigint, 'a non-member sees nothing');
select tests.as_anon();
select throws_ok($q$select 1 from public.expense_revisions$q$, '42501'::char(5), null,
  'anon select denied');
select tests.as_user('00000000-0000-0000-0000-000000000001');
select throws_ok(
  $q$insert into public.expense_revisions (expense_id, group_id, revision, snapshot)
     values ('00000000-0000-0000-0003-000000000010', '00000000-0000-0000-0001-000000000001', 99, '{}')$q$,
  '42501'::char(5), null, 'clients cannot insert revisions');
select throws_ok($q$update public.expense_revisions set revision = 98$q$, '42501'::char(5), null,
  'clients cannot update revisions');

-- Retention and the updated_at guard (as the table owner) -----------------------------------------
reset role;
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm,
                             group_amount_cents, date, type, split_mode)
  values ('00000000-0000-0000-0003-000000000011', '00000000-0000-0000-0001-000000000001', 'k0', 'e',
          1000, 'EUR', 1000000, 1000, now(), 'regular', 'equal');
update public.expenses set title = 'same hlc' where id = '00000000-0000-0000-0003-000000000011';
select is((select count(*) from public.expense_revisions
           where expense_id = '00000000-0000-0000-0003-000000000011'), 0::bigint,
  'an update without a new HLC records nothing');
select lives_ok($q$
  do $do$
  begin
    for i in 1..55 loop
      update public.expenses set title = 'v' || i, updated_at = 'k' || lpad(i::text, 3, '0')
        where id = '00000000-0000-0000-0003-000000000011';
    end loop;
  end
  $do$$q$, '55 successive changes');
select results_eq(
  $q$select count(*), min(revision), max(revision) from public.expense_revisions
     where expense_id = '00000000-0000-0000-0003-000000000011'$q$,
  $q$values (50::bigint, 6::bigint, 55::bigint)$q$,
  'only the newest 50 revisions are kept');

select * from finish();
rollback;
