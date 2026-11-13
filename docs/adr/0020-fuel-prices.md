# ADR-20: Fuel prices

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

Germany: **Tankerkönig API** (MTS-K data, CC BY 4.0, free API key) proxied + cached by a Supabase Edge Function; Austria: E-Control Spritpreisrechner API; elsewhere: EU Weekly Oil Bulletin national averages; EV: manual kWh price with a sensible default. Client never sees API keys; attribution shown

## Rationale

Live clickable prices are the core differentiator; caching keeps us inside provider rate limits and terms

## Revisit when

Verify terms + limits in P1-T01 spike before building
