# ADR-19: Web calculator stack

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

**Astro** static site (prerendered HTML per landing page, zero JS by default) + one small calculator island. Calculation logic = **the Dart domain compiled to JS** (`packages/domain_web`, `dart compile js`, exported via `dart:js_interop`) so web and app compute identical cents; parity additionally guarded by shared fixture tests

## Rationale

Flutter Web renders to canvas → poor SEO and heavy first load; a TS re-implementation would drift from the app

## Revisit when

If dart2js bundle > 150 kB gz → TS port with fixture parity tests
