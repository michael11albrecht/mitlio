# mitlio — Full-Stack Implementation Plan

> Group expense splitting (trips, shared households, car rides) with payment links, offline-first sync and a hardened, agent-driven delivery pipeline.
>
> **Status:** plan v1 · 2026-11-13 · repo is empty (initial commit only)

---

## 0. How to read this plan

- The plan is split into **phases** (P0 … P9). Each phase contains **tasks** with a stable ID (`P2-T05`).
- Every task is sized to be **one GitHub issue → one PR** that an agent can implement autonomously. Each task lists:
  - **Do** — what to build
  - **Accept** — acceptance criteria (must be verifiable by a command, not by opinion)
  - **Risk** — `safe` (auto-merge allowed) or `critical` (human review required), derived mechanically from touched paths (see §6.4)
- Phases P0–P1 are **human-led** (they build the guardrails the agents rely on). From P2 onward, tasks are written to be fed to the agent pipeline.
- Estimates assume one person with Flutter experience plus agents doing most of the typing.

### Guiding principles

0. **Simplicity and great UX above everything.** No ads, no dark patterns, no nagging, no feature that makes the common path slower. Every feature must justify the UI surface it adds (see §2.6).
1. **Local-first, accounts later.** P0–P5 deliver a fully usable single-device app. Sync is added only after a real-trip test (P5).
2. **Everything an agent needs is a command.** No step requires a GUI, a human eye or tribal knowledge. `make check` is the single source of truth for "done".
3. **Logic lives below the View.** Views are dumb. Everything testable is reachable through the ViewModel/Repository API — the same API used by unit tests, integration tests *and* the DebugDrive agent bridge.
4. **Mechanical gates over LLM judgement.** Coverage, mutation score, architecture rules, risk labels and migration safety are enforced by scripts, not by asking a model.
5. **Integer cents everywhere.** No `double` touches money. Ever.

### Product positioning

**mitlio = the private taxometer.** Primary job: charge friends fairly for car rides — single trips (holiday, concert), recurring rides (daily commute carpool: who drove when, who rode along) — with general group expense splitting as the second pillar.

**Acquisition funnel (SEO-first):**

```
Google: "Fahrtkosten berechnen", "Spritkosten teilen", "Fahrgemeinschaft Kosten aufteilen"
   │
   ▼
mitlio web calculator (free, no ads, no popups, no signup, instant result)
   │  "Jeder zahlt 12,40 €" + share via WhatsApp/link
   │
   ├─ one-off users: done, come back via bookmark/shared link
   └─ repeat users (commuters, regular trips): prominent "Fahrten speichern & monatlich abrechnen → App"
          │  deep link carries the calculated trip into the app (prefilled)
          ▼
       mitlio app: ride log, vehicles, recurring rides, monthly settlement, PayPal/SEPA
```

**Differentiators vs. existing calculators** (top-ranked German calculators are ad-heavy, popup-laden, and don't make the result obvious):
1. **Live fuel prices that are clickable** — current average/nearby E5/E10/Diesel as chips; one tap puts the price into the calculation.
2. **Result first** — the big number is *what each person pays*, then the breakdown. No "calculate" button; results update as you type.
3. **No ads, no popups, no cookie banner** (no cookies, privacy-friendly analytics only).
4. **Share result** as text/link (WhatsApp) with prefilled URL parameters, and **"open in app"** for people who do this regularly.
5. Fast and mobile-first (Lighthouse ≥ 95, LCP < 1.5 s on 4G).

---

## 1. Decisions (ADR summary)

| # | Decision | Choice | Rationale | Revisit when |
|---|---|---|---|---|
| ADR-01 | App framework | Flutter (stable), Dart 3.x | Single codebase iOS/Android, good test tooling, desktop target for headless agent runs | — |
| ADR-02 | Architecture | MVVM: View → ViewModel → Repository → Service (Flutter's official "app architecture" guide shape) + DebugDrive bridge | Matches the diagram; every user action is a ViewModel command callable from tests and agents | — |
| ADR-03 | State management / DI | Riverpod (code-gen `riverpod_generator`) | Overridable providers = trivial fakes in tests and DebugDrive seeding | — |
| ADR-04 | Local DB | Drift (SQLite) | Typed, migration-tested (`drift_dev schema` tests), runs in-memory in unit tests | — |
| ADR-05 | Domain | **Separate pure-Dart package** `packages/domain` (no Flutter import possible) | Fast tests, 90 %+ coverage and mutation testing are cheap there | — |
| ADR-06 | Backend | **Supabase** (Postgres + RLS + RPC + Edge Functions) | Relational data, SQL migrations are reviewable diffs for agents, full local stack via `supabase start` (Docker) for integration tests, pgTAP for RLS tests | If push/realtime cost or complexity explodes → Firebase |
| ADR-07 | Sync | Custom outbox + pull-cursor, **aggregate-level Last-Write-Wins** with Hybrid Logical Clock | Good enough for friend groups; deterministic and testable | If users complain about lost edits → per-field merge |
| ADR-08 | Auth | Supabase anonymous sign-in, optional email/Apple/Google linking later | Zero friction invite flow | — |
| ADR-09 | Payments | PayPal.Me deep link + EPC-QR (SEPA). No PSP SDK | No client secret, no merchant account, no PCI scope | — |
| ADR-10 | Mutation testing | `mutation_test` (Dart) for domain + selected app logic; StrykerJS for Edge Function TS | Only mutation testing proves the tests actually assert | — |
| ADR-11 | Agent runtime | `anthropics/claude-code-action@v1` on GitHub-hosted Ubuntu runners, label-triggered | Event-driven, no polling VM, logs + CI results in one place | If cost/turn-limits hurt → self-hosted runner |
| ADR-12 | Monorepo tooling | Dart pub workspaces + `Makefile` as the agent entrypoint (+ `melos` only if needed) | One command surface for humans, CI and agents | — |
| ADR-13 | Push notifications | FCM HTTP v1 (FCM also delivers to iOS via APNs key) sent from a Supabase Edge Function; DB trigger → `notification_outbox` → `pg_cron` every minute → coalesced sends | One push path for both platforms, debouncing is natural, fully testable locally with an FCM stub. Firebase is used **only** for messaging | — |
| ADR-14 | Crash reporting | Sentry, EU region (`de.sentry.io`), PII scrubbing | Keeps all user data in EU (consistent with Supabase EU), good Dart/Flutter symbolication | — |
| ADR-15 | Agent models | Open-weights implementer for `safe` tasks, Claude for `critical` tasks and as reviewer (different model family than the implementer) — chosen by measured eval, see §6.7 | Strong mechanical gates make a cheaper implementer viable; decorrelated reviewer catches more | Re-run eval quarterly |
| ADR-16 | App identity | Name **mitlio**. Single source `app/app_identity.yaml`: display name `mitlio` (dev: `mitlio dev`), URL scheme `mitlio://`, bundle/application id `app.mitlio` / `app.mitlio.dev` (reverse-DNS is only a convention, no domain ownership needed; fixed forever after first store upload), DebugDrive namespace `ext.mitlio.*` | Consumed by flavors + fastlane; any change is one PR | — |
| ADR-17 | Domain | **Own domain (revised 2026-11-13 for SEO)**, e.g. `mitlio.de` (DE-first audience; `mitlio.app` optional redirect), served by Firebase Hosting (free) — hosts the SEO web calculator, `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`, invite fallback `/join/<token>`, privacy policy/imprint. Not Firebase Dynamic Links (shut down). Until the domain exists, `mitlio.web.app` works as a stand-in | A `*.web.app` subdomain ranks and converts worse, can't build brand backlinks, and moving later loses SEO equity. Cost ~€10–20/year | — |
| ADR-19 | Web calculator stack | **Astro** static site (prerendered HTML per landing page, zero JS by default) + one small calculator island. Calculation logic = **the Dart domain compiled to JS** (`packages/domain_web`, `dart compile js`, exported via `dart:js_interop`) so web and app compute identical cents; parity additionally guarded by shared fixture tests | Flutter Web renders to canvas → poor SEO and heavy first load; a TS re-implementation would drift from the app | If dart2js bundle > 150 kB gz → TS port with fixture parity tests |
| ADR-20 | Fuel prices | Germany: **Tankerkönig API** (MTS-K data, CC BY 4.0, free API key) proxied + cached by a Supabase Edge Function; Austria: E-Control Spritpreisrechner API; elsewhere: EU Weekly Oil Bulletin national averages; EV: manual kWh price with a sensible default. Client never sees API keys; attribution shown | Live clickable prices are the core differentiator; caching keeps us inside provider rate limits and terms | Verify terms + limits in P1-T01 spike before building |
| ADR-18 | Cost policy | Lean budget with hard caps, see §6.8 | Owner wants minimum sensible spend | Monthly review of `docs/agent-metrics.md` |

Each ADR becomes a file in `docs/adr/NNNN-title.md` in P0.

---

## 2. Target architecture

### 2.1 Layering (from the diagram)

```
┌────────────────────── Device / App (debug build) ──────────────────────┐
│  UI layer                                                              │
│   View (widgets, no logic) ──events──▶ ViewModel (UI state + Commands) │
│                            ◀──state──         ▲                        │
│                                               │ same API               │
│                                     DebugDrive ext.mitlio.* (kDebugMode)   │
│                                               │                        │
│  Data layer                                   ▼                        │
│   Repository (source of truth, Drift) ──▶ Service (Supabase, FX, file) │
│                                                    └──▶ backend        │
│  Domain (pure Dart package): money, split, balance, simplify, fuel     │
└────────────────────────────────────────────────────────────────────────┘
        ▲ VM-Service websocket (JSON-RPC)
        │
  flutter run + DDS  ◀── tool/drive.sh / dart mcp-server ◀── Agent (Claude Code)
```

**The rule:** the DebugDrive handler replaces the View. It calls the *same* ViewModel / Repository API the unit tests call. If something can only be done by tapping a widget, the architecture is wrong.

### 2.2 Dependency rules (enforced by `test/architecture_test.dart`, see §5.3)

| Layer | May import | Must NOT import |
|---|---|---|
| `packages/domain` | `dart:core`, `collection`, `meta` | `flutter`, `drift`, `supabase`, `riverpod`, anything in `app/` |
| `app/lib/**/data/services` | domain, SDK clients | ViewModels, Views |
| `app/lib/**/data/repositories` | domain, services, Drift | ViewModels, Views, `package:flutter/widgets` |
| `app/lib/**/ui/*_view_model.dart` | domain, repositories (via interfaces) | services directly, Views, `BuildContext` |
| `app/lib/**/ui/*_view.dart` / widgets | ViewModels, design system | repositories, services, Drift |
| `app/lib/debug/**` | ViewModels, repositories | Views; must be tree-shaken in release (`kDebugMode` guard) |

### 2.3 Repository layout

```
free-split/                       # repo name may stay; product name is mitlio
├── CLAUDE.md                     # agent contract: architecture, commands, prohibitions
├── AGENTS.md                     # symlink/copy of CLAUDE.md for other agents
├── Makefile                      # THE command surface (see §5.1)
├── pubspec.yaml                  # pub workspace root
├── analysis_options.yaml         # shared strict lints
├── lefthook.yml                  # git hooks (format, analyze, fast tests)
├── .claude/
│   ├── settings.json             # allowed commands, hooks for the local agent
│   └── commands/                 # /implement-task, /drive, /mutation slash commands
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/agent_task.yml
│   ├── pull_request_template.md
│   └── workflows/                # ci, agent-implement, agent-review, risk-label, automerge,
│                                 # mutation-nightly, android-e2e, ios-testflight, release
├── docs/
│   ├── IMPLEMENTATION_PLAN.md    # this file
│   ├── adr/
│   ├── domain-rules.md           # rounding, split semantics, examples (golden data)
│   └── drive-protocol.md         # ext.mitlio.* contract
├── packages/
│   ├── domain/                   # pure Dart: Money, Split, Balance, Simplify, Fuel, EPC, PayPal
│   ├── domain_web/               # dart2js/js_interop facade over domain for the web calculator
│   └── drive_client/             # Dart CLI: VM-service client used by tool/drive.sh
├── app/
│   ├── lib/
│   │   ├── main.dart / main_dev.dart / main_prod.dart
│   │   ├── core/                 # di, router, theme, clock, id generator, logging
│   │   ├── features/
│   │   │   ├── groups/{data,ui}/
│   │   │   ├── expenses/{data,ui}/
│   │   │   ├── trips/{data,ui}/          # fuel-cost expense
│   │   │   ├── balances/{data,ui}/
│   │   │   ├── settle/{data,ui}/
│   │   │   ├── members/{data,ui}/
│   │   │   └── sync/{data}/              # P6
│   │   ├── db/                   # Drift database, tables, migrations
│   │   └── debug/                # DebugDrive (ext.mitlio.*), seed scenarios
│   ├── test/                     # unit + widget + golden
│   ├── integration_test/         # on-device / desktop flows
│   └── drift_schemas/            # exported schema versions for migration tests
├── web/                        # Astro SEO site + calculator island (Playwright, Lighthouse CI)
├── supabase/
│   ├── config.toml
│   ├── migrations/               # SQL, append-only
│   ├── tests/                    # pgTAP: RLS + RPC tests
│   ├── seed.sql
│   └── functions/                # Edge Functions (TS/Deno), logic in _shared/ tested with vitest
└── tool/
    ├── drive.sh                  # agent → running app
    ├── coverage_gate.dart        # per-path coverage thresholds
    ├── mutation_gate.dart        # mutation score thresholds
    ├── risk_label.sh             # path → safe|critical
    └── fixtures/                 # deterministic seed scenarios (JSON)
```

### 2.4 Data model

All IDs are **UUIDv7** generated on the client (sortable, sync-safe). All money is `int` cents. All rows carry sync metadata.

Common columns on every synced table: `id uuid pk`, `group_id uuid`, `created_at`, `updated_at` (HLC string), `deleted_at` (nullable, soft delete), `server_seq bigint` (server only; pull cursor).

| Table | Columns (besides common) | Notes |
|---|---|---|
| `groups` | `name`, `currency` (ISO 4217), `created_by` | |
| `members` | `name`, `position int`, `paypal_me`, `user_id` (nullable, P6), `iban_hint` | **Full IBAN stays local-only** (`local_member_bank` table, never synced) — see §8 |
| `expenses` | `title`, `amount_cents`, `currency`, `fx_rate_ppm` (int, parts per million, frozen), `group_amount_cents`, `date`, `category`, `type` (`regular`/`trip`/`settlement`), `split_mode`, `trip_meta jsonb` | Aggregate root |
| `expense_payers` | `expense_id`, `member_id`, `paid_cents` | Child of aggregate |
| `expense_shares` | `expense_id`, `member_id`, `share_cents`, `weight` (for share/percent modes, for re-editing) | Child of aggregate |
| `settlements` | `from_member`, `to_member`, `amount_cents`, `currency`, `date`, `method` (`paypal`/`sepa`/`cash`/`other`) | |
| `vehicles` | `owner_member_id`, `name`, `fuel_type` (`e5`/`e10`/`diesel`/`lpg`/`electric`), `consumption_milli` (l or kWh per 100 km × 1000), `wear_rate_cents_per_km`, `default_pricing` (`consumption`/`km_rate`) | Per group; reused by rides |
| `ride_templates` | `name` ("Arbeit"), `vehicle_id`, `distance_m`, `default_driver`, `default_passengers[]`, `return_trip bool` | Commute presets |
| `rides` | `template_id?`, `vehicle_id`, `driver_member_id`, `passenger_ids[]`, `date`, `distance_m`, `fuel_price_milli` (per l/kWh, frozen), `price_source` (`manual`/`tankerkoenig`/…), `extras_cents`, `expense_id?` | One logged ride; aggregated into an `expense` per settlement period (or immediately for one-offs) |
| `fuel_price_cache` | `region_key`, `fuel_type`, `price_milli`, `source`, `fetched_at` | Server only, public read (P6c) |
| `expense_revisions` | `expense_id`, `revision int`, `snapshot jsonb`, `author_member_id`, `at` | Append-only history (P7) |
| `group_invites` | `token_hash`, `expires_at`, `created_by` | Server only (P6) |
| `local_outbox` | `entity`, `entity_id`, `op`, `payload`, `attempts` | Client only (P6) |
| `device_tokens` | `user_id`, `token`, `platform`, `locale`, `app_version`, `last_seen_at` | Server only, RLS: own rows only (P6b) |
| `notification_prefs` | `user_id`, `group_id`, `level` (`all`/`mine`/`none`), `quiet_hours` | Server; default `all` (P6b) |
| `notification_outbox` | `group_id`, `actor_user_id`, `event` (`expense_added`/`expense_changed`/`expense_deleted`/`settlement_added`/`member_joined`), `entity_id`, `payload jsonb`, `created_at`, `processed_at` | Server only, written by trigger, no client access (P6b) |

Invariants (enforced in domain + DB constraints + pgTAP):
- `sum(expense_payers.paid_cents) == expenses.amount_cents`
- `sum(expense_shares.share_cents) == expenses.amount_cents`
- `amount_cents > 0`, members belong to the same group
- Sum of all member balances in a group `== 0`

### 2.5 Core domain semantics

- **Split modes:** `equal`, `shares` (weights), `percent` (basis points summing to 10 000), `exact` (fixed cents, must sum to total), plus per-person exclusion (weight 0).
- **Rounding:** *largest remainder method*, ties broken by `member.position` then `member.id`. Deterministic, documented in `docs/domain-rules.md` with worked examples that double as golden test data.
- **Balance:** `net(m) = Σ paid(m) − Σ share(m) + Σ settlements_sent(m) − Σ settlements_received(m)` in group currency.
- **Simplify debts:** greedy, largest debtor pays largest creditor; result has ≤ n−1 transfers and preserves every net balance (property test).
- **Trip cost:** `total = round(km × l_per_100km / 100 × price_per_litre_cents) + tolls + ferry + km × wear_rate_cents`; payer = driver; shares across selected passengers (+ driver if `driverCounts`). Alternative mode: flat km rate.
- **Multi-currency:** `group_amount_cents = round_half_even(amount_cents × fx_rate_ppm / 1e6)`; rate frozen on the expense; split is computed on `group_amount_cents`.

### 2.6 UX principles & enforceable UX guardrails

**Principles**
1. **One obvious next action per screen.** The primary action is reachable with the thumb; secondary actions live in overflow/sheets.
2. **Result first.** Every calculation shows the answer ("Du bekommst 23,40 €", "Jede Person zahlt 12,40 €") before any breakdown.
3. **Smart defaults over settings.** Last-used vehicle, driver, passengers, currency and split are pre-selected. Settings screens stay short.
4. **No modal interruptions.** No rating prompts in the first weeks and never mid-task, no upsell, no permission prompt before the user needs the feature, no popups on the website.
5. **Forgiving.** Every destructive action has undo (snackbar) instead of "Are you sure?" dialogs; soft delete makes this cheap.
6. **Calm, honest UI.** No fake urgency, no badges for engagement's sake, notifications only for things other people did that affect your money.
7. **Fast.** Cold start < 1.5 s on a mid-range Android, every interaction < 100 ms, no jank (no frames > 16 ms in scroll/animations).
8. **Accessible by default.** Dynamic type up to 200 %, screen reader labels, contrast AA, works one-handed.

**Mechanical guardrails** (so agents can't erode UX unnoticed)

| Guardrail | Enforced by |
|---|---|
| **Tap budgets** per core flow: log commute ride ≤ 3 taps, add equal-split expense ≤ 5 taps + typing, mark transfer as paid ≤ 2 taps, web calculator result without pressing any button | integration tests count taps via a `TapCounter` test helper; budget table in `docs/ux-budgets.md` |
| **No ads / trackers / dark-pattern SDKs** | dependency denylist check in CI (ad SDKs, attribution/tracking SDKs, `in_app_review` prompts outside the allowed trigger) — `tool/deps_policy.dart` |
| **No blocking dialogs for destructive actions** | architecture test: `showDialog` only allowed in an allowlist of files; destructive VM commands must expose `undo` |
| **Performance budgets** | `integration_test` with `traceAction` / `watchPerformance` on Linux + Android: frame build/raster p90 < 8 ms, no frame > 16 ms in core lists; cold-start measured in `android-e2e` |
| **Visual consistency** | design system only (arch test: no raw `Color(0x…)`, `TextStyle(` or magic paddings outside `core/theme`); goldens for every screen in light/dark and text scale 1.0/2.0 |
| **Copy quality** | all strings via ARB; `docs/copy-guide.md` (du-form, short, numbers formatted per locale); reviewer-agent checklist includes copy |
| **Accessibility** | `meetsGuideline(textContrastGuideline / androidTapTargetGuideline / iOSTapTargetGuideline / labeledTapTargetGuideline)` in widget tests of every screen; axe on web |
| **Empty/error/loading states** | every screen VM exposes them; golden per state |
| **Human UX gate** | PRs that add a new screen or change navigation get label `ux-review` (path-based: `app/lib/**/ui/*_view.dart` new files, router changes) → `critical`, owner looks at the golden diff images attached by CI |

**Design process for agents:** each UI task issue contains a small wireframe (ASCII or image) and the tap budget; the agent attaches before/after goldens to the PR; the reviewer agent checks against §2.6 principles.

---

## 3. Quality targets (hard gates)

| Gate | Scope | Threshold | Enforced by | When |
|---|---|---|---|---|
| Format | all Dart, SQL, TS | 0 diffs | `dart format --set-exit-if-changed`, `sqlfluff`, `prettier --check` | pre-commit, CI |
| Static analysis | all Dart | 0 issues (infos count) | `very_good_analysis` + strict-casts/inference/raw-types | pre-commit, CI |
| Architecture | `app/`, `packages/` | 0 violations | `architecture_test.dart` | CI |
| Line coverage | `packages/domain` | **≥ 95 %** (aim), **≥ 90 %** hard | `tool/coverage_gate.dart` | CI |
| Line coverage | `app/lib/**/data/**`, `app/lib/**/ui/*_view_model.dart`, `app/lib/features/sync/**` | **≥ 90 %** | `coverage_gate.dart` | CI |
| Line coverage | whole repo (excl. generated) | **≥ 80 %** | `coverage_gate.dart` | CI |
| Coverage ratchet | any path | must not drop > 0.5 pp vs `main` | `coverage_gate.dart --baseline` | CI |
| Mutation score | `packages/domain` | **≥ 85 %** killed (start 75 %, ratchet up) | `tool/mutation_gate.dart` | PR (changed files), nightly (full) |
| Mutation score | ViewModels + sync merge logic | **≥ 70 %** | same | nightly |
| Mutation score | Edge Function `_shared` TS | ≥ 80 % | StrykerJS `thresholds.break` | PR when touched |
| Web parity | `web/` calculator vs Dart domain | 100 % of shared trip fixtures identical | `web` vitest over `tool/fixtures/trip_*.json` | PR touching `web/` or `packages/domain*` |
| Web performance/SEO | all landing pages | Lighthouse Performance/SEO/Accessibility/Best-Practices ≥ 95, JS ≤ 150 kB gz | Lighthouse CI budgets | PR touching `web/` |
| Web E2E + a11y | calculator flows | 0 failures, 0 axe violations | Playwright + `@axe-core/playwright` | PR touching `web/` |
| SEO hygiene | built site | valid JSON-LD, sitemap, canonical, hreflang, no broken links | `tool/seo_check` (html parse) + `lychee` | PR touching `web/` |
| DB tests | RLS + RPC | 100 % of tables have RLS deny + allow tests | `supabase test db` + `tool/rls_coverage.sql` | CI |
| Migration safety | `supabase/migrations` | no unsafe ops (e.g. `DROP COLUMN` without expand/contract) | `squawk` | CI |
| Drift migrations | local DB | every schema version upgrade tested | `drift_dev schema steps` + generated migration tests | CI |
| Goldens | design-system components + key screens | 0 diffs | `alchemist` (CI goldens, fixed fonts) | CI (Linux only) |
| Secrets | repo | 0 findings | `gitleaks` | pre-commit, CI |
| Dependencies | pubspec, package.json | no known vulns, licence allowlist | `osv-scanner`, dependency-review action | CI |
| Release safety | release builds | no `ext.mitlio` symbol in release binary | `tool/check_release_strip.sh` | release |

Generated files (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`, `lib/l10n/**`) are excluded from coverage and mutation.

---

## 4. Testing strategy (pyramid)

| Level | Tooling | Runs on | What it proves | Speed budget |
|---|---|---|---|---|
| Domain unit + property | `test`, `glados` (property-based) | any | math correctness, invariants under random input | < 10 s |
| Repository / service | `test`, Drift `NativeDatabase.memory()`, fakes | any | persistence, mapping, queries | < 30 s |
| ViewModel | `test`, Riverpod `ProviderContainer` overrides, `fake_async` | any | commands, state transitions, error states | < 30 s |
| Widget | `flutter_test` | any | View renders VM state, forwards events | < 60 s |
| Golden | `alchemist` | Linux CI | visual regressions | < 60 s |
| Integration (desktop) | `integration_test` on `-d linux` under `xvfb` | Ubuntu | full app wiring, real Drift file DB, user journeys | < 5 min |
| Integration (Android) | `integration_test` on emulator (KVM runner) | Ubuntu large | platform plugins (url_launcher, QR, share) | PR gate, < 15 min |
| Integration (iOS) | `integration_test` on simulator | macOS | iOS-specific behaviour | main + UI-labelled PRs |
| Backend | pgTAP via `supabase test db`; vitest for TS | Ubuntu + Docker | RLS, RPC, triggers, edge logic | < 3 min |
| Sync E2E | two app instances (headless Dart harness) ↔ local Supabase | Ubuntu + Docker | conflict resolution, offline/online, invites | < 5 min |
| Agent drive smoke | `tool/drive.sh` scripted scenario against `flutter run -d linux` | Ubuntu + xvfb | DebugDrive bridge works end-to-end | < 3 min |
| Mutation | `mutation_test`, StrykerJS | Ubuntu | tests actually assert | nightly / changed files |

### Test conventions (written into CLAUDE.md)

- Every bug fix starts with a failing test (`test: reproduce #123`).
- Every domain function has: example tests from `docs/domain-rules.md`, at least one property test, edge cases (0 participants excluded, 1 cent, max int amounts, all excluded → error).
- Every ViewModel command has tests for success, validation error, and repository failure.
- Every repository has a contract test suite run against both the Drift implementation and the in-memory fake (keeps fakes honest).
- Every Supabase table has pgTAP tests: member can read/write own group, non-member gets 0 rows / permission denied, soft-deleted rows behave.
- Determinism: inject `Clock`, `IdGenerator`, `Random` everywhere. No `DateTime.now()` outside `core/clock.dart` (lint via architecture test).

---

## 5. Agent-operability layer

### 5.1 `Makefile` — the single command surface

| Target | Does | Used by |
|---|---|---|
| `make bootstrap` | install toolchain checks, `pub get`, build_runner, lefthook install | humans, CI, agents |
| `make gen` | `build_runner build --delete-conflicting-outputs` | agents after model changes |
| `make fmt` / `make lint` | format / analyze all packages | hooks |
| `make test` | all unit + widget tests, all packages | agents (fast loop) |
| `make test-domain` | domain only (seconds) | agents (TDD loop) |
| `make cov` | tests with coverage + `coverage_gate` | CI, agents before PR |
| `make mutate CHANGED=1` | mutation tests on changed files vs `origin/main` | agents before PR, CI |
| `make goldens` / `make goldens-update` | golden check / update (update forbidden in CI) | agents |
| `make it` | desktop integration tests under xvfb | CI, agents |
| `make db-up` / `make db-test` / `make db-reset` | local Supabase start, pgTAP, reset + seed | agents (P6+) |
| `make drive-up SCENARIO=trip_4p` | `flutter run -d linux` with seed, writes VM-service URI to `.drive/uri` | agents |
| `make drive CMD='...'` | wrapper around `tool/drive.sh` | agents |
| `make check` | fmt + lint + arch + cov gates + goldens + db-test (if docker) | **definition of done** |
| `make check-fast` | fmt + lint + `test-domain` + changed-package tests | Claude Code Stop hook |

### 5.2 DebugDrive (`ext.mitlio.*`) protocol

Registered in `app/lib/debug/debug_drive.dart` via `dart:developer` `registerExtension`, only inside `if (kDebugMode)` so it is tree-shaken from release builds (verified by `check_release_strip.sh`).

| Extension | Params | Returns | Calls |
|---|---|---|---|
| `ext.mitlio.ping` | — | `{version, buildSha}` | — |
| `ext.mitlio.reset` | — | ok | `AppDatabase.wipe()` |
| `ext.mitlio.seed` | `scenario` | ids of created entities | `tool/fixtures/*.json` via repositories |
| `ext.mitlio.state` | `screen?` | JSON of current ViewModel state(s) | `ViewModel.debugSnapshot()` |
| `ext.mitlio.navigate` | `route` | current route | router |
| `ext.mitlio.groups.create` | `name, currency, members[]` | group | `GroupListViewModel.createGroup` |
| `ext.mitlio.expenses.add` | expense DTO | expense id or validation errors | `ExpenseFormViewModel` commands |
| `ext.mitlio.trips.add` | trip DTO | expense id | `TripFormViewModel` |
| `ext.mitlio.balances.get` | `groupId` | balances + simplified transfers | `BalancesViewModel` |
| `ext.mitlio.settle.markPaid` | `transferId` | settlement id | `SettleViewModel.markPaid` |
| `ext.mitlio.payment.links` | `transferId` | `{paypalUrl, epcPayload}` | `PaymentLinkService` |
| `ext.mitlio.sync.now` / `ext.mitlio.sync.status` | — | sync stats | `SyncService` (P6) |
| `ext.mitlio.errors` | — | captured FlutterError / zone errors since last call | error sink |

Rules: handlers are ≤ 15 lines, parse/validate params, call one VM/repository method, return JSON. Errors are returned as `{error: code, message}` — never thrown into the isolate. The contract is documented in `docs/drive-protocol.md` and covered by `test/debug/debug_drive_test.dart` (handlers invoked directly, no VM service needed).

**Agent access paths:**
1. `tool/drive.sh <ext> [json]` → `packages/drive_client` (Dart, `package:vm_service`) reads the URI written by `flutter run --vmservice-out-file=.drive/uri` and calls the extension on the main isolate. Output is JSON on stdout — trivially parseable by agents.
2. `dart mcp-server` (Dart/Flutter MCP server) registered in `.mcp.json` for hot reload, runtime errors, widget tree inspection and screenshots.
3. Headless default: `-d linux` under `xvfb-run` (works in CI and in cloud agents without emulators). Android/iOS only when platform plugins matter.

### 5.3 Architecture test

`app/test/architecture_test.dart` parses imports (`package:analyzer` or simple regex over `lib/**`) and asserts the table in §2.2, plus:
- no `DateTime.now()` / `Random()` / `Uuid()` outside `core/`
- no `double` field named `*amount*|*cents*|*price*` in domain models (except FX input parsing)
- no `print(` (use logger)
- every `*_view_model.dart` has a sibling test file
- every `ext.mitlio.*` handler is listed in `docs/drive-protocol.md`

### 5.4 Agent contract files

- **`CLAUDE.md`**: purpose, architecture diagram, layer rules, command table, test conventions, "definition of done = `make check` green", prohibitions:
  - never edit `supabase/migrations/*` already merged (append only)
  - never edit `.github/workflows/**`, `CODEOWNERS`, `tool/*_gate.dart` thresholds, `analysis_options.yaml` (these are `critical` and will be blocked anyway)
  - never update goldens without stating why in the PR body
  - never add dependencies without an ADR note in the PR
  - never use `// ignore:` without a justification comment
  - never disable/skip tests to make CI pass
- **`.claude/settings.json`**: allowlist of `make *`, `flutter *`, `dart *`, `git *`, `gh pr *`, `supabase *`; deny `rm -rf`, `git push --force`, `curl` to non-allowlisted hosts. Hooks: `PostToolUse(Edit|Write)` → `dart format` on the file; `Stop` → `make check-fast` (block stop on failure).
- **`.claude/commands/`**: `/implement-task <issue>` (read issue → plan → TDD → `make check` → PR), `/drive <scenario>`, `/mutation-fix <file>` (kill surviving mutants).

---

## 6. CI/CD & agent pipeline

### 6.1 Workflows

| Workflow | Trigger | Runner | Jobs |
|---|---|---|---|
| `ci.yml` | PR, push main | ubuntu | fmt, lint, arch, unit+widget+goldens, coverage gate, changed-files mutation, gitleaks, osv |
| `web.yml` | PR touching `web/**` or `packages/domain*` | ubuntu | build domain_web, Astro build, vitest parity, Playwright + axe, Lighthouse CI, SEO check; deploy preview channel (Firebase Hosting) |
| `backend.yml` | PR touching `supabase/**` | ubuntu + docker | `supabase start`, `db reset`, `supabase test db`, `squawk`, types-diff check, vitest + Stryker for functions |
| `desktop-it.yml` | PR | ubuntu | `make it` under xvfb + drive smoke |
| `android-e2e.yml` | PR (required on `critical` or `ui` label), main | ubuntu (KVM) | emulator via `reactivecircus/android-emulator-runner`, `integration_test` |
| `ios-sim.yml` | label `ui-ios` or main | macOS | simulator integration tests |
| `mutation-nightly.yml` | cron 02:00 | ubuntu | full mutation run, report artifact, opens issue for surviving mutants (label `agent-ready`) |
| `agent-implement.yml` | issue labeled `agent-implement` | ubuntu | Claude implements, `make check`, opens PR |
| `agent-fix-ci.yml` | `workflow_run` failed on agent PR | ubuntu | Claude reads CI logs (`actions: read`), pushes fix, max 2 attempts |
| `agent-review.yml` | PR opened/synchronize | ubuntu | separate reviewer agent, inline comments, verdict as check |
| `risk-label.yml` | PR | ubuntu | `tool/risk_label.sh` → `safe` / `critical` labels |
| `automerge.yml` | PR labeled `safe` + all checks green + reviewer verdict `approve` | ubuntu | `gh pr merge --auto --squash` |
| `deploy-dev.yml` | push main (backend), nightly cron if main changed + `workflow_dispatch` (app) | ubuntu (backend, Android), macOS (iOS) | backend → staging Supabase, app → TestFlight + Play internal |
| `release.yml` | tag `v*.*.*` | macOS + ubuntu | env `production` (required reviewer) → backend migrate prod → smoke test → store upload (phased release) |

### 6.2 Agent implement workflow (sketch)

```yaml
name: agent-implement
on:
  issues:
    types: [labeled]
permissions:
  contents: write
  pull-requests: write
  issues: write
  actions: read
jobs:
  implement:
    if: github.event.label.name == 'agent-implement'
    runs-on: ubuntu-latest
    timeout-minutes: 60
    concurrency: agent-issue-${{ github.event.issue.number }}
    steps:
      - uses: actions/create-github-app-token@v1   # App token so pushes trigger CI
        id: app
        with:
          app-id: ${{ vars.AGENT_APP_ID }}
          private-key: ${{ secrets.AGENT_APP_KEY }}
      - uses: actions/checkout@v4
        with: { token: ${{ steps.app.outputs.token }}, fetch-depth: 0 }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: make bootstrap
      - uses: anthropics/claude-code-action@v1
        with:
          # Claude path: subscription token (no marginal cost, §6.8). Open-weights path: provider key + ANTHROPIC_BASE_URL.
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          github_token: ${{ steps.app.outputs.token }}
          # Model is selected per risk class, see §6.7. For open-weights routing:
          # ANTHROPIC_BASE_URL + provider key via env (verify in P1-T01).
          claude_args: "--max-turns 60 --model ${{ vars.IMPLEMENTER_MODEL }}"
          prompt: |
            Implement issue #${{ github.event.issue.number }} following CLAUDE.md.
            1. Create branch agent/${{ github.event.issue.number }}-<slug>.
            2. Write failing tests first, then implement.
            3. Run `make check` until green. Run `make mutate CHANGED=1`.
            4. Open a PR with `gh pr create` using the PR template; link the issue.
            If blocked or the task is ambiguous, comment on the issue and stop.
```

Notes:
- **GitHub App token, not `GITHUB_TOKEN`** — otherwise pushes don't trigger CI.
- PR creation must be explicitly requested (`gh pr create`).
- Only issues with the label (applied by the owner) run → no prompt injection via random issues. Restrict label permission to maintainers.
- Verify exact action inputs against the current `claude-code-action` docs during P1 (spike task P1-T01).

### 6.3 Reviewer agent

Separate workflow, separate prompt, ideally a different model (e.g. Opus) — the author never approves itself. Checklist in prompt: layer rules, money as int, rounding determinism, test quality (assertions, not just execution), RLS implications, unnecessary scope. Output: inline comments + a final check run `agent-review` with `approve` / `request-changes`. Auto-merge requires `approve`.

### 6.4 Risk labeling (mechanical)

`tool/risk_label.sh` labels a PR **critical** if any of:
- `supabase/migrations/**`, `supabase/functions/**`, `supabase/config.toml`
- `app/lib/features/sync/**`, `app/lib/core/auth/**`
- `.github/**`, `CODEOWNERS`, `Makefile`, `tool/*_gate.dart`, `analysis_options.yaml`, `lefthook.yml`, `.claude/**`, `CLAUDE.md`
- `pubspec.yaml` / `pubspec.lock` dependency changes, `package.json`
- `ios/**`, `android/**` (signing, permissions, Info.plist, manifest)
- `app/lib/debug/**` (release-strip risk)
- diff > 400 changed lines (excluding generated + tests + goldens)
- any golden file changed without matching widget change

Otherwise **safe**. `CODEOWNERS` requires owner review for every critical path; branch protection requires all checks + CODEOWNERS.

### 6.5 Branch protection on `main`

Required checks: `ci`, `desktop-it`, `agent-review`, `risk-label`, (`backend` when path matched), (`android-e2e` when labelled). Linear history, squash only, no force-push, signed commits from the App.

### 6.6 Environments & deployment

| Env | Backend | App distribution | Promotion |
|---|---|---|---|
| local | `supabase start` (Docker) | `flutter run` / desktop | — |
| dev/staging | Supabase project `mitlio-staging` (free plan) | TestFlight + Play internal track | backend on merge to main; app builds nightly if main changed, or manual dispatch (saves macOS minutes, §6.8) |
| prod | Supabase project `mitlio-prod` | App Store phased release + Play staged rollout | tag `v*` + manual approval in `production` env |

Rules: backend deploys before app; migrations are **expand/contract** (backward compatible for N−2 app versions); post-deploy smoke test runs the drive scenario against staging; app has a `min_supported_version` remote check from P6.

### 6.7 Model selection (implementer vs reviewer)

**Recommendation:**

| Role | Model | Why |
|---|---|---|
| Implementer, `safe` tasks (domain, UI slices, tests, mutation-killing) | Strongest open-weights coding model available via an **Anthropic-compatible endpoint**: candidates GLM (Z.ai), Kimi K2.x (Moonshot), DeepSeek V3.x, Qwen3-Coder, MiniMax M2.x — pick the latest version at decision time | Bulk of the token volume; gates (tests, coverage, mutation, arch) catch most mistakes mechanically |
| Implementer, `critical` tasks (sync, RLS, migrations, push, auth) | Claude Sonnet (`claude-sonnet-5-5`) | Lower defect rate where gates are weaker and review is expensive |
| Reviewer (all PRs) | Claude Sonnet; Claude Opus (`claude-opus-5-5`) for `critical` | Different model family than the implementer → decorrelated errors; review is few tokens so cost is low |
| CI-fix retries | same as implementer | |

**Wiring:** Claude Code (and therefore `claude-code-action`) talks to any provider that exposes an Anthropic-compatible Messages API by setting `ANTHROPIC_BASE_URL` + the provider key. Several open-weights providers (Z.ai, Moonshot, DeepSeek, MiniMax) offer such endpoints; alternatively run a translation proxy (e.g. LiteLLM) in front of OpenRouter/Together/Fireworks. Verify in P1-T01 that the action passes these env vars through. Model names live in repo variables (`IMPLEMENTER_MODEL_SAFE`, `IMPLEMENTER_MODEL_CRITICAL`, `REVIEWER_MODEL`), so switching is a settings change, not a PR.

**Decide by measurement, not vibes** (task P1-T11):
1. Freeze 6 representative tasks (2 × P2 domain, 2 × P3 slice, 1 × P4, 1 × mutation-kill) on a branch with known-good reference solutions.
2. Run each candidate model 2× per task with the real workflow and gates.
3. Record: `make check` green on first PR (y/n), CI-fix rounds, turns, wall time, $ per merged PR, mutation score, reviewer-found defects.
4. Pick the cheapest model whose green-first-try rate is within ~15 pp of Sonnet. Log results in `docs/agent-metrics.md`; re-run quarterly.

**Guardrails specific to open-weights:** stricter `--max-turns` (40), job timeout 45 min, never routed to `critical` issues (the workflow reads the issue's risk label and picks the model), no access to any secret beyond the provider key.

### 6.8 Cost budget & hard caps

Target: **≈ €45–80 / month during active development, ≈ €30 / month in maintenance.** All numbers are rough estimates — prices change, verify at signup and measure real cost per PR in P1-T11.

| Item | Plan | Est. cost |
|---|---|---|
| Apple Developer | yearly | ~€99 / year (~€8 / month) |
| Google Play Console | one-time | ~$25 |
| Supabase prod | Pro (EU), daily backups included; PITR **not** booked | ~$25 / month |
| Supabase staging | Free plan (pauses after inactivity — `deploy-dev` wakes it; acceptable) | €0 |
| Firebase (FCM + Hosting) | Spark (free) | €0 |
| Sentry | Developer (free) tier, EU | €0 |
| GitHub | private repo, Free plan Actions quota (Linux minutes; macOS minutes count with a large multiplier) | €0 if within quota, then pay-as-you-go with **$0 spending limit** by default |
| LLM — Claude (critical tasks + reviewer) | **Use the existing Claude subscription** via `CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`) in the action instead of an API key → no marginal cost, bounded by subscription usage limits | €0 extra (if subscription already paid) |
| LLM — open-weights implementer | prepaid credits, **auto-top-up off** | cap €20–40 / month |

**Hard caps (mechanical, not willpower):**
- LLM providers: prepaid balance only, no auto-recharge; Anthropic API key (only if used instead of the subscription) with a workspace spend limit.
- GitHub: Actions spending limit $0 → jobs stop instead of billing; raise deliberately.
- Agent workflows: `concurrency: agent` (max 1 agent job at a time), `--max-turns 40`, `timeout-minutes: 45`, max 2 CI-fix retries per PR, max **N agent runs per day** (repo variable `AGENT_DAILY_LIMIT`, default 6; the workflow counts today's runs via `gh run list` and exits early).
- Reviewer runs only once CI is green (no reviewing broken code), and re-reviews only the incremental diff.
- Mutation: per-PR only on changed files; nightly full run only if `main` changed since last run.

**CI minute savers:**
- Path filters: backend jobs only on `supabase/**`, Android emulator only with label `e2e-android` or on release, iOS simulator only on release tags.
- iOS/TestFlight builds nightly-if-changed instead of on every merge (macOS minutes are the most expensive item).
- `concurrency: cancel-in-progress` per PR; aggressive caching (pub, build_runner outputs, Gradle, Docker images for Supabase).
- Agents run `make check` locally inside their job before pushing → fewer red CI rounds.
- Optional, €0: register the owner's Mac as a **self-hosted macOS runner** for iOS builds (only works while the Mac is awake; GitHub-hosted macOS as fallback).
- Alternative to evaluate: making the repo **public** makes standard GitHub-hosted runners free — only with label-gated agent workflows (already the case) and no secrets in fork-triggered workflows.

**Monitoring:** `agent-metrics.md` monthly row: runs, merged PRs, $ per merged PR per model, CI minutes. If $/PR for the open-weights model is not clearly below the subscription-backed Claude path, drop it (subscription is flat-rate).

---

## 7. Phases & tasks

### P0 — Repository foundation (human-led, ~1 day)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P0-T01 | Create pub workspace: root `pubspec.yaml`, `packages/domain`, `packages/drive_client`, `app/` (`flutter create --org … --platforms ios,android,linux`) | `dart pub get` at root succeeds; `flutter run -d linux` shows default app | critical |
| P0-T02 | Shared `analysis_options.yaml` (`very_good_analysis`, strict modes), `dart format` page width decision | `make lint` 0 issues | critical |
| P0-T03 | `Makefile` with all targets from §5.1 (stubs allowed where tooling arrives later) | each target exits 0 or prints "not yet available" | critical |
| P0-T04 | `lefthook.yml`: pre-commit fmt + lint + gitleaks; pre-push `make check-fast` | hooks run locally | critical |
| P0-T05 | `CLAUDE.md` + `AGENTS.md` v1, `docs/adr/0001…0012` from §1 | files exist, reviewed by owner | critical |
| P0-T06 | Issue template `agent_task.yml` (fields: context, do, accept, out-of-scope, test notes) + PR template (checklist: tests, `make check`, risk, screenshots/goldens) | templates render on GitHub | critical |
| P0-T07 | `.claude/settings.json` (permissions, hooks), `.mcp.json` (dart mcp-server) | `claude` in repo: hooks fire on edit | critical |
| P0-T08 | Toolchain pinning: `.fvmrc` or `flutter-version` file, Dart SDK constraint, `.tool-versions` for supabase CLI / node / deno | CI and local use same versions | critical |

### P1 — Guardrails & CI skeleton (human-led, ~2–3 days)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P1-T01 | **Tooling spikes** (timebox 0.5 d): verify `mutation_test` on a sample domain file; `flutter run --vmservice-out-file`; `dart mcp-server` capabilities; `claude-code-action@v1` inputs; alchemist on Linux CI; `-d linux` integration tests under xvfb | spike notes in `docs/adr/0013-tooling-spikes.md`; any replacement tool chosen | critical |
| P1-T02 | `tool/coverage_gate.dart`: parse `lcov.info`, strip generated files, per-glob thresholds (§3), baseline ratchet vs main artifact | unit tests for the gate itself; fails on synthetic low coverage | critical |
| P1-T03 | `tool/mutation_gate.dart` + mutation config (rules XML, excludes); `make mutate CHANGED=1` computes changed files via `git diff origin/main` | fails below threshold on sample | critical |
| P1-T04 | `architecture_test.dart` with rules from §2.2 / §5.3 | deliberate violation in a test fixture fails | critical |
| P1-T05 | `ci.yml` (fmt, lint, arch, test, coverage, mutation-changed, gitleaks, osv), caching of pub + build_runner | green on main | critical |
| P1-T06 | `risk-label.yml` + `tool/risk_label.sh` + `CODEOWNERS` + branch protection | test PRs get correct labels | critical |
| P1-T07 | GitHub App for agent (contents, PRs, issues, checks), secrets `ANTHROPIC_API_KEY`, `AGENT_APP_*` | token works in a dry-run workflow | critical |
| P1-T08 | `agent-implement.yml` (no automerge yet) + `agent-review.yml` | a trivial issue ("add README badge") goes issue → PR → review comment | critical |
| P1-T09 | `desktop-it.yml` with xvfb + a hello-world integration test | green | critical |
| P1-T10 | Golden setup (alchemist, bundled fonts, `goldens` vs `ci` config) | one sample golden passes in CI | critical |
| P1-T11 | Model eval harness (§6.7): frozen task set, runner workflow, metrics table | ≥ 2 open-weights models + Sonnet measured; ADR-15 updated with numbers | critical |
| P1-T12 | `app/app_identity.yaml` (name `mitlio`, ids per ADR-16) consumed by flavors/fastlane; verify name availability: App Store Connect name reservation, Play Console, `mitlio.web.app` Hosting site id free, EUIPO/DPMA trademark search | name reserved in App Store Connect; Hosting site created | critical |

**Exit P1:** an issue labelled `agent-implement` produces a reviewed PR whose CI enforces every gate. From here, agents do the bulk of the work.

### P2 — Domain core (agent, ~2–3 days)

All in `packages/domain`. Pure Dart, `freezed` models allowed (or hand-written immutable classes if codegen hurts mutation tooling — decide in P1-T01).

| ID | Task | Accept | Risk |
|---|---|---|---|
| P2-T01 | `Money` (int cents + `Currency`), arithmetic, comparison, formatting-agnostic; `Currency` ISO list with minor units (JPY = 0) | overflow guarded; property: `a + b − b == a` | safe |
| P2-T02 | `allocate(totalCents, weights, tieOrder)` — largest remainder, deterministic | property: Σ = total for all inputs; equal weights differ by ≤ 1 cent; same input → same output | safe |
| P2-T03 | `SplitSpec` + `computeShares` for equal / shares / percent / exact / exclusion; validation errors as sealed `SplitError` | examples from `domain-rules.md`; property: Σ shares = amount | safe |
| P2-T04 | `Expense` aggregate with multiple payers; validation (payers sum, members in group, amount > 0) | invalid aggregates unconstructible (factory returns `Result`) | safe |
| P2-T05 | `computeBalances(expenses, settlements, members)` | property: Σ balances = 0; settlement of full debt zeroes both | safe |
| P2-T06 | `simplifyDebts(balances)` greedy | property: transfers ≤ n−1; applying transfers zeroes all balances; no self-transfers; deterministic order | safe |
| P2-T07 | `TripCost` calculator (consumption mode + km-rate mode, tolls, ferry, wear, driverCounts, passenger selection) → produces `Expense` | worked examples; Σ = total; driver is payer | safe |
| P2-T08 | FX: `convert(amount, rateppm)` banker's rounding; rate value object | edge cases (0-decimal currencies) | safe |
| P2-T09 | `PayPalMeLink.build(handle, amount)` → `https://paypal.me/<handle>/<12.34><CUR>`; handle validation | rejects spaces/invalid chars; URL-encodes | safe |
| P2-T10 | `EpcQrPayload.build(name, iban, bic?, amount, remittance)` (BCD/002/1/SCT, EUR only, ≤ 999 999 999.99, name ≤ 70, remittance ≤ 140) + IBAN mod-97 validator | spec examples; invalid IBAN rejected; non-EUR rejected | safe |
| P2-T11 | `docs/domain-rules.md` with all worked examples, wired as table-driven tests (single source) | doc examples == test data (test loads the doc's fenced JSON) | safe |
| P2-T12 | Mutation hardening pass: run full mutation, kill survivors | domain mutation ≥ 85 %, coverage ≥ 95 % | safe |

### P3 — Local app MVP (agent, ~5–7 days)

Shared infrastructure first, then vertical slices. Each slice = repository + ViewModel + View + DebugDrive handler + tests (unit, widget, golden, integration).

| ID | Task | Accept | Risk |
|---|---|---|---|
| P3-T01 | `core/`: `Clock`, `IdGenerator` (UUIDv7), `Logger`, error sink, Riverpod root, `go_router` routes | arch test green | safe |
| P3-T02 | Drift `AppDatabase` v1: tables from §2.4 (no sync columns used yet but present), DAOs, schema export to `drift_schemas/` | schema test; in-memory DB in tests | critical (schema) |
| P3-T03 | Repository interfaces + Drift impls + in-memory fakes + **shared contract test suite** for Groups, Members, Expenses, Settlements | contract tests pass for both impls | safe |
| P3-T04 | DebugDrive skeleton: `ext.mitlio.ping/reset/seed/state/navigate/errors`, `packages/drive_client` CLI, `tool/drive.sh`, `make drive-up` | `make drive-up && tool/drive.sh ext.mitlio.ping` returns JSON in CI (desktop-it) | critical (debug/) |
| P3-T05 | Design system: theme, spacing, `MoneyText`, `MemberAvatar`, `AmountField` (cents-safe input), empty/error states + goldens | goldens green | safe |
| P3-T06 | Slice **Groups**: list, create, edit name/currency, archive; members add/rename/reorder/remove (blocked if member has entries) | VM tests, widget tests, goldens, `ext.mitlio.groups.create`, IT: create group with 4 members | safe |
| P3-T07 | Slice **Expense form**: title, amount, currency (= group currency in MVP), date, category, payers (single/multi), split modes incl. exclusion, live per-person preview | VM covers all modes + validation; IT: add each split mode | safe |
| P3-T08 | Slice **Expense list**: per group, grouped by date, filter by member/category, swipe to delete (soft) | IT: add → delete → balances update | safe |
| P3-T09 | Slice **Trip cost form**: km, consumption, fuel price, tolls/ferry, wear, km-rate toggle, driver, passengers, driverCounts; shows breakdown | IT via `ext.mitlio.trips.add` and via UI | safe |
| P3-T10 | Slice **Balances**: per-person net, "who owes whom" (simplified), toggle raw vs simplified | IT: seed scenario `trip_4p` → expected transfers equal fixture | safe |
| P3-T11 | Seed scenarios in `tool/fixtures/` (`empty`, `trip_4p`, `household_2p`, `rounding_edge`, `large_200_expenses`) | `ext.mitlio.seed` loads each; perf: balances for 200 expenses < 16 ms | safe |
| P3-T12 | i18n setup (`flutter gen-l10n`) DE + EN, number/currency formatting via `intl` | no hardcoded strings (arch test) | safe |
| P3-T14 | UX infrastructure: `TapCounter` test helper, `docs/ux-budgets.md`, `tool/deps_policy.dart`, golden matrix (light/dark × text scale), CI attaches golden diffs to PR | budgets enforced in at least one IT per flow | critical |
| P3-T13 | Accessibility pass: semantics labels, text scaling 200 %, contrast; `meetsGuideline` tests | a11y guideline tests green | safe |

### P3r — Rides / private taxometer (agent, ~4–5 days)

The ride log is the app's headline feature for commuters.

| ID | Task | Accept | Risk |
|---|---|---|---|
| P3r-T01 | Domain: `Vehicle`, `Ride`, `RideTemplate`; `rideCost(ride, vehicle, price)` incl. EV (kWh) and km-rate mode; return trip doubling | property: Σ shares = cost; fixtures shared with web (`tool/fixtures/trip_*.json`) | safe |
| P3r-T02 | Domain: `aggregateRides(rides, period)` → one expense per (driver, period) with per-passenger shares, plus "driver counts" option; period = day/week/month/custom | property: Σ of aggregated expenses = Σ ride costs; deterministic | safe |
| P3r-T03 | Drift tables `vehicles`, `ride_templates`, `rides` + repositories + contract tests | contract tests green | critical (schema) |
| P3r-T04 | Vehicles UI: add/edit vehicle with consumption, fuel type, wear rate | VM + widget + goldens | safe |
| P3r-T05 | **Quick log**: home-screen "Heute gefahren" — pick template, driver, toggle passengers, 2 taps to save; calendar view of who drove when | IT: log 10 commute days via UI and via `ext.mitlio.rides.log`; perf: open → saved < 3 taps | safe |
| P3r-T06 | Period settlement: "Abrechnen für Oktober" turns rides into expenses (locked rides, undo possible) → flows into balances/settle | IT: month of rides → expected transfers fixture | safe |
| P3r-T07 | Fairness view: per person km driven vs ridden, "wer ist als Nächstes dran" suggestion | VM tests | safe |
| P3r-T08 | Deep link import `mitlio://ride?km=…&l100=…&price=…&n=…` (from web calculator) → prefilled ride form | IT via `ext.mitlio.navigate` with link | safe |

### P4 — Settle & pay (agent, ~1–2 days)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P4-T01 | Member payment details: `paypal_me` (synced later), IBAN/BIC/account name in `local_member_bank` (never synced, optionally encrypted via `flutter_secure_storage` key) | IBAN validated; arch test: sync code never reads `local_member_bank` | critical (PII) |
| P4-T02 | `PaymentLinkService`: opens PayPal.Me via `url_launcher` (external app), fallback copy-to-clipboard | service tested with fake launcher | safe |
| P4-T03 | Settle screen: list simplified transfers, per transfer actions: PayPal link, EPC QR (`qr_flutter`, error correction M), copy IBAN, "mark as paid" (amount editable for partial payments) | IT: mark paid → balance zero; golden of QR sheet | safe |
| P4-T04 | Settlement history + undo (soft delete) | VM + IT | safe |
| P4-T05 | Share summary as text (share sheet) | widget test | safe |

### PW — SEO web calculator (agent + human content review, ~5–7 days; start right after P2-T07)

Go live **early** (before the app ships) — SEO needs months to compound. Until the app is in the stores, the CTA is "App kommt bald — Benachrichtigen" (email waitlist via Supabase table + double opt-in, or simply skip and show store badges once live).

| ID | Task | Accept | Risk |
|---|---|---|---|
| PW-T01 | `packages/domain_web`: js_interop facade exporting `calculateTrip(input) → {total, perPerson[], breakdown}`, `dart compile js -O4`; size budget | bundle ≤ 150 kB gz; vitest parity over all trip fixtures | safe |
| PW-T02 | Astro scaffold in `web/` (static output, de default + en, hreflang, sitemap, robots, canonical), design tokens shared with app theme | `npm run build` static; Lighthouse ≥ 95 | critical (new deps) |
| PW-T03 | Calculator island: distance, consumption (l/100 km or kWh), fuel price, number of persons, driver pays share yes/no, return trip, tolls/extras; **result-first card "Jede Person zahlt X €"** + breakdown; live recalculation; state in URL params | Playwright: typing updates result; URL reload restores state | safe |
| PW-T04 | **Clickable live fuel prices**: chips for E5/E10/Diesel (national average by default, "in meiner Nähe" via opt-in geolocation/PLZ) → tap fills price; source + timestamp + attribution shown | Playwright with mocked API; chip tap sets price | safe |
| PW-T05 | Share: Web Share API / WhatsApp text ("Fahrt nach München: 4 Personen, je 18,20 €") + copy link | Playwright | safe |
| PW-T06 | App CTA: sticky "Regelmäßig fahren? Fahrten speichern & monatlich abrechnen" → smart app banner (`apple-itunes-app` meta), Play badge, deep link carrying the trip (P3r-T08) | link format test | safe |
| PW-T07 | Landing pages per search intent (each with calculator embedded + unique explanatory content + FAQ): `/fahrtkostenrechner`, `/spritkosten-teilen`, `/fahrgemeinschaft-kosten-aufteilen`, `/pendler-fahrgemeinschaft`, `/mitfahrer-kosten-berechnen`, `/kilometerpauschale-rechner`, `/elektroauto-ladekosten-teilen`; EN equivalents later | human reviews copy; each page unique title/description/H1 | safe |
| PW-T08 | Structured data: `WebApplication`/`SoftwareApplication`, `FAQPage`, `HowTo`, `Organization`; OG/Twitter images generated at build | `tool/seo_check` validates JSON-LD; Rich Results Test manual once | safe |
| PW-T09 | Privacy-friendly analytics without cookies (e.g. GoatCounter/Plausible/Cloudflare Web Analytics) — no consent banner needed; events: calculation done, share, app CTA click | no cookies set (Playwright asserts `document.cookie` empty) | critical (privacy) |
| PW-T10 | Hosting: Firebase Hosting on own domain, preview channels per PR, cache headers, security headers (CSP), `/.well-known/*` for app links | headers test; preview URL commented on PR | critical |
| PW-T11 | Google Search Console + Bing Webmaster verification, sitemap submission; monthly SEO report (impressions, CTR, top queries) into `docs/seo-metrics.md` | Search Console shows indexed pages | critical (human) |

### P6c — Live fuel prices backend (agent + review, ~2–3 days; needed by PW-T04, can precede P6)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P6c-T01 | Spike result from P1-T01 applied: Tankerkönig terms, rate limits, attribution; E-Control (AT); EU Weekly Oil Bulletin for other countries | ADR-20 confirmed or amended | critical |
| P6c-T02 | Migration `fuel_price_cache` (public read via RLS, write only service role) | pgTAP | critical |
| P6c-T03 | Edge Function `fuel-prices`: `GET ?type=e5&lat=…&lng=…&radius=…` or `?plz=` or national average; cache TTL (e.g. 10 min nearby, 1 h average), never forwards client IP/location to provider beyond rounded coords | vitest + Stryker on `_shared/fuel.ts`; integration test against a provider stub | critical |
| P6c-T04 | `pg_cron` job refreshing national/state averages periodically (computed from station data within provider limits) | pgTAP + function test | critical |
| P6c-T05 | App `FuelPriceService` (+ fake): chips in ride/trip form, auto-fill per vehicle fuel type, price frozen on the ride; offline → last known value with age label | VM tests; IT via fake | safe |
| P6c-T06 | Abuse protection: per-IP rate limit on the function, CORS restricted to own domain + app | test | critical |

### P5 — Real-world validation (human, 1 weekend + 1–2 days fixes)

| ID | Task | Accept |
|---|---|---|
| P5-T01 | Internal build to own devices (TestFlight / APK) — requires P8-T01/T02 minimal versions or manual build | app installed |
| P5-T02 | Use on a real trip; log every friction point and every number you doubted as issues (`label: field-test`) | issue list |
| P5-T03 | For every disputed number: add a fixture + test reproducing it | fixtures merged |
| P5-T04 | **Go/no-go for sync**: decide P6 scope based on findings | decision recorded as ADR |

**Milestone M1 = P0–P5: usable single-device app, all MVP features, ~2–3 weeks.**

### P6 — Backend, auth, sharing & sync (agent + human review, ~2–3 weeks)

Backend tasks are all `critical` → human review. Agents still write them; pgTAP makes review fast.

| ID | Task | Accept | Risk |
|---|---|---|---|
| P6-T01 | Supabase project init (`supabase init`), `config.toml`, staging + prod projects, `make db-up/db-test` | `supabase start` in CI works | critical |
| P6-T02 | Migration 001: tables (§2.4) with constraints, `server_seq` sequence + trigger, `updated_at` validation, soft delete | `supabase db reset` green; squawk clean | critical |
| P6-T03 | RLS: `is_group_member(group_id)` `security definer` function; policies select/insert/update per table; no hard delete | pgTAP: member allow, non-member deny, anon deny for every table; `rls_coverage.sql` asserts every table has RLS enabled + tests | critical |
| P6-T04 | RPC `upsert_expense(payload jsonb)`: transactional replace of payers/shares, invariant checks (sums), LWW compare on HLC, returns server row | pgTAP: invariant violation rejected; stale HLC ignored; newer wins | critical |
| P6-T05 | Invites: `create_invite(group_id)` → token (store hash only, 7-day expiry, revocable); `join_group(token, member_id?)` claims a participant or creates one | pgTAP: expired/revoked/reused tokens; cannot join twice | critical |
| P6-T06 | Generated TS/Dart types + CI drift check (`supabase gen types` diff) | CI fails on stale types | critical |
| P6-T07 | App auth: anonymous sign-in on first share action, session persistence, sign-out wipes local server-linked data (with confirmation) | VM tests with fake auth | critical |
| P6-T08 | HLC implementation in domain (`Hlc.now(clock, last)`, `Hlc.receive`, compare) | property tests: monotonic, causality | safe |
| P6-T09 | Outbox: every repository write in a group marked `shared` enqueues aggregate op in same Drift transaction | repository tests: write + outbox atomic | critical |
| P6-T10 | `SyncService.push`: drain outbox with backoff, idempotent (op id), handles 4xx (drop + surface) vs 5xx (retry) | fake remote tests incl. network flaps (`fake_async`) | critical |
| P6-T11 | `SyncService.pull`: by `server_seq` cursor per group, apply with LWW (HLC), children replaced per aggregate, tombstones respected | merge logic in pure Dart → mutation ≥ 70 % | critical |
| P6-T12 | Realtime: subscribe to group channels → trigger pull (not apply payload directly) | IT with local supabase | critical |
| P6-T13 | **Sync E2E harness**: two headless app containers (repositories + SyncService, no UI) against local Supabase; scenarios: offline edit both → LWW; delete vs edit; join via invite; 500 ops convergence | all scenarios converge to identical state (hash compare) | critical |
| P6-T14 | UI: share group (invite link + QR), join flow (`https://mitlio.web.app/join/<token>` universal/app link, `mitlio://join/<token>` fallback; AASA + assetlinks served by Firebase Hosting per ADR-17), "claim yourself" member picker, sync status indicator | IT with fake backend; drive `ext.mitlio.sync.*` | safe |
| P6-T15 | Convert local group → shared group (upload existing history) | E2E: local data appears on second device | critical |
| P6-T16 | `min_supported_version` config table + app gate | test | critical |

**Milestone M2: groups shared across devices, offline-first.**

### P6b — Push notifications (agent + human review, ~4–5 days, after P6-T13)

**Goal:** when another member adds/changes/deletes an expense or records a settlement, the other members get a notification; tapping it opens the expense and triggers a sync.

**Flow:**

```
App A ──upsert_expense RPC──▶ Postgres
                               │ AFTER trigger (only if actor ≠ null and change is user-visible)
                               ▼
                        notification_outbox (pending)
                               │ pg_cron every 60 s → pg_net POST (service-role secret)
                               ▼
                 Edge Function `notify`
                   1. claim pending rows (UPDATE … SET processed_at … RETURNING, SKIP LOCKED)
                   2. resolve recipients: group members with user_id, minus actor,
                      minus prefs (none / quiet hours / "mine" = only expenses where I have a share)
                   3. coalesce per (recipient, group) within window:
                      1 event  → "Anna added 'Fuel' · 42,00 €"
                      n events → "Anna added 3 expenses in 'Italy trip'"
                   4. build FCM v1 messages (loc-keys + args → rendered in device language)
                   5. send via FCM HTTP v1 (OAuth from service-account secret)
                   6. delete tokens on UNREGISTERED / INVALID_ARGUMENT
                               ▼
                    FCM ──▶ Android  /  APNs ──▶ iOS
                               ▼
App B: tap → deep link mitlio://group/<gid>/expense/<eid> → SyncService.pull → open detail
       foreground: no system banner, in-app snackbar + pull
```

**Design rules:**
- Payload carries **IDs + display strings only** (actor name, title, amount formatted). Never IBAN or notes. An option "hide amounts on lock screen" switches to a generic body.
- Coalescing window = cron interval (60 s), so a burst of 10 edits from one person = 1 notification per recipient.
- Edits only notify if amount, payers or shares changed (not a title typo) — decided in the trigger by comparing old/new.
- Notifications are a **hint**, never a data channel: the app always syncs from the server, so dropped pushes don't cause inconsistency.
- Android 13+ / iOS permission asked contextually (after first share or join), not on first launch.

| ID | Task | Accept | Risk |
|---|---|---|---|
| P6b-T01 | Firebase project (messaging only) for dev + prod, APNs auth key uploaded, `firebase_messaging` + `flutter_local_notifications` wired per flavor | test push from console arrives on both platforms (human check, once) | critical |
| P6b-T02 | Migration: `device_tokens`, `notification_prefs`, `notification_outbox` + RLS (tokens/prefs own rows, outbox no client access) | pgTAP: user cannot read others' tokens; client cannot read/write outbox | critical |
| P6b-T03 | Trigger on `expenses`/`settlements`/`members` writes → outbox row with "is user-visible change" logic | pgTAP: insert → 1 row; title-only edit → 0 rows; sync replay of same HLC → 0 rows | critical |
| P6b-T04 | `supabase/functions/_shared/notify.ts`: pure functions `resolveRecipients`, `coalesce`, `buildMessages` | vitest ≥ 90 % coverage, Stryker ≥ 80 % | critical |
| P6b-T05 | Edge Function `notify` (claim with `SKIP LOCKED`, FCM client behind interface, token cleanup, retries with max attempts) + `pg_cron` schedule | integration test: local Supabase + **FCM stub server** (records requests) → assert payloads | critical |
| P6b-T06 | App `PushService` interface (+ fake): permission flow, token register/refresh/unregister on sign-out, upsert to `device_tokens` | VM/service tests with fake messaging | safe |
| P6b-T07 | Notification routing: tap/foreground/background handlers → router + `SyncService.pull`; `ext.mitlio.push.simulate(payload)` DebugDrive handler to test routing without FCM | IT: simulate payload → expense detail open, sync called | safe |
| P6b-T08 | Settings UI: per-group level (all / only mine / none), quiet hours, hide amounts | VM tests + goldens | safe |
| P6b-T09 | Localization of loc-keys (DE/EN) in Android `strings.xml` + iOS `Localizable.strings`, generated from the ARB files | script test: every loc-key exists in all locales | safe |
| P6b-T10 | Observability: `notify` logs counts per run, failure rate alert (Sentry cron monitor) | alert fires in staging on forced failure | critical |

**Testing without real devices:** CI never talks to FCM. `notify` takes `FCM_ENDPOINT` from env; in CI it points to a tiny stub (Deno HTTP server) that stores requests, and tests assert on them. Real-device delivery is checked once per release in the staging smoke checklist.

### P7 — Product polish (agent, ~2 weeks)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P7-T01 | Multi-currency per expense: currency picker, manual rate, frozen `fx_rate_ppm`; balances in group currency | domain + VM tests; IT | safe |
| P7-T02 | Edge Function `fx-rates`: daily fetch from ECB/Frankfurter into `fx_rates` table via `pg_cron`; app suggests rate, user can override | vitest + Stryker on `_shared/fx.ts`; pgTAP for table RLS (read-only) | critical |
| P7-T03 | Edit expense with history: `expense_revisions` (server trigger + local mirror), "history" sheet showing diffs and author | pgTAP trigger test; VM tests | critical (migration) |
| P7-T04 | Export CSV (all expenses + balances) and PDF settlement report (`pdf` package), share sheet | golden for PDF page render; CSV snapshot test | safe |
| P7-T05 | Statistics by category/member/time (charts) | VM tests + goldens | safe |
| P7-T06 | Onboarding + empty states + app icon/splash | goldens | safe |
| P7-T07 | Privacy policy, imprint, in-app data deletion (account + server data via RPC `delete_my_data`) | pgTAP for deletion; legal text reviewed by human | critical |
| P7-T08 | Crash/error reporting: `sentry_flutter` (EU region DSN per flavor), `beforeSend` scrubber, debug symbols upload in release workflow; opt-in analytics only | test: scrubber removes IBAN/member names/notes from events + breadcrumbs | critical |

### P8 — Delivery pipeline (human + agent, ~3–5 days, can run in parallel with P6/P7)

| ID | Task | Accept | Risk |
|---|---|---|---|
| P8-T01 | Flavors `dev`/`prod` (bundle ids, app names, Supabase URLs via `--dart-define-from-file`) | both build locally | critical |
| P8-T02 | fastlane match (or Codemagic) for iOS signing; Android keystore in secrets; Play service account | signed builds in CI | critical |
| P8-T03 | `deploy-dev.yml`: merge → staging migrations; nightly-if-changed → TestFlight + Play internal | build appears in TestFlight | critical |
| P8-T04 | `release.yml`: tag → `production` environment approval → prod migrations → smoke drive scenario vs staging → store submission (phased) | dry run on a `v0.0.1-rc` tag | critical |
| P8-T05 | `release-please` for changelog + version bump from conventional commits | release PR generated | critical |
| P8-T06 | `check_release_strip.sh`: build release, assert no `ext.mitlio` strings / debug symbols in binary | fails if `kDebugMode` guard removed | critical |
| P8-T07 | Enable `automerge.yml` for `safe` PRs after ≥ 20 agent PRs reviewed manually with < 10 % rework | metrics recorded in `docs/agent-metrics.md` | critical |
| P8-T08 | `agent-fix-ci.yml` (auto-retry on CI failure, max 2) + `mutation-nightly.yml` that files `agent-implement` issues for surviving mutants | loop observed on a sample | critical |

### P9 — Later / backlog (agent-ready issues)

| ID | Task | Notes |
|---|---|---|
| P9-T01 | Receipt photo attach (Supabase Storage, RLS by group, image compression) | storage policies need pgTAP-equivalent tests |
| P9-T02 | OCR of receipts (on-device ML Kit) prefilling amount/date | behind feature flag |
| P9-T03 | Recurring expenses (rule engine in domain) | domain-first |
| P9-T04 | Payment reminders ("you owe Anna 23 €" after N days, opt-in) | builds on P6b outbox + cron |
| P9-T05 | Weekly group digest notification | builds on P6b |
| P9-T06 | Web app target (read-only share link) | |
| P9-T07 | Per-field merge instead of aggregate LWW, if field data shows lost edits | ADR first |

---

## 8. Security & privacy guardrails

- **IBANs:** stored only locally (`local_member_bank`), never synced; architecture test asserts sync code never imports it. Only a masked hint (`DE89 …3000`) may be synced if the user opts in.
- **RLS on every table**, enforced by a CI check (`rls_coverage.sql` fails if a table lacks RLS or tests).
- **Invite tokens:** 128-bit random, stored as SHA-256 hash, expiring, revocable, single member claim.
- **Secrets:** none in repo (`gitleaks`), Supabase anon key only in app; service role key only in Edge Functions env.
- **DebugDrive:** compiled out of release (`kDebugMode` + `check_release_strip.sh`); never listens on non-loopback.
- **Agent safety:** only maintainers can apply `agent-implement`; agent cannot modify workflows/gates (critical paths + CODEOWNERS); `--max-turns` + job timeout as budget; no production secrets available to agent workflows (only staging env).
- **Payment status** is user-asserted ("mark as paid"); UI states this clearly — no claim of verification.
- **GDPR:** privacy policy before P6 ships; data deletion RPC; EU-hosted Supabase region.

---

## 9. Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Sync conflicts (two offline edits of same expense) | lost edit | aggregate LWW by HLC; revision history (P7-T03) makes losses recoverable; E2E scenarios |
| Clock skew between devices | wrong LWW winner | HLC instead of wall clock; server rejects HLC too far in future |
| Rounding disputes | user trust | integer cents, largest remainder, documented rules, fixtures from real trip |
| FX rate changes retroactively altering balances | user trust | rate frozen per expense |
| Mutation tooling immature for Flutter app code | gate unreliable | mutation gate strict only on pure Dart (domain, merge logic); P1-T01 spike |
| Golden flakiness across platforms | red CI | goldens only on Linux CI with bundled fonts; local `--update-goldens` via docker image |
| Agent produces large/unfocused PRs | review load | issue template with out-of-scope field; > 400 lines → critical; reviewer agent flags scope creep |
| Agent games gates (skips tests, lowers thresholds) | false green | gates & workflows are critical paths; arch test forbids `skip:`/`@Skip` without issue link |
| Emulator / macOS minutes cost | budget | desktop IT as default; Android on PR only when labelled; iOS on main only |
| Notification spam (burst edits, sync replays) | users disable push | 60 s coalescing, "user-visible change" filter in trigger, HLC dedupe, per-group levels |
| Push leaks data on lock screen | privacy | IDs + minimal strings only, "hide amounts" option, never IBAN/notes |
| Open-weights implementer quality drift / provider outage | stalled pipeline | model names in repo variables, fallback to Sonnet, quarterly eval |
| App Store review delays | slower prod | phased release; backend backward compatible N−2 |

---

## 10. Agent task template (`.github/ISSUE_TEMPLATE/agent_task.yml` content)

```markdown
### Task ID
P3-T07

### Context
Links: docs/IMPLEMENTATION_PLAN.md#p3, docs/domain-rules.md#split-modes

### Do
- …

### Accept (all must be verifiable by command)
- [ ] `make check` green
- [ ] New ViewModel commands covered: success / validation / repo failure
- [ ] `ext.mitlio.<…>` handler added + documented in docs/drive-protocol.md
- [ ] Integration test `integration_test/<flow>_test.dart`
- [ ] Mutation (changed files) ≥ threshold

### Out of scope
- …

### Drive verification (agent runs and pastes output in PR)
make drive-up SCENARIO=trip_4p
tool/drive.sh ext.mitlio.balances.get '{"groupId":"<id>"}'
```

---

## 11. Timeline & milestones

| Milestone | Phases | Est. calendar time | Outcome |
|---|---|---|---|
| M0 Harness | P0–P1 | ~1 week | agents can safely produce PRs |
| M1 Local MVP | P2–P5 incl. P3r | ~3–4 weeks | usable single-device app incl. ride log, field-tested |
| MW Web live | PW + P6c (parallel to M1) | ~1.5 weeks | SEO calculator with live fuel prices indexed, waitlist/app CTA |
| M2 Shared groups | P6 + P6b (+P8 in parallel) | ~3–4 weeks | multi-device offline-first sync, push notifications, TestFlight/Play internal |
| M3 Store release | P7 + P8-T04 | ~2 weeks | v1.0 in stores |
| M4 Autonomy | P8-T07/T08 | ongoing | safe PRs auto-merge, nightly mutation loop self-heals |

## 12. Owner decisions

| # | Question | Answer (2026-11-13) | Consequence |
|---|---|---|---|
| 1 | Apple Developer account | yes | P8-T02 unblocked; TestFlight from M1 |
| 2 | Supabase EU + paid plan | yes | Pro plan prod (daily backups, no pausing), free plan staging; push via ADR-13 / P6b |
| 3 | App name / bundle id | **mitlio** | ADR-16; reserve store names in P1-T12; bundle id `app.mitlio` fixed at first TestFlight upload (cannot be changed afterwards) |
| 4 | Models | open-weights preferred | ADR-15 / §6.7: open-weights for `safe`, Claude for `critical` + review, decided by P1-T11 eval |
| 5 | Crash reporting | no preference | Sentry EU (ADR-14) |

| 6 | Domain | don't care → **revised: own domain recommended** because of the SEO funnel | ADR-17: e.g. `mitlio.de` (~€10–20/year) on Firebase Hosting; needs owner purchase before PW-T10 |
| 8 | Positioning | private taxometer + SEO web calculator funnel, live clickable fuel prices | Product positioning section, P3r, PW, P6c, ADR-19/20 |
| 7 | Monthly budget | as low as sensible | ADR-18 / §6.8: ~€45–80 dev, ~€30 maintenance; Claude via existing subscription, prepaid open-weights cap €20–40, GitHub spend limit $0 |

No open owner questions remain for P0–P1.
