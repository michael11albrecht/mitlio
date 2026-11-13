<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# domain (`mitlio_domain`)

## Purpose
Pure Dart business logic: money, splits, balances, debt simplification, trip/ride cost, payment payloads. Currently P0 skeleton exposing `domainRulesVersion`; real logic arrives in P2 (e.g. P2-T03 `SplitSpec` + `computeShares`).

## Key Files
| File | Description |
|------|-------------|
| `lib/mitlio_domain.dart` | Library entry; `domainRulesVersion` (bump when calculation semantics change) |
| `test/mitlio_domain_test.dart` | Skeleton test |
| `pubspec.yaml` | No runtime deps; dev: `test`, `coverage`, `mutation_test` |

## For AI Agents

### Working In This Directory
- **Imports allowed:** dart core libs, `collection`, `meta`. **Never** flutter, drift, supabase, riverpod, or app code (`domain-purity` rule).
- Money is `int` cents. Never `double` for amounts.
- Rounding: largest remainder, ties by member position then id (`docs/domain-rules.md`, P2-T11).
- No `DateTime.now()`, `Random()`, UUIDs — take `Clock`/`IdGenerator`/`Random` as params.
- Validation errors as sealed types, not exceptions for expected cases.

### Testing Requirements
- TDD loop: `make test-domain` (seconds).
- Every function: worked examples (from `docs/domain-rules.md`) + ≥ 1 property test + edge cases (0 participants, 1 cent, max int, all excluded → error).
- Coverage ≥ 90 % on `lib/**`. Mutation score gate via `tool/mutate.sh` (threshold in `tool/mutation/domain.template.xml`, ratchet toward 85).

## Dependencies

### External
- dev only: `test`, `coverage`, `mutation_test`

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
