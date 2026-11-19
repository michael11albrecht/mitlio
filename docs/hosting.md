# Hosting (PW-T10)

The SEO site (`web/`, Astro static build) is served by Firebase Hosting, project `mitlio`, site `mitlio` (https://mitlio.web.app). ADR-17: an own domain replaces this later.

## Files

- `web/firebase.json`, `web/.firebaserc`: `public: dist`, clean URLs + trailing slashes (matches Astro `trailingSlash: 'always'`). `firebase.json` is **generated** by `npm run build` (`web/scripts/write-hosting-files.mjs`, builders in `web/scripts/hosting.mjs`) because the CSP `connect-src` includes the `FUEL_API_URL` origin. The committed copy is the default-env output; `web/tests/hosting.spec.ts` fails if it drifts.
- Headers: CSP (`default-src 'self'`, no inline script or style, `frame-ancestors 'none'`), HSTS, `nosniff`, `Referrer-Policy`, `Permissions-Policy` (geolocation only for self), COOP. Hashed `/_astro/**` is `immutable` for 1 year, everything else `max-age=0, must-revalidate`, images 1 day. This is why Astro stylesheets are not inlined (`build.inlineStylesheets: 'never'`) and why the calculator form has no inline `onsubmit`: do not add inline scripts/styles, the browser test in `hosting.spec.ts` will fail.
- `/.well-known/apple-app-site-association` is committed in `web/public/.well-known/` (team `C9B9SUM8W6`, bundle ids `app.mitlio` and `app.mitlio.dev`, path `/join/*` only; `hosting.spec.ts` keeps it equal to the generator output). `/.well-known/assetlinks.json` is written into `dist/` at build time from `ANDROID_SHA256_CERT_FINGERPRINTS` for both packages (`app.mitlio`, `app.mitlio.dev`). While that variable is empty the file is **not** emitted (404 beats a file with placeholder fingerprints that Android would cache). Setting `APPLE_TEAM_ID` also regenerates the AASA over the committed one. A malformed value fails the build. Both are served as `application/json`.
- Invite fallback: `firebase.json` rewrites `/join/**` to the static page `/join/index.html` (`web/src/pages/join.astro`): German, `noindex` (meta and `X-Robots-Tag`), not in the sitemap, **no script**, so the token in the URL is never read, logged, stored or sent. Store buttons appear once `APP_STORE_URL` / `PLAY_STORE_URL` are set.

## Deploys (`.github/workflows/web-deploy.yml`)

- Pull request touching `web/**` or `packages/domain*`: build, then a preview channel (`pr<number>`, 7 days). The action comments the preview URL on the PR.
- Push to `main` with the same paths: live deploy.
- Needs the repo secret `FIREBASE_SERVICE_ACCOUNT` (service account JSON, role Firebase Hosting Admin). Without it, and on fork PRs, the job is skipped.
- Build-time config comes from repo **variables** (Settings > Variables): `SITE_URL`, `FUEL_API_URL`, `FUEL_API_ANON_KEY`, `APP_STORE_URL`, `PLAY_STORE_URL`, `APPLE_TEAM_ID`, `ANDROID_SHA256_CERT_FINGERPRINTS`. All optional.

## Owner to do later

1. Connect `mitlio.de` (owned) in Firebase Hosting (Hosting > Add custom domain, then the DNS records it shows) and set variable `SITE_URL` to `https://mitlio.de`. Invite links and the AASA/assetlinks files only work on that domain. The app side (`applinks:mitlio.de`, intent filter, `siteUrl` default) is already set.
2. The Associated Domains entitlement needs a paid Apple Developer membership on team `C9B9SUM8W6`; without it a device build cannot be signed with the entitlement.
3. Set `ANDROID_SHA256_CERT_FINGERPRINTS` (comma separated): the debug cert for dev builds, and the release / Play App Signing cert (see `docs/release.md`, "Android app links"). Until it is set there is no assetlinks.json and Android opens invite links in the browser.
4. If `FUEL_API_URL` is set, the CSP is extended automatically on the next build.
