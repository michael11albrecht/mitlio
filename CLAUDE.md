# mitlio — agent contract

mitlio is "the private taxometer": share car-ride costs and group expenses fairly. Flutter app + Supabase backend + SEO web calculator.
Full plan, task IDs and rationale: `docs/IMPLEMENTATION_PLAN.md`. Decisions: `docs/adr/`.

**Product rule #0: simplicity and great UX.** No ads, no dark patterns, no popups, result first, smart defaults, undo instead of confirm dialogs. See plan §2.6.

## Definition of done

`make check` is green. Nothing else counts. Never weaken a gate to get green.

## Commands

| Command | Use |
|---|---|
| `make bootstrap` | after clone / dependency change |
| `make test-domain` | TDD loop for business logic (seconds) |
| `make test` | all unit + widget tests |
| `make check-fast` | format + lint + domain tests (runs in the Stop hook) |
| `make check` | full gate before opening a PR |
| `make fmt` | format everything |
| `make help` | list all targets (some are stubs until their phase lands) |

Flutter SDK: version pinned in root `pubspec.yaml` (`environment.flutter`). Local install at `~/sdk/flutter` is picked up automatically by the Makefile.

## Repository layout

- `packages/domain` (`mitlio_domain`) — pure Dart business logic: money, splits, balances, debt simplification, trip/ride cost, payment payloads. **No Flutter, Drift, Supabase or Riverpod imports.**
- `packages/drive_client` (`mitlio_drive`) — CLI for the DebugDrive protocol.
- `app/` (`mitlio`) — Flutter app. Shipped targets: iOS + Android. `linux/` exists only as a headless test/DebugDrive harness for CI and is never released. App code is feature-first: `lib/features/<feature>/{data,ui}/`, shared code in `lib/core/`, DebugDrive in `lib/debug/`.
- `supabase/` (P6+) — SQL migrations, pgTAP tests, Edge Functions.
- `web/` (PW) — Astro SEO site with calculator island.
- `tool/` — gates, hooks, drive scripts, fixtures.

## Architecture (MVVM + DebugDrive)

View → ViewModel → Repository → Service. Views contain no logic. Every user action is a ViewModel command. DebugDrive handlers (`ext.mitlio.*`, debug builds only) call the same ViewModel/Repository API that tests call. If something can only be done by tapping a widget, the design is wrong.

| Layer | May import | Must NOT import |
|---|---|---|
| domain | dart core libs, `collection`, `meta` | flutter, drift, supabase, riverpod, app |
| services | domain, SDK clients | ViewModels, Views |
| repositories | domain, services, drift | ViewModels, Views, widgets |
| ViewModels | domain, repository interfaces | services, Views, `BuildContext` |
| Views | ViewModels, design system | repositories, services, drift |
| debug | ViewModels, repositories | Views |

## Rules

- **Money is `int` cents.** Never `double` for amounts. Rounding: largest remainder, ties by member position then id (`docs/domain-rules.md`).
- Inject `Clock`, `IdGenerator`, `Random`. No `DateTime.now()`, `Random()` or UUID creation outside `app/lib/core/`.
- Tests first. Bug fix = failing test first. Every domain function: examples + property test + edge cases. Every ViewModel command: success, validation error, repository failure.
- Coverage: ≥ 80 % overall, ≥ 90 % domain/data/ViewModels/sync. Mutation score enforced on domain.
- All UI strings via ARB (l10n). Design tokens only from `core/theme`.

## Prohibitions

- Do not edit merged files in `supabase/migrations/` (append new migrations only).
- Do not edit `.github/workflows/**`, `CODEOWNERS`, `tool/*_gate.dart` thresholds, `analysis_options.yaml`, `lefthook.yml`, `.claude/**`, `CLAUDE.md` unless the issue explicitly asks for it (these paths are `critical` and need owner review).
- Do not skip, delete or loosen tests to make CI pass. No `skip:` without an issue link.
- No `// ignore:` without a justification comment on the same line.
- No new dependencies without a one-line rationale in the PR body. Never add ad, tracking or attribution SDKs.
- Do not update golden files without explaining why in the PR body.
- Never commit secrets; `.env*` files are local only.

## Model usage

- **Implementation (code, tests, CI fixes, PR review): Claude Sonnet** (`claude-sonnet-5-5`). Subagents that write code run on Sonnet.
- **Thinking/planning only: Claude Opus** (`claude-opus-5-5`) — breaking phases into issues, plan/ADR changes, architecture decisions, root-cause analysis when Sonnet is stuck after 2 attempts. Opus does not write production code.

## Workflow for an issue

1. Read the issue and the referenced plan section/task ID.
2. Branch `agent/<issue>-<slug>`.
3. Write failing tests, implement, `make check-fast` in the loop.
4. `make check` before pushing.
5. `gh pr create` using the PR template; link the issue; list the task ID.
6. If the task is ambiguous or blocked: comment on the issue and stop. Do not guess at product decisions.
