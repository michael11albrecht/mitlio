# ADR-23: Riverpod without code generation (P3-T01)

- **Status:** accepted (amends ADR-03)
- **Date:** 2026-11-14

## Decision

Use `flutter_riverpod` with hand-written `Provider`/`NotifierProvider` declarations. Do **not** add
`riverpod_generator`, `riverpod_annotation` or `build_runner` for now.

## Rationale

- Generated `*.g.dart` files would need exclusion from coverage gates and mutation tooling, and `build_runner`
  adds a slow generation step to `make check` and CI.
- The overridability that motivated ADR-03 (fakes in tests, DebugDrive seeding) is identical with plain providers.
- Providers here are few and simple; codegen's main benefits (family params, auto-dispose inference) are not needed.
- `make gen` stays a stub until Drift/freezed (P4) need `build_runner`.

## Revisit when

Provider families with many parameters appear, or `build_runner` is introduced anyway for Drift (then migrating is cheap).
