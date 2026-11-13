# ADR-17: Domain

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

**Own domain (revised 2026-11-13 for SEO)**, e.g. `mitlio.de` (DE-first audience; `mitlio.app` optional redirect), served by Firebase Hosting (free) — hosts the SEO web calculator, `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`, invite fallback `/join/<token>`, privacy policy/imprint. Not Firebase Dynamic Links (shut down). Until the domain exists, `mitlio.web.app` works as a stand-in

## Rationale

A `*.web.app` subdomain ranks and converts worse, can't build brand backlinks, and moving later loses SEO equity. Cost ~€10–20/year

## Revisit when

No trigger defined.
