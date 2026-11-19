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
- The postal address is never committed (the repo is public). `legal.ts` keeps the placeholders
  `[[STRASSE HAUSNUMMER]]` and `[[PLZ ORT]]`; `web/src/lib/legal.ts` (`fillAddress`) replaces them at build time from
  the env vars `LEGAL_STREET` and `LEGAL_CITY`. In CI these are GitHub repo variables (Settings > Variables), passed
  in the build env of `.github/workflows/web-deploy.yml`. For a local production-like build:
  `LEGAL_STREET="..." LEGAL_CITY="..." npm run build`. A missing or blank variable keeps the placeholder, so the
  production gate below fails the build.
- Contacts: imprint `contact@mitlio.de`, privacy controller `privacy@mitlio.de` (mailboxes with a 12-month
  auto-delete rule, see `docs/retention.md`). Supervisory authority: BayLDA, Ansbach.
- Retention periods in the text are interpolated from `supabase/retention.json` (`docs/retention.md`).
- Gate: `web/src/lib/legal.ts` fails `npm run build` when a `[[` placeholder remains and `SITE_URL` is not the
  stand-in `https://mitlio.web.app` or a local host. To also gate a release build on the stand-in origin, build
  with `LEGAL_STRICT=1`. `.github/workflows/web-deploy.yml` (live deploy and preview channels) always sets
  `LEGAL_STRICT=1`, because it deploys the stand-in origin live while `SITE_URL` is unset; a missing `LEGAL_STREET` or
  `LEGAL_CITY` therefore fails that build. Normal CI (`ci.yml`) builds without it. Tests: `web/tests/legal.spec.ts`.
- Sections for features that are not live (anonymous sign-in, group sync, invite links, the Art. 14 notice for
  people who do not use mitlio, server-side deletion, push via Firebase Cloud Messaging and APNs) are in
  `futurePrivacySections*` plus the `changes` of the live sections in `legal.ts` and are not rendered. TODO(owner):
  when sync ships, set `SYNC_PRIVACY_RENDERED = true` in `legal.ts` (and remove the push section first if push does not
  ship with it), have the text reviewed, and re-check every sentence against the shipped behaviour.
- Sync release gate: `web/src/components/Legal.astro` calls `assertSyncDisclosed` (`web/src/lib/legal.ts`) on the
  privacy page. When `app/config/prod.json` has a non-empty `SUPABASE_URL` but the rendered privacy text lacks any
  sync section, `npm run build` fails, so `make web-check` and therefore `make check` fail, and so does the web deploy.
  There is no second check in the Dart gates: the privacy text is built by the web build, and that build runs in
  `make check`. Release order: flip `SYNC_PRIVACY_RENDERED`, deploy the web text, then set `SUPABASE_URL` in the app
  release. Tests for both states: `web/tests/legal.spec.ts` ("release gate").
- Re-check the text whenever behaviour changes: new network calls, a DSN in release builds (crash reports),
  the hosting provider, the retention intervals (`supabase/retention.json`, `docs/retention.md`).

## Android app links (invite links) — P6-T14c

`https://mitlio.de/join/<token>` opens the app on Android only when `https://mitlio.de/.well-known/assetlinks.json`
lists the SHA-256 fingerprint of the certificate the installed app is signed with.

- Dev builds: the local debug cert. Get it with
  `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
  (line `SHA256:`). It is a public cert, fine to put in the repo variable.
- TODO(owner): release fingerprint. Play Console > your app > Test and release > App integrity > App signing > "App
  signing key certificate" > SHA-256 certificate fingerprint (and the upload key's, if you also sideload upload-signed
  builds). Without it the verified link does not work for store installs; links then open in the browser.
- Put all fingerprints, comma separated, into the repo variable `ANDROID_SHA256_CERT_FINGERPRINTS`
  (Settings > Variables) and redeploy the web (`docs/hosting.md`). The file lists both packages `app.mitlio` and
  `app.mitlio.dev`.
- Check: `adb shell pm get-app-links app.mitlio` shows `mitlio.de: verified`.
- iOS needs nothing per release: the AASA is committed (team `C9B9SUM8W6`); the Associated Domains entitlement
  `applinks:mitlio.de` is in `app/ios/Runner/Runner.entitlements` and needs a paid Apple Developer membership.

## Version and build number

- `app/pubspec.yaml` holds only the version name (`0.2.0`), bumped by release-please on the
  `# x-release-please-version` line. Merging the release PR tags `mitlio-vX.Y.Z` and creates a
  GitHub release.
- The build number is not in the repo. Store builds must pass a strictly increasing one, e.g.
  `flutter build ipa --build-number=${{ github.run_number }}` (Android `versionCode` and iOS
  `CFBundleVersion` both come from it). Local builds without it are fine for development.
