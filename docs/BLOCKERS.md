# Blockers that need a human (status 2026-11-20)

| # | Blocker | Blocks | Owner action |
|---|---|---|---|
| 1 | Anthropic API credit balance too low for `agent-implement` (CI auth was switched to the subscription OAuth token; confirm the re-run for #210 passes) | all CI agent runs | confirm OAuth token secret is valid, or top up credit |
| 2 | CODEOWNERS review required on `critical` paths (`CLAUDE.md`, `.github/**`, `supabase/migrations/**`, `tool/*_gate.dart`) | merging #206, P8-T04/T08, P6b migrations | review and approve |
| 3 | Android `android-build (dev apk)` fails on Gradle: cannot resolve the Flutter plugin loader | Android internal builds, P8-T03 Play half | check Gradle/Flutter plugin setup on CI |
| 4 | Play Console: service account + keystore secrets | Play internal track | create and add secrets |
| 5 | Production Supabase project `Mitlio` (`vnlshkpxcvriiaguniro`, eu-central-1) exists with `ORS_API_KEY` set; still open: remaining secrets, `production` environment approval, check which Edge Functions are deployed | P8-T04 release workflow, P6b | set environment reviewers, remaining secrets |
| 6 | Firebase project, APNs auth key, FCM service account | P6b-T01, T05 live test | create and upload keys |
| 7 | Legal texts (Impressum, Datenschutz) are drafts | store submission, P7-T07 sign-off | review with lawyer / sign off |
| 8 | Apple Associated Domains / AASA for `mitlio.de` must be live and match the profile | universal join links on device | verify domain + hosting |
| 9 | P5 field test on a real trip | go-live confidence; new fixtures | drive, file `field-test` issues |
| 10 | Receipt fixtures (~30 anonymised receipts) | P9r-T02 | collect and anonymise |
| 11 | ADR-28 owner question 13 (support tip) | P7-T09 | decide model (link vs. IAP), App Store 3.1.1 |
| 12 | PU-T06 illustrations and wording of the PBefG hint need owner judgement | PU merge | review goldens |
| 13 | Search Console / Bing verification (DNS TXT) | PW-T11 | add DNS record |
| 14 | Store listings, screenshots, privacy nutrition labels | release | create in App Store Connect / Play |
| 15 | Tankerkönig API key: applied for, not received yet. Then `supabase secrets set TANKERKOENIG_API_KEY=... --remote=<ref> --yes`. Until then nearby/PLZ prices return `503 provider_unconfigured`, national falls back to the EU oil bulletin | P6c, PW-T04 live prices | wait for key, set secret; confirm CC BY 4.0 attribution and rate limits |
| 16 | Routing: `ORS_API_KEY` is set. Open: rotate the key (it was pasted into a session transcript), optional `GEOAPIFY_API_KEY` fallback, quota/ToS spike + ADR for #130, confirm the ORS endpoint is current | P9-T08 | rotate key, add Geoapify later, decide #130 |
| 17 | Supabase CLI 3.x rejects `[inbucket]` in `supabase/config.toml` (wants `local_smtp`), CI pins CLI 2.70.0 which needs `inbucket`. Local CLI 3.x works only from a directory without `supabase/config.toml` | local `supabase` use, CI CLI bump | decide: pin CI to 3.x and rename, or keep 2.x (touches `.github/workflows/**`, critical) |
| 18 | E-Control (Austria) fuel API terms for ADR-20 not confirmed | AT fuel prices | check terms |
| 19 | #206 Supabase Auth audit logs must not be stored in the DB (`auth.audit_log_entries` survives `delete from auth.users`). Hosted-project dashboard toggle only, not expressible in `supabase/config.toml` (never pushed). Do it on staging and on prod (`mitlio-prod`), then run the check in `supabase/README.md` (expect `0`). Same visit: anonymous sign-ins rate limit 10/h per IP, usage alerts | sync go-live, privacy text | switch off the toggle per project, run the check |
