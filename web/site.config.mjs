// Single source of truth for the public origin. The domain is not bought yet:
// override with the SITE_URL env var at build time (empty counts as unset), or change the default here.
export const SITE_URL = process.env.SITE_URL || 'https://mitlio.web.app';

// Store listings. Empty until the app is published (owner decision): the calculator then shows
// "App kommt bald". Once set, store badges, an "open in app" deep link and the
// <meta name="apple-itunes-app"> smart banner are rendered automatically.
// APP_STORE_URL must contain the numeric id, e.g. https://apps.apple.com/app/mitlio/id1234567890.
export const APP_STORE_URL = process.env.APP_STORE_URL ?? '';
export const PLAY_STORE_URL = process.env.PLAY_STORE_URL ?? '';

// Live fuel prices (PW-T04). FUEL_API_URL is the full endpoint of the `fuel-prices` Edge Function, e.g.
// https://<project>.supabase.co/functions/v1/fuel-prices. Empty until hosting exists: the chips are then
// not rendered at all and the page makes no network request. FUEL_API_ANON_KEY is the public anon key
// (shipped to browsers on purpose, see docs/fuel-prices-api.md); optional.
export const FUEL_API_URL = process.env.FUEL_API_URL ?? '';
export const FUEL_API_ANON_KEY = process.env.FUEL_API_ANON_KEY ?? '';

// Contact form (Impressum). Same Supabase project as the fuel chips: the `contact` Edge Function lives next to
// `fuel-prices`, so endpoint, CSP origin and anon key all derive from FUEL_API_URL. Empty when FUEL_API_URL is
// empty: the contact page then shows the e-mail address instead of the form and makes no network request.
export const CONTACT_API_URL = FUEL_API_URL ? new URL('contact', FUEL_API_URL).href : '';

// App links (PW-T10). Needed for /.well-known/apple-app-site-association and /.well-known/assetlinks.json, which are
// generated at build time (scripts/write-hosting-files.mjs). Both stay empty until the apps are signed (owner decision):
// an empty value means the matching file is NOT emitted (a 404 is honest, a file with placeholder ids would make
// iOS/Android cache a broken association). APPLE_TEAM_ID is the 10-character Apple Developer Team ID.
// ANDROID_SHA256_CERT_FINGERPRINTS is a comma-separated list of the release signing cert SHA-256 fingerprints
// (AA:BB:...:FF, 32 bytes), including the Play App Signing key once the app is on Play.
export const APPLE_TEAM_ID = process.env.APPLE_TEAM_ID ?? '';
export const ANDROID_SHA256_CERT_FINGERPRINTS = process.env.ANDROID_SHA256_CERT_FINGERPRINTS ?? '';

// From-to route field (PW-T12, issue #207). OFF by default: set ROUTE_WEB=1 at build time to render the collapsed
// "Start und Ziel" row. It talks to the `route-distance` Edge Function next to `fuel-prices` (same Supabase origin, so
// the CSP connect-src needs no change) and sends typed addresses to openrouteservice. The Datenschutz section that
// names it (src/i18n/legal.ts, routePrivacy) is rendered by the same flag and still carries an [[ENTWURF ...]]
// placeholder that fails a production build until the owner has signed off the wording.
export const ROUTE_WEB = process.env.ROUTE_WEB === '1';
export const ROUTE_API_URL = ROUTE_WEB && FUEL_API_URL ? new URL('route-distance', FUEL_API_URL).href : '';

// Support the developer (P7-T09, ADR-28). PayPal.Me handle of the footer link (e.g. "michaelalbrecht"). Empty means no
// link and nothing else changes: this is the web's off switch, the counterpart of the app's remote flag
// `support_tips_enabled`. The static site has no runtime flag, so the owner sets it at build time, and only after the
// tax clarification (plan section 12, 13c).
export const SUPPORT_PAYPAL_ME = process.env.SUPPORT_PAYPAL_ME ?? '';
