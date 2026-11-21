-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the functions
-- and triggers are created here and nothing else defines them.
-- 0016_notification_triggers: writes of expenses, settlements and members feed the outbox
-- (P6b-T03, ADR-13, plan §7 P6b).
--
-- Rules (plan P6b "design rules"):
--   * Only a signed-in actor counts (auth.uid() not null). Service-role and migration writes are
--     silent.
--   * Only user-visible changes: a new expense, a soft delete, and an edit that changes the amount,
--     the currency, the payers or the shares. A title, category, date or note edit writes nothing.
--     Un-deleting an expense counts as added.
--   * Idempotent: `dedupe_key` is unique, the key of an expense event contains the HLC of the row
--     version. A replayed sync (same HLC) never updates the row (upsert_expense returns
--     applied=false), and even if it did, the second insert is a no-op.
--   * Payload = ids and display strings only (title, amount, currency, names). Never IBAN or notes.
--     `involved_member_ids` (payers and shares of an expense, from/to of a settlement) feeds the
--     "only mine" level.
--
-- Why the expense trigger is a DEFERRED constraint trigger: public.upsert_expense updates the
-- expenses row first and replaces payers and shares afterwards, so an immediate trigger would see
-- the old children. Deferred to COMMIT, the trigger sees the final state. The previous state of
-- payers and shares is the newest expense_revisions snapshot, which record_expense_revision (0007)
-- wrote in the same transaction.
--
-- Settlements and members have no child rows, so their triggers are immediate.
-- members: only a person that gets linked to an account (user_id null -> not null, claim or
-- connect) counts as "joined"; a join without claiming a person creates no member row here.

set lock_timeout = '1s';
set statement_timeout = '5s';

-- SECURITY DEFINER: clients have no grant on notification_outbox. Called only by the trigger
-- functions below; no EXECUTE for clients.
create function public.enqueue_notification(
  p_group_id uuid, p_actor uuid, p_event text, p_entity_id uuid, p_dedupe_key text,
  p_payload jsonb
) returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notification_outbox (group_id, actor_user_id, event, entity_id, dedupe_key,
                                          payload)
  select p_group_id, p_actor, p_event, p_entity_id, p_dedupe_key,
         jsonb_strip_nulls(p_payload || jsonb_build_object(
           'group_name', g.name,
           'actor_name', (
             select m.name
             from public.group_memberships gm
             join public.members m on m.id = gm.member_id and m.group_id = gm.group_id
             where gm.group_id = p_group_id and gm.user_id = p_actor)))
  from public.groups g
  where g.id = p_group_id
  on conflict (dedupe_key) do nothing;
$$;

revoke all on function public.enqueue_notification(uuid, uuid, text, uuid, text, jsonb)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- expenses (deferred to commit, see header)
-- ---------------------------------------------------------------------------
create function public.notify_expense_written() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_cur public.expenses;
  v_event text;
  v_snap jsonb;
  v_payers jsonb;
  v_shares jsonb;
  v_unchanged boolean;
begin
  if v_actor is null then
    return null;
  end if;
  select * into v_cur from public.expenses e where e.id = new.id;
  if not found then
    return null;
  end if;

  if tg_op = 'INSERT' then
    if v_cur.deleted_at is not null then
      return null;
    end if;
    v_event := 'expense_added';
  elsif old.deleted_at is not null and v_cur.deleted_at is not null then
    return null;
  elsif old.deleted_at is null and v_cur.deleted_at is not null then
    v_event := 'expense_deleted';
  elsif old.deleted_at is not null then
    v_event := 'expense_added';
  else
    -- live -> live: only amount, currency, payers and shares are user-visible.
    select r.snapshot into v_snap
    from public.expense_revisions r
    where r.expense_id = v_cur.id
    order by r.revision desc
    limit 1;

    v_unchanged := false;
    if v_snap is not null and old.amount_cents = v_cur.amount_cents
       and old.group_amount_cents = v_cur.group_amount_cents
       and old.currency = v_cur.currency then
      select
        coalesce((select jsonb_agg(jsonb_build_object(
                    'member_id', p.member_id::text, 'paid_cents', p.paid_cents)
                  order by p.member_id::text)
                  from public.expense_payers p where p.expense_id = v_cur.id), '[]'::jsonb),
        coalesce((select jsonb_agg(jsonb_build_object(
                    'member_id', s.member_id::text, 'share_cents', s.share_cents)
                  order by s.member_id::text)
                  from public.expense_shares s where s.expense_id = v_cur.id), '[]'::jsonb)
      into v_payers, v_shares;
      v_unchanged :=
        v_payers = coalesce((select jsonb_agg(jsonb_build_object(
                    'member_id', e ->> 'member_id', 'paid_cents', (e ->> 'paid_cents')::bigint)
                  order by e ->> 'member_id')
                  from jsonb_array_elements(v_snap -> 'payers') e), '[]'::jsonb)
        and v_shares = coalesce((select jsonb_agg(jsonb_build_object(
                    'member_id', e ->> 'member_id', 'share_cents', (e ->> 'share_cents')::bigint)
                  order by e ->> 'member_id')
                  from jsonb_array_elements(v_snap -> 'shares') e), '[]'::jsonb);
    end if;
    if v_unchanged then
      return null;
    end if;
    v_event := 'expense_changed';
  end if;

  perform public.enqueue_notification(
    v_cur.group_id, v_actor, v_event, v_cur.id,
    v_event || ':' || v_cur.id::text || ':' || v_cur.updated_at,
    jsonb_build_object(
      'title', v_cur.title,
      'amount_cents', v_cur.amount_cents,
      'currency', v_cur.currency,
      'involved_member_ids', coalesce((
        select jsonb_agg(u.member_id::text order by u.member_id::text)
        from (
          select p.member_id from public.expense_payers p where p.expense_id = v_cur.id
          union
          select s.member_id from public.expense_shares s where s.expense_id = v_cur.id
        ) u), '[]'::jsonb)));
  return null;
end;
$$;

create constraint trigger notify_expense_insert after insert on public.expenses
  deferrable initially deferred
  for each row execute function public.notify_expense_written();
create constraint trigger notify_expense_update after update on public.expenses
  deferrable initially deferred
  for each row when (old.updated_at is distinct from new.updated_at)
  execute function public.notify_expense_written();

-- ---------------------------------------------------------------------------
-- settlements: a new, live settlement
-- ---------------------------------------------------------------------------
create function public.notify_settlement_written() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
begin
  if v_actor is null then
    return null;
  end if;
  perform public.enqueue_notification(
    new.group_id, v_actor, 'settlement_added', new.id, 'settlement_added:' || new.id::text,
    jsonb_build_object(
      'amount_cents', new.amount_cents,
      'currency', new.currency,
      'involved_member_ids', jsonb_build_array(new.from_member::text, new.to_member::text)));
  return null;
end;
$$;

create trigger notify_settlement_insert after insert on public.settlements
  for each row when (new.deleted_at is null)
  execute function public.notify_settlement_written();

-- ---------------------------------------------------------------------------
-- members: a person gets linked to an account
-- ---------------------------------------------------------------------------
create function public.notify_member_joined() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- The person that was linked is the actor; the join RPCs run as that user.
  perform public.enqueue_notification(
    new.group_id, new.user_id, 'member_joined', new.id,
    'member_joined:' || new.id::text || ':' || new.user_id::text,
    jsonb_build_object('member_name', new.name));
  return null;
end;
$$;

create trigger notify_member_joined after update on public.members
  for each row when (old.user_id is null and new.user_id is not null and new.deleted_at is null)
  execute function public.notify_member_joined();

revoke all on function public.notify_expense_written() from public, anon, authenticated;
revoke all on function public.notify_settlement_written() from public, anon, authenticated;
revoke all on function public.notify_member_joined() from public, anon, authenticated;
