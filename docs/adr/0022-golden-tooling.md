# ADR-22: Golden tooling (P1-T10)

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

Use `alchemist` **0.14.1** (dev dependency of `app`). It resolves and runs on Flutter 3.50 / Dart 3.14, so the
plain `matchesGoldenFile` helper alternative is not needed.

## Policy

- **Only alchemist "CI" goldens are committed and verified**, on every host (macOS, Linux). They render text as
  coloured blocks in the bundled Ahem font, so they are byte-stable across platforms. Platform goldens (real
  glyphs) differ per OS and are disabled in `app/test/flutter_test_config.dart`.
- No extra font asset is bundled in the app: Ahem ships inside alchemist and is loaded by it; icons use the
  Material icon font. Re-evaluate if a design system needs real glyphs in goldens.
- Files live next to the tests: `app/test/golden/goldens/<name>.png`. Tests carry the `golden` tag
  (`app/dart_test.yaml`).
- Matrix (plan §2.6): light/dark x text scale 1.0/2.0. One golden file per brightness (brightness set through the
  platform dispatcher, i.e. what `ThemeMode.system` reads), two scenarios per file (text scale 1.0, 2.0 through
  `MediaQuery`). Since P3-T05 the app has a real `darkTheme`, so the dark golden differs from the light one; it
  follows `ThemeMode.system`.

## Commands

- `make goldens`: verify. Part of `make check`. CI job `goldens` uploads failure diffs (`failures/` PNGs) as an artifact.
- `make goldens-update`: regenerate. Refuses to run when `CI` is set. State why in the PR body.
