-- Outbox triggers (P6b-T03): which writes of expenses, settlements and members notify.
-- Actors: alice (member of group A, linked to person m1), bob (member of group A, linked to m2),
-- person m3 is not linked yet. The expense trigger is deferred to COMMIT; the test runs in one
-- transaction, so tests.flush() fires the pending trigger events like a commit would.
begin;
create extension if not exists pgtap with schema extensions;
select plan(42);

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

create function tests.as_service() returns void
language plpgsql as $$
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
end;
$$;

create function tests.flush() returns void
language plpgsql as $$
begin
  set constraints all immediate;
  set constraints all deferred;
end;
$$;

-- The outbox is closed to clients; the test reads it through definer helpers owned by postgres.
create function tests.outbox_n() returns bigint
language sql security definer as $$ select count(*) from public.notification_outbox $$;
create function tests.outbox_rows() returns setof public.notification_outbox
language sql security definer as $$
  select * from public.notification_outbox order by ctid $$;
grant execute on function tests.outbox_n(), tests.outbox_rows() to authenticated;

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
  ('00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'bob@example.test');
insert into public.groups (id, name, currency, created_by, updated_at) values
  ('00000000-0000-0000-0001-000000000001', 'Italy trip', 'EUR', '00000000-0000-0000-0000-000000000001', 'h1');
insert into public.members (id, group_id, updated_at, name, position) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0001-000000000001', 'h1', 'Anna', 0),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', 'Ben', 1),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0001-000000000001', 'h1', 'Cara', 2);
insert into public.group_memberships (group_id, user_id, member_id) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000001'),
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0002-000000000002');

-- expense added ------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000001');
select is((public.upsert_expense(tests.pl('k02')) ->> 'applied'), 'true', 'expense created');
select is(tests.outbox_n(), 0::bigint, 'nothing is queued before commit');
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'a new expense queues one row at commit');
select is((select event from tests.outbox_rows()), 'expense_added', 'event is expense_added');
select is((select actor_user_id from tests.outbox_rows()), '00000000-0000-0000-0000-000000000001'::uuid,
  'actor is the caller');
select is((select entity_id from tests.outbox_rows()), '00000000-0000-0000-0003-000000000010'::uuid,
  'entity is the expense');
select is((select group_id from tests.outbox_rows()), '00000000-0000-0000-0001-000000000001'::uuid,
  'group is set');
select is((select payload from tests.outbox_rows()),
  '{"title":"dinner","amount_cents":1000,"currency":"EUR","group_name":"Italy trip","actor_name":"Anna",
    "involved_member_ids":["00000000-0000-0000-0002-000000000001","00000000-0000-0000-0002-000000000002"]}'::jsonb,
  'payload has display strings and ids only');
select is((select processed_at from tests.outbox_rows()), null, 'row is pending');

-- replay and invisible edits -> no rows ------------------------------------------------------------
select is((public.upsert_expense(tests.pl('k02')) ->> 'applied'), 'false', 'replay of the same HLC is not applied');
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'sync replay of the same HLC queues nothing');
select is((public.upsert_expense(tests.pl('k03', title => 'dinner at Luigi')) ->> 'applied'), 'true',
  'title edit applied');
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'a title-only edit queues nothing');
select is((public.upsert_expense(tests.pl('k04',
    shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":500,"weight":5},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":500,"weight":5}]'))
  ->> 'applied'), 'true', 'weight-only edit applied');
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'a weight-only edit (same cents) queues nothing');
update public.expenses set title = 'direct', updated_at = 'k04b'
  where id = '00000000-0000-0000-0003-000000000010';
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'a direct title update queues nothing');
update public.expenses set title = 'same hlc'
  where id = '00000000-0000-0000-0003-000000000010';
select tests.flush();
select is(tests.outbox_n(), 1::bigint, 'an update that keeps the HLC queues nothing');

-- visible edits -> one row each ---------------------------------------------------------------------
select public.upsert_expense(tests.pl('k05', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":750,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":750,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 2::bigint, 'an amount change queues one row');
select is((select event from tests.outbox_rows() offset 1), 'expense_changed', 'event is expense_changed');
select public.upsert_expense(tests.pl('k05', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000001","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":750,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":750,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 2::bigint, 'replaying the amount change queues nothing');

select public.upsert_expense(tests.pl('k06', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":750,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":750,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 3::bigint, 'a payer change queues one row');

select public.upsert_expense(tests.pl('k07', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":1000,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000002","share_cents":500,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 4::bigint, 'a share change queues one row');

select public.upsert_expense(tests.pl('k08', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":1000,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000003","share_cents":500,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 5::bigint, 'swapping a share holder queues one row');
select is((select payload -> 'involved_member_ids' from tests.outbox_rows() offset 4),
  '["00000000-0000-0000-0002-000000000001","00000000-0000-0000-0002-000000000002","00000000-0000-0000-0002-000000000003"]'::jsonb,
  'involved members are payers and share holders');

-- delete and undelete -------------------------------------------------------------------------------
select public.upsert_expense(tests.pl('k09', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":1000,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000003","share_cents":500,"weight":1}]',
  deleted => '2026-02-01T00:00:00Z'));
select tests.flush();
select is(tests.outbox_n(), 6::bigint, 'a soft delete queues one row');
select is((select event from tests.outbox_rows() offset 5), 'expense_deleted', 'event is expense_deleted');
select public.upsert_expense(tests.pl('k10', title => 'edited while deleted', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":1000,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000003","share_cents":500,"weight":1}]',
  deleted => '2026-02-01T00:00:00Z'));
select tests.flush();
select is(tests.outbox_n(), 6::bigint, 'editing an already deleted expense queues nothing');
select public.upsert_expense(tests.pl('k11', amount => 1500,
  payers => '[{"member_id":"00000000-0000-0000-0002-000000000002","paid_cents":1500}]',
  shares => '[{"member_id":"00000000-0000-0000-0002-000000000001","share_cents":1000,"weight":1},{"member_id":"00000000-0000-0000-0002-000000000003","share_cents":500,"weight":1}]'));
select tests.flush();
select is(tests.outbox_n(), 7::bigint, 'un-deleting queues one row');
select is((select event from tests.outbox_rows() offset 6), 'expense_added', 'un-delete is expense_added');

-- a deleted new expense, and writes without a signed-in actor ---------------------------------------
select is((public.upsert_expense(jsonb_set(tests.pl('k12', deleted => '2026-02-01T00:00:00Z'), '{id}',
    '"00000000-0000-0000-0003-000000000011"')) ->> 'applied'), 'true', 'a new, already deleted expense is stored');
select tests.flush();
select is(tests.outbox_n(), 7::bigint, 'a new expense that is already deleted queues nothing');
-- No signed-in user: clear the JWT claims of the previous steps, then act as the table owner.
select tests.as_service();
insert into public.expenses (id, group_id, updated_at, title, amount_cents, currency, fx_rate_ppm,
  group_amount_cents, date, type, split_mode)
values ('00000000-0000-0000-0003-000000000012', '00000000-0000-0000-0001-000000000001', 'h1',
  'service write', 100, 'EUR', 1000000, 100, now(), 'regular', 'equal');
select tests.flush();
select is(tests.outbox_n(), 7::bigint, 'a write without a signed-in user (service role) queues nothing');

-- settlements ----------------------------------------------------------------------------------------
select tests.as_user('00000000-0000-0000-0000-000000000002');
insert into public.settlements (id, group_id, updated_at, from_member, to_member, amount_cents,
  currency, date, method)
values ('00000000-0000-0000-0004-000000000001', '00000000-0000-0000-0001-000000000001', 'h1',
  '00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0002-000000000001', 500, 'EUR', now(), 'cash');
select is(tests.outbox_n(), 8::bigint, 'a new settlement queues one row immediately');
select is((select event from tests.outbox_rows() offset 7), 'settlement_added', 'event is settlement_added');
select is((select payload from tests.outbox_rows() offset 7),
  '{"amount_cents":500,"currency":"EUR","group_name":"Italy trip","actor_name":"Ben",
    "involved_member_ids":["00000000-0000-0000-0002-000000000002","00000000-0000-0000-0002-000000000001"]}'::jsonb,
  'settlement payload');
update public.settlements set deleted_at = now(), updated_at = 'k02'
  where id = '00000000-0000-0000-0004-000000000001';
insert into public.settlements (id, group_id, updated_at, deleted_at, from_member, to_member,
  amount_cents, currency, date, method)
values ('00000000-0000-0000-0004-000000000002', '00000000-0000-0000-0001-000000000001', 'h1', now(),
  '00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0002-000000000001', 500, 'EUR', now(), 'cash');
select is(tests.outbox_n(), 8::bigint, 'deleting or inserting a deleted settlement queues nothing');

-- members --------------------------------------------------------------------------------------------
update public.members set user_id = '00000000-0000-0000-0000-000000000002'
  where id = '00000000-0000-0000-0002-000000000003';
select is(tests.outbox_n(), 9::bigint, 'linking a person to an account queues member_joined');
select is((select event from tests.outbox_rows() offset 8), 'member_joined', 'event is member_joined');
select is((select actor_user_id from tests.outbox_rows() offset 8), '00000000-0000-0000-0000-000000000002'::uuid,
  'the linked account is the actor');
select is((select payload from tests.outbox_rows() offset 8),
  '{"member_name":"Cara","group_name":"Italy trip","actor_name":"Ben"}'::jsonb, 'member payload');
update public.members set name = 'Cara K', updated_at = 'k02'
  where id = '00000000-0000-0000-0002-000000000003';
select is(tests.outbox_n(), 9::bigint, 'renaming a linked person queues nothing');
update public.members set user_id = null, updated_at = 'k03' where id = '00000000-0000-0000-0002-000000000003';
update public.members set user_id = '00000000-0000-0000-0000-000000000002', updated_at = 'k04'
  where id = '00000000-0000-0000-0002-000000000003';
select is(tests.outbox_n(), 9::bigint, 'linking the same account again is deduplicated');

select * from finish();
rollback;
