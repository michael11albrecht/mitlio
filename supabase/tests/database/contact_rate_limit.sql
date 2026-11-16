-- Rate limit keys of the contact Edge Function (rate_limits.key_hash must be 16..128 chars, migration 0005).
-- The function sends sha256 hex (64 chars) for both the per-client and the global key.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

set local role service_role;
select is(
  public.consume_rate_limit('3f1c9a7e5b2d4f60a8c1e3d5b7f9021a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d', 50, 50.0 / 86400),
  true, 'global bucket key (64 hex chars) works with capacity 50 per day');
select is(
  public.consume_rate_limit('9b8a7c6d5e4f30211a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f7081', 5, 5.0 / 3600),
  true, 'per-client bucket key (64 hex chars) works with capacity 5 per hour');
select throws_ok($q$select public.consume_rate_limit('contact:global', 50, 50.0 / 86400)$q$, '23514', null,
  'the old 14-char key is rejected by the key_hash check');
select throws_ok($q$select public.consume_rate_limit(repeat('a', 129), 5, 0)$q$, '23514', null,
  'keys longer than 128 chars are rejected');

select * from finish();
rollback;
