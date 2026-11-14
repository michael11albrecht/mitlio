# mitlio web

Astro static SEO site (de default at `/`, en at `/en/`). Plan: `docs/IMPLEMENTATION_PLAN.md` PW rows.

- `make web-install` / `make web-build` / `make web-check` from the repo root.
- `SITE_URL` env var sets the public origin (default in `site.config.mjs`, currently `https://mitlio.web.app`).
- `npm run prebuild` (runs before `npm run build`) rebuilds `build/domain_web/mitlio_domain.js` via
  `tool/build_domain_web.sh` when `dart` is available, else reuses an existing build, and copies it to
  `public/mitlio_domain.js` (gitignored); the calculator island (`src/calculator/`) loads it.
- `npm test` runs Playwright (chromium) + axe against `dist/` via `astro preview` (build first; `npx playwright install chromium` once). Calculator URL params: `km, l100, p, n, d, rt, x, ev`.
- `npm run lhci` runs Lighthouse CI against `dist/` (needs Chrome; set `CHROME_PATH` if not found).
- `src/styles/tokens.css` holds placeholder design tokens (TODO P3-T05: mirror the app theme).
- Legal pages (`/impressum/`, `/datenschutz/`) are `noindex` placeholders: the owner supplies the text.
