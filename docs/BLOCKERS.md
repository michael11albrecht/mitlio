# Blockers that need a human (status 2026-11-20)

| # | Blocker | Blocks | Owner action |
|---|---|---|---|
| 1 | Anthropic API credit balance too low for `agent-implement` (CI auth was switched to the subscription OAuth token; confirm the re-run for #210 passes) | all CI agent runs | confirm OAuth token secret is valid, or top up credit |
| 2 | CODEOWNERS review required on `critical` paths (`CLAUDE.md`, `.github/**`, `supabase/migrations/**`, `tool/*_gate.dart`) | merging #206, P8-T04/T08, P6b migrations | review and approve |
| 3 | Android `android-build (dev apk)` fails on Gradle: cannot resolve the Flutter plugin loader | Android internal builds, P8-T03 Play half | check Gradle/Flutter plugin setup on CI |
| 4 | Play Console: service account + keystore secrets | Play internal track | create and add secrets |
| 5 | Production Supabase project and secrets, `production` environment approval | P8-T04 release workflow, P6b | create project, set environment reviewers |
| 6 | Firebase project, APNs auth key, FCM service account | P6b-T01, T05 live test | create and upload keys |
| 7 | Legal texts (Impressum, Datenschutz) are drafts | store submission, P7-T07 sign-off | review with lawyer / sign off |
| 8 | Apple Associated Domains / AASA for `mitlio.de` must be live and match the profile | universal join links on device | verify domain + hosting |
| 9 | P5 field test on a real trip | go-live confidence; new fixtures | drive, file `field-test` issues |
| 10 | Receipt fixtures (~30 anonymised receipts) | P9r-T02 | collect and anonymise |
| 11 | ADR-28 owner question 13 (support tip) | P7-T09 | decide model (link vs. IAP), App Store 3.1.1 |
| 12 | PU-T06 illustrations and wording of the PBefG hint need owner judgement | PU merge | review goldens |
| 13 | Search Console / Bing verification (DNS TXT) | PW-T11 | add DNS record |
| 14 | Store listings, screenshots, privacy nutrition labels | release | create in App Store Connect / Play |
