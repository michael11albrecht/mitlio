# Blockers that need a human (status 2026-11-22)

| # | Blocker | Blocks | Owner action |
|---|---|---|---|
| 1 | Anthropic API credit balance too low for `agent-implement` (CI auth was switched to the subscription OAuth token; confirm the re-run for #210 passes) | all CI agent runs | confirm OAuth token secret is valid, or top up credit |
| 2 | CODEOWNERS review required on `critical` paths (`CLAUDE.md`, `.github/**`, `supabase/migrations/**`, `tool/*_gate.dart`) | merging the open PRs below | review and approve |
| 3 | ~~Android `android-build (dev apk)` fails on Gradle~~ **Resolved, no owner action.** Only failure was run 44801038184 (2026-11-20, `agent/worktree-rule`): `plugins.gradle.org` could not serve `kotlin-stdlib`/`kotlin-gradle-plugin` 2.3.20 while resolving the Flutter plugin loader, a transient artifact-repository outage (not a settings.gradle, Flutter pin, Java or keystore problem). Since then the job is green on every run, incl. main run 44904403742 and 44899907745 (dev debug APK builds, ~5 min). If it recurs, re-run the job first | Android internal builds, P8-T03 Play half | none; re-run CI on a recurrence |
| 4 | Play Console: service account + keystore secrets | Play internal track | create and add secrets |
| 5 | Supabase. `Mitlio` (`vnlshkpxcvriiaguniro`) is staging: `fx-rates`, `contact`, `route-distance`, `fuel-prices` deployed; only `FUEL_ALLOWED_ORIGINS`, `ORS_API_KEY` set. `mitlio-prod` (`bbkhmqdseazczsgltuto`) has migrations 0001-0014 and the 4 Edge Functions (#271), app prod config points at it. Open per project: secrets `RESEND_API_KEY`, `CONTACT_TO`, `CONTACT_FROM` (else `contact` returns `503 not_configured`), `TANKERKOENIG_API_KEY` (item 15), optional `CONTACT_ALLOWED_ORIGINS`, `FX_ALLOWED_ORIGINS`, `*_RATE_LIMIT_SALT` (fall back to service role key). `production` environment approval. The CLI labels `Mitlio` as `production`: relabel | prod secrets, release workflow | set reviewers + secrets |
| 6 | Firebase: `mitlio` (prod) and `mitlio-dev` each have iOS + Android apps. Open for P6b-T01: upload FCM service account and APNs auth key (.p8) per project. For `notify` (P6b-T05) set the Edge Function secrets `FCM_SERVICE_ACCOUNT` (JSON), `FCM_ENDPOINT`, `NOTIFY_TOKEN` and the Vault secrets `notify_url`, `notify_anon_key`, `notify_token` per project (see `supabase/README.md`). App side is merged (#252, `UnavailablePushService` default); T01 adds `firebase_messaging` + `flutter_local_notifications`, a `PushService` impl registered in `main` only with a Firebase config, and `Localizable.strings` in the Xcode project | P6b-T01, T05 live test | create and upload keys |
| 7 | Legal texts (Impressum, Datenschutz) are drafts | store submission, P7-T07 sign-off | review with lawyer / sign off |
| 8 | Apple Associated Domains / AASA for `mitlio.de` must be live and match the profile | universal join links on device | verify domain + hosting |
| 9 | P5 field test on a real trip | go-live confidence; new fixtures | drive, file `field-test` issues |
| 10 | Receipt fixtures (~30 anonymised receipts) | P9r-T02 | collect and anonymise |
| 11 | ADR-28 owner question 13 (support tip) | P7-T09 | decide model (link vs. IAP), App Store 3.1.1 |
| 12 | PU decisions: avatar column (profile); PBefG hint wording and default fuel prices/flat rate/consumption table (#254); monthly settle +2 taps; first-run commute path; QR hint wording; step titles de/en; illustration goldens | PU polish, release | decide |
| 13 | Search Console / Bing verification (DNS TXT) | PW-T11 | add DNS record |
| 14 | Store listings, screenshots, privacy nutrition labels | release | create in App Store Connect / Play |
| 15 | ~~Tankerkönig API key~~ **Resolved (2026-11-22).** Key received and set as `TANKERKOENIG_API_KEY` on `mitlio-prod` and `Mitlio` (staging). Verified: `fuel-prices?type=e5&lat=52.52&lng=13.405&radius=5` returns 200, `source: tankerkoenig`, with the CC BY 4.0 attribution on both. Open: confirm Tankerkönig rate limits against our cache TTL and rotate the key at some point (it was sent by mail) | P6c, PW-T04 live prices | rotate key later; confirm rate limits |
| 16 | Routing: `ORS_API_KEY` is set on staging only (not on `mitlio-prod`). Open: set it on prod, rotate the key (it was pasted into a session transcript), optional `GEOAPIFY_API_KEY` fallback, quota/ToS spike + ADR for #130, confirm the ORS endpoint is current | P9-T08 | rotate key, set on prod, add Geoapify later, decide #130 |
| 17 | ~~Supabase CLI 3 config + CI pin~~ Merged (#262). Remaining nit: CLI warns `auth.email.enable_signup` deprecated (use `auth.email.enabled`, removed in v4) and `--project-ref` for `--remote` | none | none |
| 18 | E-Control (Austria) fuel API terms for ADR-20 not confirmed | AT fuel prices | check terms |
| 19 | #206 Supabase Auth audit logs must not be stored in the DB (`auth.audit_log_entries` survives `delete from auth.users`). Hosted-project dashboard toggle only, not expressible in `supabase/config.toml` (never pushed). Do it on staging and on prod (`mitlio-prod`), then run the check in `supabase/README.md` (expect `0`). Same visit: anonymous sign-ins rate limit 10/h per IP, usage alerts | sync go-live, privacy text | switch off the toggle per project, run the check |
| 20 | Feedback (ADR-29): GitHub App or fine-grained PAT with `issues:write` only, stored as Supabase function secret (never in the app) | P7-T10 (#230) | create the credential (ADR-29 accepted, #229) |
| 21 | Feedback (ADR-29): private Supabase Storage bucket for screenshots + retention period and cleanup schedule | P7-T10 (#230) | create bucket, decide retention |
| 22 | Feedback (ADR-29): privacy policy update (free-text, screenshots, optional email, diagnostics, retention) | P7-T10, P7-T07 sign-off | update the Datenschutz draft, review with item 7 |
| 23 | P7-T08 Sentry (app side merged, #241): create the EU Sentry project, add `SENTRY_DSN` per flavor (`app/config/{dev,prod}.json` stay empty in the repo, pass as CI secret/dart-define), add `SENTRY_AUTH_TOKEN`, and add the `--split-debug-info` + `sentry_dart_plugin` upload step to the release workflow (steps in `docs/release.md`; touches `.github/workflows/**`, critical). Set project retention to 30 days | crash reports in release builds; also needs the P6b-T10 monitor (#268) | create project and secrets, review the workflow change |

## Open PRs (owner action)

| PR | What | Action |
|---|---|---|
| #253 | P6b-T05 `notify` function | stale bot CHANGES_REQUESTED: dismiss, then review/merge |
| #251 | #206 audit-log delete + purge, migration 0017 | stale bot CHANGES_REQUESTED: dismiss; check CI `db`, renumber if needed |
| #268 | P6b-T10 notify monitoring, Sentry check-ins | stacked on #253: merge after |
| #226 | release 0.4.0 | merge when ready to cut |
