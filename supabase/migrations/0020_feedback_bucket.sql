-- squawk-ignore-file prefer-robust-stmts
-- Justification: the Supabase CLI applies each migration file once, in a transaction; the bucket is created
-- with "on conflict do nothing" and the policy and the function are new in this file.
-- 0020_feedback_bucket: private Storage bucket for in-app feedback + daily retention call (P7-T10, ADR-29).
--
-- Privacy model:
--   * The bucket is private. Screenshots and the optional reply address (`<id>/contact.json`) are written
--     by the `submit-feedback` Edge Function with the service role only; the service role bypasses RLS.
--   * anon and authenticated get no access at all: there is no permissive policy, and the restrictive policy
--     below keeps it that way even if someone later adds a broad "authenticated can read storage.objects" policy.
--   * 5 MB per file and image/json types only, enforced by Storage itself (the function validates too).
--   * Retention (`feedback_days` in supabase/retention.json, docs/retention.md): the daily job calls the Edge
--     Function, which deletes old files through the Storage API. A SQL delete on storage.objects would leave the
--     files in the object store, so it is deliberately not used. Inert until the owner stores the Vault secrets
--     feedback_url, feedback_anon_key and feedback_cleanup_token.

set lock_timeout = '1s';
set statement_timeout = '5s';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'feedback-screenshots', 'feedback-screenshots', false, 5242880,
  array['image/png', 'image/jpeg', 'image/webp', 'application/json']
)
on conflict (id) do nothing;

create policy feedback_screenshots_service_only on storage.objects
  as restrictive
  for all
  to anon, authenticated
  using (bucket_id <> 'feedback-screenshots')
  with check (bucket_id <> 'feedback-screenshots');

create or replace function public.cleanup_feedback_screenshots() returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_anon text;
  v_token text;
begin
  if to_regclass('vault.decrypted_secrets') is null then
    return;
  end if;
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_url using 'feedback_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_anon using 'feedback_anon_key';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_token using 'feedback_cleanup_token';
  if coalesce(v_url, '') = '' or coalesce(v_anon, '') = '' or coalesce(v_token, '') = '' then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_anon,
      'apikey', v_anon,
      'x-feedback-cleanup', v_token));
end;
$$;
revoke all on function public.cleanup_feedback_screenshots() from public, anon, authenticated;

select cron.schedule('feedback-cleanup', '41 3 * * *', 'select public.cleanup_feedback_screenshots()');
