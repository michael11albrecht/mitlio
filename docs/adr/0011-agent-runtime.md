# ADR-11: Agent runtime

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

`anthropics/claude-code-action@v1` on GitHub-hosted Ubuntu runners, label-triggered

## Rationale

Event-driven, no polling VM, logs + CI results in one place

## Revisit when

If cost/turn-limits hurt → self-hosted runner
