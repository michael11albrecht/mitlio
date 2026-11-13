# ADR-15: Agent models

- **Status:** accepted (revised 2026-11-13)
- **Date:** 2026-11-13

## Decision

**Owner decision 2026-11-13: Claude Sonnet (`claude-sonnet-5-5`) for all implementation work** (issues → PRs, CI fixes, mutation-killing, reviews of PRs). **Claude Opus (`claude-opus-5-5`) only for thinking/planning**: task decomposition, plan/ADR updates, architecture questions, root-cause analysis when an agent is stuck. Open-weights models are not used by default (optional later eval, §6.7)

## Rationale

Sonnet is capable and cheap enough for gated implementation; Opus where reasoning depth matters, not for volume

## Revisit when

If Sonnet's first-try green rate on `critical` tasks is poor → consider Opus for those
