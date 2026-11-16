# Hosting (PW-T10)

The SEO site (`web/`, Astro static build) is served by Firebase Hosting, project `mitlio`, site `mitlio` (https://mitlio.web.app). ADR-17: an own domain replaces this later.

## Files

- `web/firebase.json`, `web/.firebaserc`: `public: dist`, clean URLs + trailing slashes (matches Astro `trailingSlash: 'always'`). `firebase.json` is **generated** by `npm run build` (`web/scripts/write-hosting-files.mjs`, builders in `web/scripts/hosting.mjs`) because the CSP `connect-src` includes the `FUEL_API_URL` origin. The committed copy is the default-env output; `web/tests/hosting.spec.ts` fails if it drifts.
- Headers: CSP (`default-src 'self'`, no inline script or style, `frame-ancestors 'none'`), HSTS, `nosniff`, `Referrer-Policy`, `Permissions-Policy` (geolocation only for self), COOP. Hashed `/_astro/**` is `immutable` for 1 year, everything else `max-age=0, must-revalidate`, images 1 day. This is why Astro stylesheets are not inlined (`build.inlineStylesheets: 'never'`) and why the calculator form has no inline `onsubmit`: do not add inline scripts/styles, the browser test in `hosting.spec.ts` will fail.
- `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json` are written into `dist/` at build time from `APPLE_TEAM_ID` and `ANDROID_SHA256_CERT_FINGERPRINTS`. While a value is empty the file is **not** emitted (404 beats a file with placeholder ids that apps would cache). A malformed value fails the build. Both are served as `application/json`. Link path: `/join/*`; ids from `app/app_identity.yaml` (iOS: prod + dev, Android: prod only).

## Deploys (`.github/workflows/web-deploy.yml`)

- Pull request touching `web/**` or `packages/domain*`: build, then a preview channel (`pr<number>`, 7 days). The action comments the preview URL on the PR.
- Push to `main` with the same paths: live deploy.
- Needs the repo secret `FIREBASE_SERVICE_ACCOUNT` (service account JSON, role Firebase Hosting Admin). Without it, and on fork PRs, the job is skipped.
- Build-time config comes from repo **variables** (Settings > Variables): `SITE_URL`, `FUEL_API_URL`, `FUEL_API_ANON_KEY`, `APP_STORE_URL`, `PLAY_STORE_URL`, `APPLE_TEAM_ID`, `ANDROID_SHA256_CERT_FINGERPRINTS`. All optional.

## Owner to do later

1. Buy the domain, connect it in Firebase Hosting, set variable `SITE_URL` (and `link_domain` in `app/app_identity.yaml`).
2. Set `APPLE_TEAM_ID` once the Apple Developer account exists, and add the Associated Domains entitlement `applinks:<domain>`.
3. Set `ANDROID_SHA256_CERT_FINGERPRINTS` (comma separated; release key and Play App Signing key) once the app is signed.
4. If `FUEL_API_URL` is set, the CSP is extended automatically on the next build.
