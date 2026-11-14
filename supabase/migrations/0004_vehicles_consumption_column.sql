-- squawk-ignore-file renaming-column, require-lock-timeout, require-statement-timeout
-- Justification: no hosted project exists yet (nothing reads this column), and the table is empty
-- on any local stack, so the brief ACCESS EXCLUSIVE lock and the rename cannot break a client.
-- 0004: align the server column name with the client Drift schema (P6-T06 drift check).
-- Drift derives `consumption_milli_per100km` from `consumptionMilliPer100km`; 0001 spelled it
-- `consumption_milli_per_100km`. Sync maps columns by name, so the names must be identical.
alter table public.vehicles
  rename column consumption_milli_per_100km to consumption_milli_per100km;
