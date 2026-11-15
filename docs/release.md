# Release

## Crash reporting (Sentry EU) — P7-T08

Status: the app code is in place; the release pipeline is not yet wired.

- The DSN is `SENTRY_DSN` (`--dart-define=SENTRY_DSN=...`, EU region `de.sentry.io`). It is empty in the
  repo: builds without it never initialise Sentry and make no network call.
- Reports are sent only if the user turned on Settings > Datenschutz > "Absturzberichte senden" (default off).
- Events pass `app/lib/core/crash/scrubber.dart` before leaving the device.

TODO (owner, needs a `.github/workflows/**` change, therefore not part of P7-T08):

1. Add the DSN as a CI secret and pass it as `--dart-define=SENTRY_DSN=$SENTRY_DSN` in the release builds
   (per flavor, see #84).
2. Upload debug symbols in the release workflow: build with `--split-debug-info=build/symbols`
   `--obfuscate`, then `dart run sentry_dart_plugin` (org, project and `SENTRY_AUTH_TOKEN` as secrets).
3. Verify with a forced crash in a staging build that the event arrives scrubbed and symbolicated.

Note: `configureSentryOptions` removes the SDK's global error integrations by class name. With `--obfuscate`
these names may be mangled and the integrations then stay installed. Events still pass the scrubber and the
opt-in gate; verify this in the staging crash test above.

## Legal texts (Impressum, Datenschutzerklärung) — release blocker

Status: DRAFT ("Entwurf, vor Veröffentlichung prüfen lassen", e.g. a lawyer or a generator such as eRecht24).

- Source: `web/src/i18n/legal.ts` (DE and EN, rendered by `web/src/components/Legal.astro`). The app links to
  these pages from Settings > Datenschutz (`app/lib/features/settings/data/repositories/legal_links_repository.dart`)
  and shows only a short summary, so there is one text to maintain. The app's `SITE_URL` define must match
  `web/site.config.mjs`.
- Placeholders the owner must fill (all `[[...]]` in `legal.ts`): `[[STRASSE HAUSNUMMER]]`, `[[PLZ ORT]]`,
  `[[E-MAIL]]`, `[[ZUSTÄNDIGE LANDESBEHÖRDE FÜR DEN DATENSCHUTZ]]` (the data protection authority of the owner's
  state).
- Gate: `web/src/lib/legal.ts` fails `npm run build` when a `[[` placeholder remains and `SITE_URL` is not the
  stand-in `https://mitlio.web.app` or a local host. To also gate a release build on the stand-in origin, build
  with `LEGAL_STRICT=1`. Tests: `web/tests/legal.spec.ts`.
- Sections for features that are not live (anonymous sign-in, group sync, invite links, push via Firebase Cloud
  Messaging and APNs) are in `futurePrivacySections*` in `legal.ts` and are not rendered. TODO(owner): move them
  into the live text when sync/push ships, and re-check every sentence.
- Re-check the text whenever behaviour changes: new network calls, a DSN in release builds (crash reports),
  the hosting provider, the retention interval of `cleanup_fuel_tables()` (migration 0005).
