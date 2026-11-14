#!/usr/bin/env node
// SEO hygiene gate for the built site (plan section 3, PW-T08). No dependencies.
// Usage: node tool/seo_check.mjs [distDir]   (default: web/dist; run after `npm run build`)
//
// Checks, for every indexable page (no <meta name="robots" content="noindex">):
//  - unique <title> (max 60), unique meta description (max 155), exactly one <h1>, unique <h1>
//  - canonical present and equal to the page's own URL
//  - hreflang only where the alternate page exists, includes self, and links back
//  - JSON-LD parses and has the required fields per type; FAQ questions appear in the visible text
//  - landing pages: 300-600 words of article text, Organization + WebApplication + FAQPage
//  - og:image exists in dist; all internal links resolve; the sitemap lists every indexable page
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const dist = resolve(process.argv[2] ?? join(here, '..', 'web', 'dist'));
const errors = [];
const fail = (page, msg) => errors.push(`${page}: ${msg}`);

if (!existsSync(dist)) {
  console.error(`seo_check: ${dist} does not exist. Run "npm run build" in web/ first.`);
  process.exit(2);
}

const walk = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
const files = walk(dist);
const htmlFiles = files.filter((f) => f.endsWith('.html'));

const decode = (s) =>
  s
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
const attr = (tag, name) => {
  const m = new RegExp(`\\s${name}="([^"]*)"`).exec(tag);
  return m ? decode(m[1]) : undefined;
};
const tags = (html, name) => [...html.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'g'))].map((m) => m[0]);
const textOf = (html) => decode(html.replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();

// ---- load pages ----
const pages = htmlFiles.map((file) => {
  const html = readFileSync(file, 'utf8');
  const rel = file.slice(dist.length).replace(/\\/g, '/');
  const route = rel.endsWith('/index.html') ? rel.slice(0, -'index.html'.length) : rel;
  const metas = tags(html, 'meta');
  const meta = (key, value) => metas.find((t) => attr(t, key) === value);
  return {
    file,
    route,
    html,
    title: /<title>([\s\S]*?)<\/title>/.exec(html)?.[1]?.trim(),
    description: attr(meta('name', 'description') ?? '', 'content'),
    noindex: /noindex/.test(attr(meta('name', 'robots') ?? '', 'content') ?? ''),
    h1s: [...html.matchAll(/<h1\b[^>]*>([\s\S]*?)<\/h1>/g)].map((m) => textOf(m[1])),
    canonical: attr(tags(html, 'link').find((t) => attr(t, 'rel') === 'canonical') ?? '', 'href'),
    alternates: tags(html, 'link')
      .filter((t) => attr(t, 'rel') === 'alternate' && attr(t, 'hreflang'))
      .map((t) => ({ lang: attr(t, 'hreflang'), href: attr(t, 'href') })),
    ogImage: attr(meta('property', 'og:image') ?? '', 'content'),
  };
});
const indexable = pages.filter((p) => !p.noindex && p.route !== '/404.html');

// The origin comes from canonical URLs, so the check works with any SITE_URL.
const origin = indexable.map((p) => p.canonical && new URL(p.canonical).origin).find(Boolean);
if (!origin) {
  console.error('seo_check: no canonical URLs found in the build.');
  process.exit(1);
}

const urlToRoute = (href) => {
  const u = new URL(href, origin);
  return u.origin === origin ? u.pathname : undefined;
};
const routeExists = (pathname) => {
  const base = join(dist, decodeURIComponent(pathname));
  if (pathname.endsWith('/')) return existsSync(join(base, 'index.html'));
  return existsSync(base) && statSync(base).isFile();
};

// ---- per page ----
const seen = { title: new Map(), description: new Map(), h1: new Map() };
const unique = (kind, value, page) => {
  const prev = seen[kind].get(value);
  if (prev) fail(page, `duplicate ${kind} "${value}" (also on ${prev})`);
  else seen[kind].set(value, page);
};

const REQUIRED = {
  Organization: ['name', 'url'],
  WebApplication: ['name', 'url', 'applicationCategory', 'operatingSystem', 'offers'],
  FAQPage: ['mainEntity'],
  HowTo: ['name', 'step'],
};

function checkJsonLd(p, text) {
  const blocks = [...p.html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)];
  const types = [];
  for (const [, raw] of blocks) {
    let data;
    try {
      data = JSON.parse(raw);
    } catch (e) {
      fail(p.route, `JSON-LD does not parse: ${e.message}`);
      continue;
    }
    if (data['@context'] !== 'https://schema.org') fail(p.route, 'JSON-LD without @context https://schema.org');
    const type = data['@type'];
    types.push(type);
    const required = REQUIRED[type];
    if (!required) {
      fail(p.route, `unexpected JSON-LD type "${type}"`);
      continue;
    }
    for (const key of required) {
      const v = data[key];
      if (v === undefined || v === '' || (Array.isArray(v) && v.length === 0)) {
        fail(p.route, `${type} JSON-LD is missing "${key}"`);
      }
    }
    if (type === 'WebApplication' && data.offers?.price === undefined) fail(p.route, 'WebApplication offers.price missing');
    if (type === 'FAQPage') {
      for (const q of data.mainEntity ?? []) {
        if (q['@type'] !== 'Question' || !q.name || q.acceptedAnswer?.['@type'] !== 'Answer' || !q.acceptedAnswer?.text) {
          fail(p.route, `FAQPage has an invalid question: ${JSON.stringify(q).slice(0, 80)}`);
        } else if (!text.includes(q.name)) {
          fail(p.route, `FAQ question "${q.name}" is not visible on the page`);
        }
      }
    }
    if (type === 'HowTo') {
      if ((data.step ?? []).length < 2) fail(p.route, 'HowTo needs at least 2 steps');
      for (const s of data.step ?? []) {
        if (s['@type'] !== 'HowToStep' || !s.name || !s.text) fail(p.route, 'HowTo has an invalid step');
        else if (!text.includes(s.name)) fail(p.route, `HowTo step "${s.name}" is not visible on the page`);
      }
    }
    if (data.url && urlToRoute(data.url) === undefined) fail(p.route, `${type} url is outside ${origin}`);
  }
  return types;
}

for (const p of indexable) {
  if (!p.title) fail(p.route, 'missing <title>');
  else {
    if ([...p.title].length > 60) fail(p.route, `title longer than 60 characters (${[...p.title].length})`);
    unique('title', p.title, p.route);
  }
  if (!p.description) fail(p.route, 'missing meta description');
  else {
    if ([...p.description].length > 155) fail(p.route, `description longer than 155 characters (${[...p.description].length})`);
    unique('description', p.description, p.route);
  }
  if (p.h1s.length !== 1) fail(p.route, `expected exactly one <h1>, found ${p.h1s.length}`);
  else unique('h1', p.h1s[0], p.route);

  const self = new URL(p.route, origin).href;
  if (!p.canonical) fail(p.route, 'missing canonical');
  else if (p.canonical !== self) fail(p.route, `canonical ${p.canonical} is not the page URL ${self}`);

  // hreflang: only with a real alternate; self + x-default allowed; each target exists and links back.
  if (p.alternates.length > 0) {
    if (!p.alternates.some((a) => a.href === self)) fail(p.route, 'hreflang set does not include the page itself');
    for (const a of p.alternates) {
      const route = urlToRoute(a.href);
      const target = pages.find((o) => o.route === route);
      if (!target) {
        fail(p.route, `hreflang ${a.lang} points to a page that does not exist: ${a.href}`);
        continue;
      }
      if (!target.alternates.some((b) => b.href === self)) fail(p.route, `hreflang target ${a.href} does not link back`);
    }
    // Reciprocal means the whole set is shared: the pair partner lists exactly the same hreflang entries.
    const key = (alts) => alts.map((a) => `${a.lang}=${a.href}`).sort().join(' ');
    for (const a of p.alternates) {
      const target = pages.find((o) => o.route === urlToRoute(a.href));
      if (target && key(target.alternates) !== key(p.alternates)) {
        fail(p.route, `hreflang set differs from the one on ${a.href}`);
      }
    }
    // x-default is the German page; each hreflang language matches the <html lang> of its target.
    const xDefault = p.alternates.find((a) => a.lang === 'x-default');
    if (!xDefault) fail(p.route, 'hreflang set without x-default');
    else if (!p.alternates.some((a) => a.lang === 'de-DE' && a.href === xDefault.href)) {
      fail(p.route, 'x-default must point to the German page');
    }
    for (const a of p.alternates.filter((x) => x.lang !== 'x-default')) {
      const target = pages.find((o) => o.route === urlToRoute(a.href));
      const htmlLang = /<html[^>]*\slang="([^"]*)"/.exec(target?.html ?? '')?.[1];
      if (target && htmlLang !== a.lang) fail(p.route, `hreflang ${a.lang} targets a page with <html lang="${htmlLang}">`);
    }
    if (p.alternates.filter((a) => a.lang !== 'x-default').length < 2) {
      fail(p.route, 'hreflang present but no alternate language exists (drop it)');
    }
  }

  // og image
  if (!p.ogImage) fail(p.route, 'missing og:image');
  else {
    const route = urlToRoute(p.ogImage);
    if (route === undefined || !routeExists(route)) fail(p.route, `og:image does not exist in the build: ${p.ogImage}`);
  }

  const article = /<article\b[\s\S]*?<\/article>/.exec(p.html)?.[0];
  const text = textOf(p.html);
  const types = checkJsonLd(p, text);
  if (article) {
    const words = textOf(article).split(' ').length;
    if (words < 300 || words > 600) fail(p.route, `article has ${words} words, expected 300-600`);
    for (const t of ['Organization', 'WebApplication', 'FAQPage']) {
      if (!types.includes(t)) fail(p.route, `landing page without ${t} JSON-LD`);
    }
    const nFaq = (article.match(/<h3\b/g) ?? []).length;
    if (nFaq < 4 || nFaq > 6) fail(p.route, `FAQ has ${nFaq} questions, expected 4-6`);
    if (!/id="calculator"/.test(p.html)) fail(p.route, 'landing page without the calculator');
  }
}

// ---- internal links (all pages, including noindex and 404) ----
for (const p of pages) {
  for (const tag of tags(p.html, 'a')) {
    const href = attr(tag, 'href');
    if (!href || href.startsWith('#')) continue;
    // External schemes (https:, mailto:, mitlio:, ...) are not ours to check.
    if (/^[a-z][a-z0-9+.-]*:/i.test(href) && !href.startsWith(origin)) continue;
    const pathname = urlToRoute(href);
    if (pathname === undefined) continue;
    if (!routeExists(pathname)) fail(p.route, `broken internal link ${href}`);
    else if (href.includes('#')) {
      const id = href.split('#')[1];
      const target = pages.find((o) => o.route === pathname);
      if (id && target && !target.html.includes(`id="${id}"`)) fail(p.route, `link to missing anchor ${href}`);
    }
  }
}

// ---- sitemap ----
const sitemapFiles = files.filter((f) => /sitemap-\d+\.xml$/.test(f));
if (sitemapFiles.length === 0) fail('sitemap', 'no sitemap-N.xml in the build');
const sitemapUrls = new Set(
  sitemapFiles.flatMap((f) => [...readFileSync(f, 'utf8').matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1])),
);
for (const p of indexable) {
  const self = new URL(p.route, origin).href;
  if (!sitemapUrls.has(self)) fail(p.route, 'missing from the sitemap');
}
for (const p of pages.filter((q) => q.noindex)) {
  if (sitemapUrls.has(new URL(p.route, origin).href)) fail(p.route, 'noindex page is in the sitemap');
}
for (const url of sitemapUrls) {
  const route = urlToRoute(url);
  if (route === undefined || !routeExists(route)) fail('sitemap', `lists a page that does not exist: ${url}`);
}

if (errors.length > 0) {
  console.error(`seo_check: ${errors.length} problem(s)\n${errors.map((e) => `  - ${e}`).join('\n')}`);
  process.exit(1);
}
console.log(`seo_check: OK (${indexable.length} indexable pages, ${sitemapUrls.size} sitemap URLs)`);
