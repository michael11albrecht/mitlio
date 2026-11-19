// Pure builders for the Firebase Hosting config and the app-link files (PW-T10). No I/O here so the
// Playwright tests can import them; scripts/write-hosting-files.mjs writes the results.

// App ids come from app/app_identity.yaml (tests/hosting.spec.ts keeps them in sync).
export const IOS_APP_IDS = ['app.mitlio', 'app.mitlio.dev'];
// Both flavors. The dev flavor is signed with the debug key: it verifies only while the debug cert is in
// ANDROID_SHA256_CERT_FINGERPRINTS (docs/release.md).
export const ANDROID_PACKAGES = ['app.mitlio', 'app.mitlio.dev'];
// Invite links, see docs/deeplink.md. The site itself is only the fallback page.
export const LINK_PATH = '/join/*';

const TEAM_ID = /^[A-Z0-9]{10}$/;
const FINGERPRINT = /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/;

/** The CSP: no inline script, no inline style, no third-party origin except the optional fuel API. */
export function contentSecurityPolicy(fuelApiUrl = '') {
  const connect = ["'self'"];
  if (fuelApiUrl) connect.push(new URL(fuelApiUrl).origin);
  return [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self' data:",
    "font-src 'self'",
    `connect-src ${connect.join(' ')}`,
    "manifest-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    'upgrade-insecure-requests',
  ].join('; ');
}

const h = (key, value) => ({ key, value });

/** firebase.json. `public` is relative to web/ (the file lives next to package.json). */
export function firebaseConfig(fuelApiUrl = '') {
  return {
    hosting: {
      public: 'dist',
      cleanUrls: true,
      trailingSlash: true,
      // Firebase ignores dotfiles by default, which would drop /.well-known: override the default list.
      ignore: ['firebase.json', '**/node_modules/**'],
      // Invite links https://<domain>/join/<token>: every token path is the same static fallback page (no script
      // reads the token, see src/pages/join.astro).
      rewrites: [{ source: '/join/**', destination: '/join/index.html' }],
      // Firebase applies every matching rule; for a repeated key the LAST rule wins. Order: general, then specific.
      headers: [
        {
          source: '**',
          headers: [
            h('Content-Security-Policy', contentSecurityPolicy(fuelApiUrl)),
            h('Strict-Transport-Security', 'max-age=31536000; includeSubDomains'),
            h('X-Content-Type-Options', 'nosniff'),
            h('Referrer-Policy', 'strict-origin-when-cross-origin'),
            // Geolocation is only used by the opt-in "in meiner Nähe" fuel chip.
            h('Permissions-Policy', 'geolocation=(self), camera=(), microphone=(), payment=(), usb=(), interest-cohort=()'),
            h('Cross-Origin-Opener-Policy', 'same-origin'),
            h('Cache-Control', 'public, max-age=0, must-revalidate'),
          ],
        },
        { source: '**/*.@(png|svg|ico)', headers: [h('Cache-Control', 'public, max-age=86400')] },
        // Content-hashed by Astro: safe to cache forever.
        { source: '/_astro/**', headers: [h('Cache-Control', 'public, max-age=31536000, immutable')] },
        { source: '/join/**', headers: [h('X-Robots-Tag', 'noindex')] },
        {
          // apple-app-site-association has no extension, so the type must be set explicitly (iOS requires JSON).
          source: '/.well-known/**',
          headers: [h('Content-Type', 'application/json'), h('Cache-Control', 'public, max-age=3600')],
        },
      ],
    },
  };
}

/** Returns { 'apple-app-site-association'?: object, 'assetlinks.json'?: object }; a file is omitted when its input is empty. */
export function wellKnownFiles(teamId = '', fingerprints = '') {
  const files = {};
  if (teamId) {
    if (!TEAM_ID.test(teamId)) throw new Error(`APPLE_TEAM_ID must be 10 characters A-Z/0-9, got "${teamId}"`);
    files['apple-app-site-association'] = {
      applinks: {
        details: [{ appIDs: IOS_APP_IDS.map((id) => `${teamId}.${id}`), components: [{ '/': LINK_PATH }] }],
      },
    };
  }
  const prints = fingerprints
    .split(',')
    .map((f) => f.trim().toUpperCase())
    .filter(Boolean);
  if (prints.length > 0) {
    for (const p of prints) {
      if (!FINGERPRINT.test(p)) throw new Error(`ANDROID_SHA256_CERT_FINGERPRINTS: "${p}" is not a SHA-256 fingerprint (AA:BB:..)`);
    }
    files['assetlinks.json'] = ANDROID_PACKAGES.map((packageName) => ({
      relation: ['delegate_permission/common.handle_all_urls'],
      target: { namespace: 'android_app', package_name: packageName, sha256_cert_fingerprints: prints },
    }));
  }
  return files;
}
