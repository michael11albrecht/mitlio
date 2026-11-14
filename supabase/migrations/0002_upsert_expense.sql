-- 0002_upsert_expense: transactional expense upsert with invariants + LWW (P6-T04, plan §2.4, §8).
--
-- public.upsert_expense(payload jsonb) returns jsonb
--   SECURITY DEFINER, set search_path = ''. Justification: replacing payers/shares wholesale needs
--   DELETE on expense_payers/expense_shares, and 0001 deliberately grants `authenticated` no
--   delete on any table (soft delete only; rls_coverage enforces it). A security invoker function
--   therefore cannot do the job. The function compensates for the bypassed RLS with its own gate:
--   right after the payload parse it checks `is_group_member(group_id)` (membership is the sole
--   authority) and it never trusts ids from the payload beyond that check. anon/PUBLIC have no
--   EXECUTE.
--
-- Payload (jsonb object):
--   id, group_id, title, amount_cents, currency, fx_rate_ppm, group_amount_cents, date,
--   type, split_mode, updated_at (HLC) [required]; category, trip_meta, deleted_at [optional];
--   payers: [{member_id, paid_cents}], shares: [{member_id, share_cents, weight?}].
--
-- Errors (all SQLSTATE 23514 check_violation, message is the stable code, details in DETAIL):
--   invalid_payload, amount_not_positive, payers_sum_mismatch, shares_sum_mismatch,
--   duplicate_member, member_not_in_group, group_mismatch.
--   Not a member / anon: 42501 insufficient_privilege.
--
-- LWW: if the stored `updated_at` (HLC, compared with collate "C") is >= the payload's, nothing is
-- written and the server row is returned with applied=false. Equal HLC => replay is a no-op.
-- Soft delete: payload.deleted_at; children are kept/replaced like any other update.
-- Returns {applied, expense: <row incl. server_seq>, payers: [...], shares: [...]}.

set lock_timeout = '1s';
set statement_timeout = '5s';

create function public.upsert_expense(payload jsonb) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_id uuid;
  v_gid uuid;
  v_title text;
  v_amount bigint;
  v_currency text;
  v_fx bigint;
  v_group_amount bigint;
  v_date timestamptz;
  v_category text;
  v_type text;
  v_split text;
  v_trip jsonb;
  v_updated text;
  v_deleted timestamptz;
  v_payers jsonb;
  v_shares jsonb;
  v_payer_sum bigint;
  v_payer_n bigint;
  v_payer_distinct bigint;
  v_payer_bad boolean;
  v_share_sum bigint;
  v_share_n bigint;
  v_share_distinct bigint;
  v_share_bad boolean;
  v_existing public.expenses;
  v_rows bigint;
  v_applied boolean := true;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = 'insufficient_privilege';
  end if;
  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception 'invalid_payload' using errcode = 'check_violation';
  end if;

  begin
    v_id := (payload ->> 'id')::uuid;
    v_gid := (payload ->> 'group_id')::uuid;
    v_title := payload ->> 'title';
    v_amount := (payload ->> 'amount_cents')::bigint;
    v_currency := payload ->> 'currency';
    v_fx := (payload ->> 'fx_rate_ppm')::bigint;
    v_group_amount := (payload ->> 'group_amount_cents')::bigint;
    v_date := (payload ->> 'date')::timestamptz;
    v_category := payload ->> 'category';
    v_type := payload ->> 'type';
    v_split := payload ->> 'split_mode';
    v_trip := nullif(payload -> 'trip_meta', 'null'::jsonb);
    v_updated := payload ->> 'updated_at';
    v_deleted := (payload ->> 'deleted_at')::timestamptz;
    v_payers := payload -> 'payers';
    v_shares := payload -> 'shares';

    if v_id is null or v_gid is null or v_title is null or v_amount is null
       or v_currency is null or v_fx is null or v_group_amount is null or v_date is null
       or v_type is null or v_split is null or v_updated is null
       or v_payers is null or jsonb_typeof(v_payers) <> 'array'
       or v_shares is null or jsonb_typeof(v_shares) <> 'array' then
      raise exception 'invalid_payload' using errcode = 'check_violation';
    end if;

    select coalesce(sum(p.paid_cents), 0), count(*), count(distinct p.member_id),
           coalesce(bool_or(p.member_id is null or p.paid_cents is null or p.paid_cents <= 0), false)
      into v_payer_sum, v_payer_n, v_payer_distinct, v_payer_bad
      from jsonb_to_recordset(v_payers) as p (member_id uuid, paid_cents bigint);

    select coalesce(sum(s.share_cents), 0), count(*), count(distinct s.member_id),
           coalesce(bool_or(s.member_id is null or s.share_cents is null or s.share_cents < 0
                            or coalesce(s.weight, 0) < 0), false)
      into v_share_sum, v_share_n, v_share_distinct, v_share_bad
      from jsonb_to_recordset(v_shares) as s (member_id uuid, share_cents bigint, weight bigint);
  exception
    when data_exception then
      -- bad uuid / number / timestamp / overflow in the payload
      raise exception 'invalid_payload' using errcode = 'check_violation';
  end;

  -- Authorization: membership is the sole authority. 42501 for non-members and strangers.
  if not public.is_group_member(v_gid) then
    raise exception 'not a member of this group' using errcode = 'insufficient_privilege';
  end if;

  -- Invariants (docs/domain-rules.md).
  if v_amount <= 0 or v_group_amount <= 0 or v_payer_bad or v_share_bad then
    raise exception 'amount_not_positive' using errcode = 'check_violation';
  end if;
  if v_payer_n = 0 or v_share_n = 0 then
    raise exception 'invalid_payload' using errcode = 'check_violation',
      detail = 'payers and shares must not be empty';
  end if;
  if v_payer_n <> v_payer_distinct or v_share_n <> v_share_distinct then
    raise exception 'duplicate_member' using errcode = 'check_violation';
  end if;
  if v_payer_sum <> v_amount then
    raise exception 'payers_sum_mismatch' using errcode = 'check_violation',
      detail = format('payers sum %s <> amount_cents %s', v_payer_sum, v_amount);
  end if;
  if v_share_sum <> v_group_amount then
    raise exception 'shares_sum_mismatch' using errcode = 'check_violation',
      detail = format('shares sum %s <> group_amount_cents %s', v_share_sum, v_group_amount);
  end if;
  if exists (
    select 1
    from (
      select p.member_id from jsonb_to_recordset(v_payers) as p (member_id uuid)
      union
      select s.member_id from jsonb_to_recordset(v_shares) as s (member_id uuid)
    ) u
    where not exists (
      select 1 from public.members m where m.id = u.member_id and m.group_id = v_gid
    )
  ) then
    raise exception 'member_not_in_group' using errcode = 'check_violation';
  end if;

  -- Lock the existing row (if any) so concurrent upserts of one expense serialize.
  select * into v_existing from public.expenses e where e.id = v_id for update;
  if not found then
    insert into public.expenses (id, group_id, updated_at, deleted_at, title, amount_cents, currency,
                                 fx_rate_ppm, group_amount_cents, date, category, type, split_mode,
                                 trip_meta)
    values (v_id, v_gid, v_updated, v_deleted, v_title, v_amount, v_currency, v_fx, v_group_amount,
            v_date, v_category, v_type, v_split, v_trip)
    on conflict (id) do nothing;
    get diagnostics v_rows = row_count;
    if v_rows = 0 then
      -- lost an insert race: treat the winner as the existing row
      select * into v_existing from public.expenses e where e.id = v_id for update;
    end if;
  end if;

  if v_existing.id is not null then
    if v_existing.group_id <> v_gid then
      if public.is_group_member(v_existing.group_id) then
        raise exception 'group_mismatch' using errcode = 'check_violation';
      end if;
      -- Do not reveal that the id exists in a group the caller cannot see.
      raise exception 'not a member of this group' using errcode = 'insufficient_privilege';
    end if;
    if v_existing.updated_at collate "C" >= v_updated collate "C" then
      v_applied := false;
    else
      update public.expenses e set
        updated_at = v_updated, deleted_at = v_deleted, title = v_title, amount_cents = v_amount,
        currency = v_currency, fx_rate_ppm = v_fx, group_amount_cents = v_group_amount,
        date = v_date, category = v_category, type = v_type, split_mode = v_split,
        trip_meta = v_trip
      where e.id = v_id;
    end if;
  end if;

  if v_applied then
    delete from public.expense_payers ep where ep.expense_id = v_id;
    delete from public.expense_shares es where es.expense_id = v_id;
    insert into public.expense_payers (group_id, expense_id, member_id, paid_cents)
      select v_gid, v_id, p.member_id, p.paid_cents
      from jsonb_to_recordset(v_payers) as p (member_id uuid, paid_cents bigint);
    insert into public.expense_shares (group_id, expense_id, member_id, share_cents, weight)
      select v_gid, v_id, s.member_id, s.share_cents, coalesce(s.weight, 0)
      from jsonb_to_recordset(v_shares) as s (member_id uuid, share_cents bigint, weight bigint);
  end if;

  select jsonb_build_object(
    'applied', v_applied,
    'expense', to_jsonb(e),
    'payers', coalesce((select jsonb_agg(to_jsonb(p) order by p.member_id)
                        from public.expense_payers p where p.expense_id = e.id), '[]'::jsonb),
    'shares', coalesce((select jsonb_agg(to_jsonb(s) order by s.member_id)
                        from public.expense_shares s where s.expense_id = e.id), '[]'::jsonb))
    into v_result
    from public.expenses e
    where e.id = v_id;
  return v_result;
end;
$$;

revoke all on function public.upsert_expense(jsonb) from public;
revoke all on function public.upsert_expense(jsonb) from anon;
grant execute on function public.upsert_expense(jsonb) to authenticated;
