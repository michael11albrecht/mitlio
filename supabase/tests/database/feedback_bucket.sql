-- In-app feedback bucket (0021, ADR-29): private, size and type limited, no client access, daily cleanup scheduled.
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

select is((select public from storage.buckets where id = 'feedback-screenshots'), false, 'bucket is private');
select is((select file_size_limit from storage.buckets where id = 'feedback-screenshots'), 5242880::bigint,
  'bucket limits files to 5 MB');
select is(
  (select allowed_mime_types from storage.buckets where id = 'feedback-screenshots'),
  array['image/png', 'image/jpeg', 'image/webp', 'application/json'],
  'bucket accepts images and the contact json only');
select ok(exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects'
    and policyname = 'feedback_screenshots_service_only' and permissive = 'RESTRICTIVE'),
  'a restrictive policy fences the bucket off from client roles');
select ok(exists (select 1 from cron.job where jobname = 'feedback-cleanup' and command like '%cleanup_feedback_screenshots%'),
  'feedback-cleanup is scheduled');
select lives_ok($q$select public.cleanup_feedback_screenshots()$q$, 'cleanup is inert without the Vault secrets');
select is(has_function_privilege('anon', 'public.cleanup_feedback_screenshots()', 'execute'), false,
  'anon cannot run the cleanup');
select is(has_function_privilege('authenticated', 'public.cleanup_feedback_screenshots()', 'execute'), false,
  'authenticated cannot run the cleanup');

-- A stored object, as the Edge Function writes it (service role / postgres).
insert into storage.objects (bucket_id, name, owner, metadata)
values ('feedback-screenshots', 'fb-test/1.png', null, '{"mimetype": "image/png"}'::jsonb);

set local role anon;
select is((select count(*) from storage.objects where bucket_id = 'feedback-screenshots'), 0::bigint,
  'anon cannot read feedback files');
reset role;

set local role authenticated;
select is((select count(*) from storage.objects where bucket_id = 'feedback-screenshots'), 0::bigint,
  'authenticated cannot read feedback files');
select throws_ok(
  $q$insert into storage.objects (bucket_id, name) values ('feedback-screenshots', 'fb-test/evil.png')$q$,
  '42501', null, 'authenticated cannot upload into the bucket');
select is_empty(
  $q$delete from storage.objects where bucket_id = 'feedback-screenshots' returning name$q$,
  'authenticated cannot delete feedback files (no rows visible)');
reset role;

select is((select count(*) from storage.objects where bucket_id = 'feedback-screenshots'), 1::bigint,
  'the stored file is still there');

select * from finish();
rollback;
