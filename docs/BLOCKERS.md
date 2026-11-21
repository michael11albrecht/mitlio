# Blockers that need a human (status 2026-11-20)

| # | Blocker | Blocks | Owner action |
|---|---|---|---|
| 1 | Anthropic API credit balance too low for `agent-implement` (CI auth was switched to the subscription OAuth token; confirm the re-run for #210 passes) | all CI agent runs | confirm OAuth token secret is valid, or top up credit |
| 2 | CODEOWNERS review required on `critical` paths (`CLAUDE.md`, `.github/**`, `supabase/migrations/**`, `tool/*_gate.dart`) | merging #206, P8-T04/T08, P6b migrations | review and approve |
| 3 | ~~Android `android-build (dev apk)` fails on Gradle~~ **Resolved, no owner action.** Only failure was run 44801038184 (2026-11-20, `agent/worktree-rule`): `plugins.gradle.org` could not serve `kotlin-stdlib`/`kotlin-gradle-plugin` 2.3.20 while resolving the Flutter plugin loader, a transient artifact-repository outage (not a settings.gradle, Flutter pin, Java or keystore problem). Since then the job is green on every run, incl. main run 44904403742 and 44899907745 (dev debug APK builds, ~5 min). If it recurs, re-run the job first | Android internal builds, P8-T03 Play half | none; re-run CI on a recurrence |
| 4 | Play Console: service account + keystore secrets | Play internal track | create and add secrets |
| 5 | Supabase projects. `Mitlio` (`vnlshkpxcvriiaguniro`, eu-central-1) is **staging**: `fx-rates`, `contact`, `route-distance`, `fuel-prices` deployed; only `FUEL_ALLOWED_ORIGINS` and `ORS_API_KEY` set. Missing there: `RESEND_API_KEY`, `CONTACT_TO`, `CONTACT_FROM` (required for `contact`, else `503 not_configured`), `TANKERKOENIG_API_KEY` (item 15), and optional `CONTACT_ALLOWED_ORIGINS`, `FX_ALLOWED_ORIGINS` (no origin allowed without it), `FX_RATE_LIMIT_SALT`, `FUEL_RATE_LIMIT_SALT`, `CONTACT_RATE_LIMIT_SALT`, `ROUTE_RATE_LIMIT_SALT` (all fall back to the service role key). `mitlio-prod` (`bbkhmqdseazczsgltuto`, created 2026-11-20) is **empty**: no functions, no secrets, migrations not pushed. Note: the Supabase CLI labels `Mitlio` as `production` (project setting), relabel it to avoid mixups. Still open: push migrations and deploy functions to prod, `production` environment approval, set the secrets above per project | P8-T04 release workflow, P6b | set environment reviewers, set secrets, run the prod deploy |
| 6 | Firebase: projects `mitlio` (prod) and `mitlio-dev` each already have an iOS and an Android app registered. Still open for P6b-T01: upload the FCM service account (as Supabase function secret for `notify`) and the APNs auth key (.p8) in the Firebase console per project | P6b-T01, T05 live test | create and upload keys |
| 7 | Legal texts (Impressum, Datenschutz) are drafts | store submission, P7-T07 sign-off | review with lawyer / sign off |
| 8 | Apple Associated Domains / AASA for `mitlio.de` must be live and match the profile | universal join links on device | verify domain + hosting |
| 9 | P5 field test on a real trip | go-live confidence; new fixtures | drive, file `field-test` issues |
| 10 | Receipt fixtures (~30 anonymised receipts) | P9r-T02 | collect and anonymise |
| 11 | ADR-28 owner question 13 (support tip) | P7-T09 | decide model (link vs. IAP), App Store 3.1.1 |
| 12 | PU-T06 illustrations and wording of the PBefG hint need owner judgement | PU merge | review goldens |
| 13 | Search Console / Bing verification (DNS TXT) | PW-T11 | add DNS record |
| 14 | Store listings, screenshots, privacy nutrition labels | release | create in App Store Connect / Play |
| 15 | Tankerkönig API key: applied for, not received yet. Then `supabase secrets set TANKERKOENIG_API_KEY=... --remote=<ref> --yes`. Until then nearby/PLZ prices return `503 provider_unconfigured`, national falls back to the EU oil bulletin | P6c, PW-T04 live prices | wait for key, set secret; confirm CC BY 4.0 attribution and rate limits |
| 16 | Routing: `ORS_API_KEY` is set on staging only (not on `mitlio-prod`). Open: set it on prod, rotate the key (it was pasted into a session transcript), optional `GEOAPIFY_API_KEY` fallback, quota/ToS spike + ADR for #130, confirm the ORS endpoint is current | P9-T08 | rotate key, set on prod, add Geoapify later, decide #130 |
| 17 | Fixed in the PR `agent/supabase-cli-3`: `supabase/config.toml` uses `[local_smtp]` and CI pins Supabase CLI 3.2.0 in `db`, `deploy-dev`, `deploy-prod`, `sync-e2e` (verified locally: `supabase start`, `db reset`, `test db` pass on CLI 3.2.0). Owner: review and merge (touches `.github/workflows/**`, critical). Remaining nit: CLI warns `auth.email.enable_signup` is deprecated (use `auth.email.enabled`, removal in v4) and `--project-ref` is deprecated for `--remote` | CI CLI bump | review PR |
| 18 | E-Control (Austria) fuel API terms for ADR-20 not confirmed | AT fuel prices | check terms |
| 19 | #206 Supabase Auth audit logs must not be stored in the DB (`auth.audit_log_entries` survives `delete from auth.users`). Hosted-project dashboard toggle only, not expressible in `supabase/config.toml` (never pushed). Do it on staging and on prod (`mitlio-prod`), then run the check in `supabase/README.md` (expect `0`). Same visit: anonymous sign-ins rate limit 10/h per IP, usage alerts | sync go-live, privacy text | switch off the toggle per project, run the check |
| 20 | Feedback (ADR-29): GitHub App or fine-grained PAT with `issues:write` only, stored as Supabase function secret (never in the app) | P7-T10 (#230) | create the credential after ADR-29 is accepted |
| 21 | Feedback (ADR-29): private Supabase Storage bucket for screenshots + retention period and cleanup schedule | P7-T10 (#230) | create bucket, decide retention |
| 22 | Feedback (ADR-29): privacy policy update (free-text, screenshots, optional email, diagnostics, retention) | P7-T10, P7-T07 sign-off | update the Datenschutz draft, review with item 7 |
| 23 | P7-T08 Sentry release wiring: create the EU Sentry project, add `SENTRY_DSN` per flavor (`app/config/{dev,prod}.json` stay empty in the repo, pass as CI secret/dart-define), add `SENTRY_AUTH_TOKEN`, and add the `--split-debug-info` + `sentry_dart_plugin` upload step to the release workflow (steps in `docs/release.md`; touches `.github/workflows/**`, critical). Set project retention to 30 days | crash reports in release builds | create project and secrets, review the workflow change |

## Owner review queue (critical PRs, code-owner review required)

Updated 2026-11-21. Agents cannot merge these. Merge order matters where marked.

| PR | What | Why critical / what you decide |
|---|---|---|
| #229 | ADR-29 in-app feedback | accept or reject; blocks #230 |
| #239 | PU-T04 profile + personal vehicles tables, schema v7 | schema, PII (IBAN stays local) |
| #245 | PU-T05 guided setup step-flow framework | ux-review, golden look |
| #247 | PU-T06 illustrations (CustomPainter) | owner judges goldens (decision #11) |
| #249 | PU-T07 profile flow | stacked: merge after #239, #245 |
| #254 | PU-T08/T09 car + cost-calculator flows | stacked: merge after #239, #245. Confirm: PBefG hint wording, flat rate, typical-consumption table, default fuel prices; personal cars EUR only for now |
| #246 | P6b-T02..T04 push tables, outbox trigger, notify logic | migrations 0015/0016, RLS |
| #253 | P6b-T05 `notify` function + FCM stub | stacked on #246 |
| #252 | P6b app-side push with fakes | ux-review; no Firebase yet (T01 is item 6) |
| #251 | #206 audit-log delete + purge | migration 0017, renumber if merge order changes; check CI `db` first |
| #242 | P8-T06 release-strip gate | `.github/**` |
| #243 | P8-T08 `agent-fix-ci` workflow | `.github/**` |
