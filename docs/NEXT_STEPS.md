# Next steps: task list (status 2026-11-22)

Source of truth for scope stays `docs/IMPLEMENTATION_PLAN.md`. This file is the working queue: what is done, what is next, what waits on a human. Update it in every PR that finishes an item. Human-only items: `docs/BLOCKERS.md`.

## Status snapshot

| Phase | State |
|---|---|
| P0-P4, P3r | done |
| PW, P6c | done; #207 route field waits on owner (ORS origins, Datenschutz) |
| P6 sync | done (T01-T16); prod backend bootstrapped, app prod config set (#271) |
| P7 | T01-T08 done; T09 tip jar waits on ADR-28; T10 feedback form unblocked (ADR-29 merged, #229), needs credential/bucket (BLOCKERS 20-22); store listing draft (#260) |
| P8 | T01-T04, T06-T08 done (#233, #242, #243); T03 store halves wait on secrets |
| PU | T02-T12, T15, T16 done; T13, T14, T17 later; decisions in BLOCKERS 12 |
| P6b | T02-T04 (#246) and app side T06-T09 (#252) done; T05 (#253) and T10 (#268) open; T01 needs Firebase keys |
| P9 | T03 domain recurrence done (#266); rest skipped for now |
| P9r | not started |

## Open PRs
#253 notify, #251 audit purge (both stale bot CHANGES_REQUESTED, need owner dismissal), #268 P6b-T10 (stacked on #253), #226 release 0.4.0.

## Remaining agent-doable
| Item | Note |
|---|---|
| PU-T13, T14, T17 | later |
| P9-T03 app side, T04/T05 reminders + digest | skipped until P6b lands |
| P9-T06 read-only web share link | ADR first; skipped |
| P9r-T03 parser, T04 interface | synthetic fixtures only; T01/T02 need owner |

Everything else waits on a human: `docs/BLOCKERS.md`.

## Verification rule
Every UI-visible item is also checked on the iOS simulator through DebugDrive (`flutter run -d <sim> --flavor dev --vmservice-out-file=.drive/uri`, `tool/drive.sh`), respecting the tap budgets in `docs/ux-budgets.md`. Findings that are not fixed in the same PR become issues.
