# ADR-16: App identity

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

Name **mitlio**. Single source `app/app_identity.yaml`: display name `mitlio` (dev: `mitlio dev`), URL scheme `mitlio://`, bundle/application id `app.mitlio` / `app.mitlio.dev` (reverse-DNS is only a convention, no domain ownership needed; fixed forever after first store upload), DebugDrive namespace `ext.mitlio.*`

## Rationale

Consumed by flavors + fastlane; any change is one PR

## Revisit when

No trigger defined.
