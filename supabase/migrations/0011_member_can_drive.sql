-- 0011_member_can_drive: who drives, per member (rides fairness).
--
-- Server side of the Drift column `members.can_drive` (schema v4). Only members with
-- can_drive = true are suggested as next driver; everyone drives by default.
-- A constant default makes this a metadata-only change on PG 11+: existing rows read true
-- without a table rewrite.
alter table public.members add column if not exists can_drive boolean not null default true;
