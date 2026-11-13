<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# adr

## Purpose
Architecture Decision Records. Each file expands one row of the plan §1 summary table.

## Key Files
| File | Description |
|------|-------------|
| `README.md` | Index table of ADRs |
| `0001`–`0020-*.md` | Short decisions: framework, MVVM, state/DI, local DB, domain, backend, sync, auth, payments, mutation testing, agent runtime, monorepo tooling, push, crash reporting, agent models, app identity, domain name, cost policy, web calculator, fuel prices |
| `0021-mutation-tooling-spike.md` | Mutation tooling spike result (backs `tool/mutate.sh`) |

## For AI Agents

### Working In This Directory
- New ADR: next number, `NNNN-kebab-title.md`, add row to `README.md` (and plan §1 if it changes the summary).
- Do not rewrite accepted ADRs; supersede with a new one.
- ADR authoring is Opus/planning work, not implementation.

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
