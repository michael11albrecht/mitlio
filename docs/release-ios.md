# iOS release (TestFlight / App Store)

Pipeline: `.github/workflows/ios-testflight.yml` -> `app/ios/fastlane` (match signing, `flutter build ipa`, upload).
Bundle ids come from `app/app_identity.yaml`: `app.mitlio` (prod), `app.mitlio.dev` (dev). Fixed forever after the first upload.

## One-time owner setup

1. App Store Connect: create the app (name `mitlio`, bundle id `app.mitlio`, SKU any). Repeat for `app.mitlio.dev` if you want dev builds in TestFlight.
2. Developer portal: register App IDs `app.mitlio` and `app.mitlio.dev`.
3. App Store Connect -> Users and Access -> Integrations -> Keys: create an API key (role App Manager). Keep the `.p8`, Key ID, Issuer ID.
4. Create an empty **private** git repo for match (`mitlio-certs`) and add an SSH deploy key with write access (no personal token needed).
5. GitHub -> Settings -> Environments -> new environment `ios-release` with secrets:
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (full file contents), `MATCH_GIT_URL` (ssh url), `MATCH_GIT_PRIVATE_KEY` (deploy key, private half), `MATCH_PASSWORD` (passphrase that encrypts the certs).
6. Actions -> ios-testflight -> Run workflow, flavor `prod`, **create_signing = true** (first run only). Later runs use readonly match.

## Notes

- Build number = latest TestFlight build + 1. Version name comes from `pubspec.yaml`.
- Nightly run skips when `main` has not changed since the last successful run.
- `ITSAppUsesNonExemptEncryption=false` in Info.plist answers export compliance (standard encryption only).
- Public release also needs: privacy policy + imprint URL, App Privacy answers (no tracking), screenshots, description, age rating.
