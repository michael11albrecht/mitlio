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

// App links (PW-T10). Needed for /.well-known/apple-app-site-association and /.well-known/assetlinks.json, which are
// generated at build time (scripts/write-hosting-files.mjs). Both stay empty until the apps are signed (owner decision):
// an empty value means the matching file is NOT emitted (a 404 is honest, a file with placeholder ids would make
// iOS/Android cache a broken association). APPLE_TEAM_ID is the 10-character Apple Developer Team ID.
// ANDROID_SHA256_CERT_FINGERPRINTS is a comma-separated list of the release signing cert SHA-256 fingerprints
// (AA:BB:...:FF, 32 bytes), including the Play App Signing key once the app is on Play.
export const APPLE_TEAM_ID = process.env.APPLE_TEAM_ID ?? '';
export const ANDROID_SHA256_CERT_FINGERPRINTS = process.env.ANDROID_SHA256_CERT_FINGERPRINTS ?? '';
