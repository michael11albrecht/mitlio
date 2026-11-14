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
