# Next steps — task list (status 2026-11-20)

Source of truth for scope stays `docs/IMPLEMENTATION_PLAN.md`. This file is the working queue: what is done, what is next, what waits on a human. Update it in every PR that finishes an item.

## Status snapshot

| Phase | State |
|---|---|
| P0–P4 (foundation, domain, local app, rides, settle) | done |
| PW (SEO web calculator), P6c (fuel prices) | done; open polish: #186, #207, PR #211/#212 |
| P6 (backend, sync, share, join, version gate) | done (T01–T16); sync E2E on local Supabase green |
| P7 | T01–T03, T07 done; T04–T06 present; T08 (Sentry scrubber) open; T09 (support tip, ADR-28) in PR #217 |
| P8 | T01–T03 done (iOS TestFlight signing fixed in #216); T04–T08 open |
| PU (personal profile, cars, guided setup) | **not started** (ADR-25) |
| P6b (push) | **not started** (needs Firebase accounts) |
| P9r (receipt OCR), P9-T01..T07 | not started |

## Queue (agent-doable, in order)

### Q1 — Open PRs to land (no new code)
- [ ] #211 web fuel footer, #212 wear toggle, #217 ADR-28: get CI green, merge.

### Q2 — Open bugs from field test / ux-review (small, test-first)
Each: failing test first, then fix. Some may already be fixed on main; verify with a repro test before coding.
- [ ] #136 balances break in a group with a removed member
- [ ] #139 "Up next" / default driver stuck on first driver
- [ ] #138 member rename: inline field gets no focus
- [ ] #141 settle month sheet shows total ride cost instead of what others owe
- [ ] #143 seed scenarios shift a day outside UTC; fixture category keys unknown
- [ ] #144 duplicate member names accepted silently
- [ ] #145 balances empty state says "nothing to settle" while rides are unsettled
- [ ] #146 trip share text does not say who to pay
- [ ] #147 trip calculator accepts implausible values
- [ ] #137, #140, #142: closed by earlier PRs? Verify on the simulator, close or fix.

### Q3 — Small features
- [ ] #186 web footer credit, #187 app credit in About
- [ ] #207 web from-to route field (fills km)
- [ ] #206 Supabase: stop writing Auth audit logs to the DB (config only, `critical`, owner review)
- [ ] Mutation survivors: #210 semver, #178 car_catalog, #120 ride_period, #119 split_error, #118 expense_error

### Q4 — PU personal profile, cars, guided setup (ADR-25) — biggest product gap
Order: PU-T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11 → T15 → T16 → T12.
PU-T13 (photo), T14 (needs P6-T07 account tie), T17 (needs P6b) stay later.

### Q5 — Release hardening (P8)
- [ ] P8-T06 `check_release_strip.sh` wired into the release workflow (script exists; verify gate)
- [ ] P8-T04 `release.yml` with prod approval + smoke drive (needs prod project, see blockers)
- [ ] P8-T08 `agent-fix-ci.yml`
- [ ] P7-T08 Sentry: scrubber test, `beforeSend`, opt-in only
- [ ] P7-T09 support the developer (after #217, ADR-28: opt-in, never in payment flow, App Store 3.1.1)

### Q6 — Later
P6b push (T02–T05, T09 backend/agent parts doable with stubs; T01 needs Firebase), P9r receipt OCR, P9-T01..T07.

## Verification rule
Every UI-visible item is also checked on the iOS simulator through DebugDrive (`make drive-up`, `tool/drive.sh`), with the flow's tap budget (`docs/ux-budgets.md`) respected. Findings that are not fixed in the same PR become issues.

## Blockers needing a human
See `docs/BLOCKERS.md`.
