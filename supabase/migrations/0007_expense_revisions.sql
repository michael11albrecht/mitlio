-- squawk-ignore-file prefer-robust-stmts, require-concurrent-index-creation
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the table,
-- its indexes and the function are created here on a table that does not exist yet, so nothing is
-- re-run and no write can be blocked.
-- 0007_expense_revisions: server side of the expense edit history (P7-T03, plan §7 P7 row T03).
--
-- Model (mirrors the client `expense_revisions` table, Drift schema v3):
--   * One row per applied change of an expense (edit or soft delete). `snapshot` is the aggregate
--     as it was BEFORE the change: title, amounts, currency, frozen fx rate, date, category, type,
--     split mode, trip meta, payers [{member_id, paid_cents}], shares [{member_id, share_cents,
--     weight}]. Creation writes no row (revision 1 is the first edit).
--   * `revision` counts up per expense; the newest 50 are kept, older ones are pruned by the same
--     trigger.
--   * Written only by the trigger below. Group members may select; clients have no insert, update
--     or delete grant and no such policy (rls_coverage keeps it that way).
--   * `author_member_id` is group_memberships.member_id of auth.uid() (null when the caller is not
--     yet linked to a member, or for service-role writes).
--
-- Capturing payers and shares: public.upsert_expense updates the expenses row first and replaces
-- expense_payers / expense_shares afterwards. The AFTER UPDATE trigger therefore still sees the
-- old children when it runs, so a hook inside upsert_expense is not needed; direct client updates
-- of expenses (RLS allows them) are covered the same way. The trigger is skipped when updated_at
-- (the HLC) did not change, and upsert_expense never updates a row on a replayed or stale HLC, so
-- replays cannot create duplicate revisions.

set lock_timeout = '1s';
set statement_timeout = '5s';

create table public.expense_revisions (
  id uuid primary key default gen_random_uuid(),
  expense_id uuid not null,
  group_id uuid not null references public.groups (id),
  revision bigint not null check (revision > 0),
  changed_at timestamptz not null default now(),
  author_member_id uuid,
  snapshot jsonb not null check (octet_length(snapshot::text) <= 262144),
  unique (expense_id, revision),
  foreign key (expense_id, group_id) references public.expenses (id, group_id),
  foreign key (author_member_id, group_id) references public.members (id, group_id)
);

create index expense_revisions_group_id on public.expense_revisions (group_id);
create index expense_revisions_author_member_id on public.expense_revisions (author_member_id);

alter table public.expense_revisions enable row level security;
grant select on public.expense_revisions to authenticated;
create policy expense_revisions_select on public.expense_revisions for select to authenticated
  using (public.is_group_member(group_id));

-- SECURITY DEFINER: clients have no insert/delete grant on expense_revisions, and the trigger must
-- write and prune it. It takes no input from the caller beyond the OLD/NEW rows of the statement.
create function public.record_expense_revision() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_next bigint;
  v_author uuid;
begin
  select gm.member_id into v_author
    from public.group_memberships gm
    where gm.group_id = old.group_id and gm.user_id = (select auth.uid());

  -- The UPDATE holds the expense row lock, so concurrent changes of one expense serialize here.
  select coalesce(max(r.revision), 0) + 1 into v_next
    from public.expense_revisions r
    where r.expense_id = old.id;

  insert into public.expense_revisions (expense_id, group_id, revision, author_member_id, snapshot)
  values (
    old.id, old.group_id, v_next, v_author,
    jsonb_build_object(
      'title', old.title,
      'amount_cents', old.amount_cents,
      'currency', old.currency,
      'fx_rate_ppm', old.fx_rate_ppm,
      'group_amount_cents', old.group_amount_cents,
      'date', old.date,
      'category', old.category,
      'type', old.type,
      'split_mode', old.split_mode,
      'trip_meta', old.trip_meta,
      'payers', coalesce((
        select jsonb_agg(jsonb_build_object('member_id', p.member_id, 'paid_cents', p.paid_cents)
                         order by p.member_id)
        from public.expense_payers p where p.expense_id = old.id), '[]'::jsonb),
      'shares', coalesce((
        select jsonb_agg(jsonb_build_object('member_id', s.member_id, 'share_cents', s.share_cents,
                                            'weight', s.weight)
                         order by s.member_id)
        from public.expense_shares s where s.expense_id = old.id), '[]'::jsonb)));

  -- Retention: keep the newest 50 per expense.
  delete from public.expense_revisions r
    where r.expense_id = old.id and r.revision <= v_next - 50;
  return null;
end;
$$;

revoke all on function public.record_expense_revision() from public;
revoke all on function public.record_expense_revision() from anon;
revoke all on function public.record_expense_revision() from authenticated;

create trigger record_expense_revision after update on public.expenses
  for each row when (old.updated_at is distinct from new.updated_at)
  execute function public.record_expense_revision();
