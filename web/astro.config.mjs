import sitemap from '@astrojs/sitemap';
import { defineConfig } from 'astro/config';

import { SITE_URL } from './site.config.mjs';

export default defineConfig({
  site: SITE_URL,
  output: 'static',
  // Playwright serves a second build with a fake FUEL_API_URL from its own folder (scripts/serve-fuel-fixture.mjs).
  outDir: process.env.ASTRO_OUT_DIR ?? './dist',
  trailingSlash: 'always',
  build: { format: 'directory' },
  i18n: {
    defaultLocale: 'de',
    locales: ['de', 'en'],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({
      // Legal placeholder pages stay noindex (and out of the sitemap) until the owner supplies the text.
      filter: (page) => !/\/(impressum|datenschutz|imprint|privacy)\/$/.test(page),
      i18n: { defaultLocale: 'de', locales: { de: 'de-DE', en: 'en' } },
    }),
  ],
});
