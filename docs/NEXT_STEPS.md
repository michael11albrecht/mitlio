# Next steps — task list (status 2026-11-21)

Source of truth for scope stays `docs/IMPLEMENTATION_PLAN.md`. This file is the working queue: what is done, what is next, what waits on a human. Update it in every PR that finishes an item. Human-only items: `docs/BLOCKERS.md`.

## Status snapshot

| Phase | State |
|---|---|
| P0–P4, P3r | done |
| PW, P6c | done; #207 route field waits on owner (ORS origins, Datenschutz) |
| P6 sync | done (T01–T16) |
| P7 | T01–T08 done; T09 tip jar waits on ADR-28 owner decision (#219); T10 feedback form waits on ADR-29 (#229, #230) |
| P8 | T01–T03, T07 done, T04 prod deploy workflow done (#233); T06 (#242, gate verified on a real iOS build), T08 (#243, off until `AGENT_FIX_CI=true`) in owner review |
| PU | T02, T03, T15 done (#235); T04 (#239), T05 (#245), T06 (#247) in review; T07–T09 in progress (stacked) |
| P6b | T02–T04 in review (#246); T05 notify function, app-side T06–T09 in progress; T01 needs Firebase (owner) |
| P9r, P9-T01..T07 | not started |

## Done since 2026-11-20
Bug fixes #136–#147 (closed), credits #186/#187, mutation survivors #118–#120/#178/#210, Sentry scrubber, prod deploy workflow, auto-merge for safe PRs, wear toggle and fuel footer on the web.

## In flight (agents)
- PU-T07 profile flow, PU-T08/T09 car + cost calculator (stacked on #239, #245)
- P6b-T05 `notify` function (stacked on #246), P6b app-side push with fakes
- #206 audit-log purge follow-up (migration)
- UX nits #236, #237; #247 CI fix

## Next up (agent-doable)
1. PU-T10 group integration, PU-T11 entry points and cards, PU-T16 share my QR code, PU-T12 move rare flows onto step flow — after PU-T07/T08 merge
2. P9-T03 recurring expenses (domain-first), P9-T04/T05 reminders and digest (after P6b)
3. P9r receipt OCR: T03 domain parser and T04 interface can start with synthetic fixtures; T01 spike and T02 real receipts need the owner
4. P9-T06 read-only web share link (ADR first)

## Verification rule
Every UI-visible item is also checked on the iOS simulator through DebugDrive (`flutter run -d <sim> --flavor dev --vmservice-out-file=.drive/uri`, `tool/drive.sh`), respecting the tap budgets in `docs/ux-budgets.md`. Findings that are not fixed in the same PR become issues.
