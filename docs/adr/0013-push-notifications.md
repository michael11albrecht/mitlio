# ADR-13: Push notifications

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

FCM HTTP v1 (FCM also delivers to iOS via APNs key) sent from a Supabase Edge Function; DB trigger → `notification_outbox` → `pg_cron` every minute → coalesced sends

## Rationale

One push path for both platforms, debouncing is natural, fully testable locally with an FCM stub. Firebase is used **only** for messaging

## Revisit when

No trigger defined.
