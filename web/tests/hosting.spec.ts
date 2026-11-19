import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

import { expect, test } from '@playwright/test';

import { FUEL_API_URL } from '../site.config.mjs';
// @ts-expect-error plain .mjs helper without types
import { contentSecurityPolicy, firebaseConfig, wellKnownFiles } from '../scripts/hosting.mjs';

// PW-T10: hosting config. Reads firebase.json and the real build output (dist/, run `npm run build` first).
const web = resolve(import.meta.dirname, '..');
const dist = join(web, process.env['ASTRO_OUT_DIR'] ?? 'dist');

interface Rule {
  source: string;
  headers: { key: string; value: string }[];
}
const firebase = JSON.parse(readFileSync(join(web, 'firebase.json'), 'utf8')) as {
  hosting: { public: string; cleanUrls: boolean; trailingSlash: boolean; headers: Rule[] };
};
const rule = (source: string) => firebase.hosting.headers.find((r) => r.source === source);
const header = (source: string, key: string) => rule(source)?.headers.find((x) => x.key === key)?.value;

function htmlFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    return statSync(p).isDirectory() ? htmlFiles(p) : p.endsWith('.html') ? [p] : [];
  });
}

const fingerprint = Array.from({ length: 32 }, (_, i) => (i * 7 + 10).toString(16).toUpperCase().padStart(2, '0').slice(-2)).join(':');

test.describe('firebase.json', () => {
  test('serves web/dist with clean urls and trailing slashes like astro (trailingSlash: always)', () => {
    expect(firebase.hosting.public).toBe('dist');
    expect(firebase.hosting.cleanUrls).toBe(true);
    expect(firebase.hosting.trailingSlash).toBe(true);
  });

  test('committed file is what the generator produces for the default env', () => {
    test.skip(FUEL_API_URL !== '', 'firebase.json was generated with a FUEL_API_URL');
    expect(firebase).toEqual(firebaseConfig(''));
  });

  test('security headers on every path', () => {
    const csp = header('**', 'Content-Security-Policy') ?? '';
    for (const d of ["default-src 'self'", "script-src 'self'", "style-src 'self'", "frame-ancestors 'none'", "object-src 'none'", "base-uri 'self'"]) {
      expect(csp).toContain(d);
    }
    expect(csp).not.toContain('unsafe-inline');
    expect(csp).not.toContain('unsafe-eval');
    expect(header('**', 'Strict-Transport-Security')).toMatch(/max-age=31536000/);
    expect(header('**', 'X-Content-Type-Options')).toBe('nosniff');
    expect(header('**', 'Referrer-Policy')).toBe('strict-origin-when-cross-origin');
    expect(header('**', 'Permissions-Policy')).toContain('geolocation=(self)');
  });

  test('CSP allows exactly the fuel API origin for connect-src when configured', () => {
    expect(contentSecurityPolicy('')).toContain("connect-src 'self';");
    expect(contentSecurityPolicy('https://abc.supabase.co/functions/v1/fuel-prices')).toContain(
      "connect-src 'self' https://abc.supabase.co;",
    );
    expect(header('**', 'Content-Security-Policy')).toBe(contentSecurityPolicy(FUEL_API_URL));
  });

  test('cache headers: hashed assets immutable, html revalidated', () => {
    expect(header('/_astro/**', 'Cache-Control')).toBe('public, max-age=31536000, immutable');
    expect(header('**', 'Cache-Control')).toBe('public, max-age=0, must-revalidate');
    // Specific rules must come after the general one (last rule wins per key).
    const sources = firebase.hosting.headers.map((r) => r.source);
    expect(sources.indexOf('/_astro/**')).toBeGreaterThan(sources.indexOf('**'));
  });

  test('/.well-known is served as application/json (apple-app-site-association has no extension)', () => {
    expect(header('/.well-known/**', 'Content-Type')).toBe('application/json');
  });
});

test.describe('CSP fits the build output', () => {
  test('no inline scripts, styles, style attributes or event handlers; only same-origin assets', () => {
    const files = htmlFiles(dist);
    expect(files.length).toBeGreaterThan(10);
    for (const f of files) {
      const html = readFileSync(f, 'utf8');
      const scripts = [...html.matchAll(/<script\b([^>]*)>/g)].map((m) => m[1] ?? '');
      for (const attrs of scripts) {
        const external = /\ssrc="\//.test(` ${attrs}`);
        const data = /type="application\/ld\+json"/.test(attrs); // data block, not executed
        expect(external || data, `${f}: inline script <script ${attrs}>`).toBe(true);
      }
      expect(html, `${f}: <style>`).not.toMatch(/<style[\s>]/);
      expect(html, `${f}: style attribute`).not.toMatch(/\sstyle=/);
      expect(html, `${f}: inline event handler`).not.toMatch(/\son[a-z]+="/);
      expect(html, `${f}: javascript: url`).not.toMatch(/javascript:/i);
      for (const m of html.matchAll(/<link\b[^>]*rel="(?:stylesheet|icon|preload|modulepreload)"[^>]*>/g)) {
        expect(m[0], `${f}: cross-origin asset`).not.toMatch(/href="(?:https?:)?\/\//);
      }
    }
  });

  test('browser: calculator runs with the production CSP applied and reports no violation', async ({ page }) => {
    const csp = header('**', 'Content-Security-Policy') ?? '';
    const messages: string[] = [];
    page.on('console', (m) => {
      if (/Content Security Policy|Refused to/i.test(m.text())) messages.push(m.text());
    });
    await page.route('**/*', async (route) => {
      const response = await route.fetch();
      await route.fulfill({ response, headers: { ...response.headers(), 'content-security-policy': csp } });
    });
    await page.goto('/');
    await expect(page.locator('#calculator')).toHaveAttribute('data-ready', 'true');
    await page.locator('#calc-km').fill('250');
    await expect(page.locator('#calc-result-amount')).toHaveText(/€/);
    expect(messages).toEqual([]);
  });
});

test.describe('/.well-known', () => {
  const identity = readFileSync(resolve(web, '..', 'app', 'app_identity.yaml'), 'utf8');
  const prod = /bundle_id: (app\.mitlio)\s*$/m.exec(identity)?.[1];
  const dev = /bundle_id: (app\.mitlio\.dev)\s*$/m.exec(identity)?.[1];

  test('emits nothing while the ids are not configured', () => {
    expect(wellKnownFiles('', '')).toEqual({});
  });

  test('apple-app-site-association uses the app ids and the /join/ path', () => {
    const files = wellKnownFiles('ABCDE12345', '');
    expect(Object.keys(files)).toEqual(['apple-app-site-association']);
    const detail = files['apple-app-site-association'].applinks.details[0];
    expect(detail.appIDs).toEqual([`ABCDE12345.${prod}`, `ABCDE12345.${dev}`]);
    expect(detail.components).toEqual([{ '/': '/join/*' }]);
  });

  test('assetlinks.json lists both flavors with the fingerprints', () => {
    const files = wellKnownFiles('', `${fingerprint.toLowerCase()}, ${fingerprint}`);
    expect(Object.keys(files)).toEqual(['assetlinks.json']);
    const entries = files['assetlinks.json'];
    expect(entries).toHaveLength(2);
    for (const [i, pkg] of [prod, dev].entries()) {
      expect(entries[i].relation).toEqual(['delegate_permission/common.handle_all_urls']);
      expect(entries[i].target).toEqual({
        namespace: 'android_app',
        package_name: pkg,
        sha256_cert_fingerprints: [fingerprint, fingerprint],
      });
    }
    expect(() => JSON.parse(JSON.stringify(files['assetlinks.json']))).not.toThrow();
  });

  test('the committed apple-app-site-association is valid JSON for both bundle ids, /join/* only', () => {
    const file = join(web, 'public', '.well-known', 'apple-app-site-association');
    const json = JSON.parse(readFileSync(file, 'utf8')) as {
      applinks: { details: { appIDs: string[]; components: Record<string, string>[] }[] };
    };
    expect(json.applinks.details).toHaveLength(1);
    expect(json.applinks.details[0].appIDs).toEqual([`C9B9SUM8W6.${prod}`, `C9B9SUM8W6.${dev}`]);
    expect(json.applinks.details[0].components).toEqual([{ '/': '/join/*' }]);
    // The build copies it as is, so the served file is the committed one.
    expect(JSON.parse(readFileSync(join(dist, '.well-known', 'apple-app-site-association'), 'utf8'))).toEqual(json);
  });

  test('the generated apple-app-site-association for the same team equals the committed one', () => {
    const committed = JSON.parse(
      readFileSync(join(web, 'public', '.well-known', 'apple-app-site-association'), 'utf8'),
    );
    expect(wellKnownFiles('C9B9SUM8W6', '')['apple-app-site-association']).toEqual(committed);
  });

  test('malformed values fail the build instead of shipping a broken file', () => {
    expect(() => wellKnownFiles('short', '')).toThrow(/APPLE_TEAM_ID/);
    expect(() => wellKnownFiles('', 'AA:BB')).toThrow(/ANDROID_SHA256_CERT_FINGERPRINTS/);
  });
});

test.describe('/join/<token> fallback (P6-T14c)', () => {
  const html = () => readFileSync(join(dist, 'join', 'index.html'), 'utf8');

  test('firebase rewrites every /join/** path to the static fallback page', () => {
    const rewrites = (firebase.hosting as unknown as { rewrites: { source: string; destination: string }[] }).rewrites;
    expect(rewrites).toEqual([{ source: '/join/**', destination: '/join/index.html' }]);
  });

  test('the join paths are noindex for crawlers (header and meta)', () => {
    expect(header('/join/**', 'X-Robots-Tag')).toBe('noindex');
    expect(html()).toMatch(/<meta name="robots" content="noindex"/);
  });

  test('says what to do, in du-form German', () => {
    expect(html()).toContain('Öffne den Link auf deinem Handy mit mitlio');
    expect(html()).toContain('<html lang="de-DE"');
  });

  test('no script at all, so nothing can read, log, store or send the token', () => {
    expect(html()).not.toMatch(/<script\b/i);
    expect(html()).not.toMatch(/\son[a-z]+="/);
  });

  test('is not in the sitemap', () => {
    expect(readFileSync(join(dist, 'sitemap-0.xml'), 'utf8')).not.toContain('/join/');
  });

  test('browser: the page renders and makes no request carrying a token', async ({ page }) => {
    // Firebase does the rewrite in production; astro preview serves the same file at /join/.
    const requests: string[] = [];
    page.on('request', (r) => requests.push(r.url()));
    await page.goto('/join/');
    await expect(page.locator('h1')).toHaveText('Öffne den Link auf deinem Handy mit mitlio');
    expect(requests.filter((u) => /\/join\/./.test(u))).toEqual([]);
  });
});
