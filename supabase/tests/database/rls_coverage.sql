-- RLS coverage gate (P6-T03, plan §8). Fails when a table in `public`:
--   * has RLS disabled,
--   * is not in the registry below (i.e. has no tests in rls_policies.sql), or
--   * is reachable by anon, deletable by authenticated, or has a policy for another role.
-- Adding a table => add it to the registry here AND to TABLES in rls_policies.sql.
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

select is_empty(
  $q$select c.relname
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity$q$,
  'every table in public has RLS enabled');

select is_empty(
  $q$select tablename from pg_tables where schemaname = 'public'
     except
     select unnest(array[
       'groups', 'members', 'expenses', 'expense_payers', 'expense_shares',
       'settlements', 'vehicles', 'ride_templates', 'rides',
       'group_memberships', 'group_invites', 'fuel_price_cache', 'rate_limits',
       'expense_revisions'
     ])$q$,
  'every table in public is in the RLS test registry (add new tables here and in rls_policies.sql)');

select is_empty(
  $q$select unnest(array[
       'groups', 'members', 'expenses', 'expense_payers', 'expense_shares',
       'settlements', 'vehicles', 'ride_templates', 'rides',
       'group_memberships', 'group_invites', 'fuel_price_cache', 'rate_limits',
       'expense_revisions'
     ])
     except
     select tablename from pg_tables where schemaname = 'public'$q$,
  'every table in the RLS test registry exists');

select is_empty(
  $q$select c.relname
     from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind in ('r', 'p')
       and (case when c.relname = 'fuel_price_cache'
                 then has_table_privilege('anon', c.oid,
                        'insert, update, delete, truncate, references, trigger')
                 else has_table_privilege('anon', c.oid,
                        'select, insert, update, delete, truncate, references, trigger')
            end
            or has_table_privilege('authenticated', c.oid,
              'delete, truncate, references, trigger')
            or (c.relname in ('fuel_price_cache', 'expense_revisions')
                and has_table_privilege('authenticated', c.oid, 'insert, update')))$q$,
  'anon has no table privileges (fuel_price_cache: select only); authenticated has no delete/truncate/references/trigger, and no write on fuel_price_cache / expense_revisions');

select is_empty(
  $q$select tablename, policyname from pg_policies
     where schemaname = 'public' and roles <> array['authenticated']::name[]
       and not (tablename = 'fuel_price_cache' and cmd = 'SELECT'
                and roles <@ array['anon', 'authenticated']::name[])$q$,
  'every policy targets exactly the authenticated role (anon/public never); only fuel_price_cache has a public read');

select is_empty(
  $q$select tablename, policyname from pg_policies
     where schemaname = 'public' and cmd in ('DELETE', 'ALL')$q$,
  'no delete or catch-all policies exist (soft delete only)');

select * from finish();
rollback;
