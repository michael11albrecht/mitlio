# ADR-06: Backend

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

**Supabase** (Postgres + RLS + RPC + Edge Functions)

## Rationale

Relational data, SQL migrations are reviewable diffs for agents, full local stack via `supabase start` (Docker) for integration tests, pgTAP for RLS tests

## Revisit when

If push/realtime cost or complexity explodes → Firebase
