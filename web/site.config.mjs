// Single source of truth for the public origin. The domain is not bought yet:
// override with the SITE_URL env var at build time, or change the default here.
export const SITE_URL = process.env.SITE_URL ?? 'https://mitlio.web.app';

// Store listings. Empty until the app is published (owner decision): the calculator then shows
// "App kommt bald". Once set, store badges, an "open in app" deep link and the
// <meta name="apple-itunes-app"> smart banner are rendered automatically.
// APP_STORE_URL must contain the numeric id, e.g. https://apps.apple.com/app/mitlio/id1234567890.
export const APP_STORE_URL = process.env.APP_STORE_URL ?? '';
export const PLAY_STORE_URL = process.env.PLAY_STORE_URL ?? '';
