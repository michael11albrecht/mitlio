// Build-time Open Graph / Twitter card (1200x630 PNG): branded SVG with the page title as text,
// rasterised by sharp (already installed by astro for image optimisation). No runtime dependency.
import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';
import sharp from 'sharp';

import { messages } from '../../i18n';

const WIDTH = 1200;
const HEIGHT = 630;
const MAX_LINE = 22;

export const getStaticPaths = (async () => {
  const pages = await getCollection('landing');
  return [
    { params: { slug: 'home' }, props: { title: messages.de.heroTitle } },
    ...pages.map((e) => ({ params: { slug: e.id }, props: { title: e.data.h1 } })),
  ];
}) satisfies GetStaticPaths;

const escapeXml = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** Greedy word wrap at MAX_LINE characters; titles are short so three lines are plenty. */
function wrap(title: string): string[] {
  const lines: string[] = [];
  for (const word of title.split(/\s+/)) {
    const last = lines[lines.length - 1];
    if (last !== undefined && `${last} ${word}`.length <= MAX_LINE) lines[lines.length - 1] = `${last} ${word}`;
    else lines.push(word);
  }
  return lines.slice(0, 3);
}

function ogSvg(title: string): string {
  const lines = wrap(title);
  const first = 300 - ((lines.length - 1) * 84) / 2;
  const text = lines
    .map((l, i) => `<tspan x="80" y="${first + i * 84}">${escapeXml(l)}</tspan>`)
    .join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <rect width="${WIDTH}" height="${HEIGHT}" fill="#0f766e"/>
  <text x="80" y="110" font-family="Helvetica, Arial, DejaVu Sans, sans-serif" font-size="44" font-weight="700" fill="#ffffff">mitlio</text>
  <text font-family="Helvetica, Arial, DejaVu Sans, sans-serif" font-size="72" font-weight="700" fill="#ffffff">${text}</text>
  <text x="80" y="560" font-family="Helvetica, Arial, DejaVu Sans, sans-serif" font-size="34" fill="#ccfbf1">Kostenlos, ohne Anmeldung, ohne Werbung</text>
</svg>`;
}

export const GET: APIRoute = async ({ props }) => {
  const png = await sharp(Buffer.from(ogSvg((props as { title: string }).title))).png().toBuffer();
  return new Response(new Uint8Array(png), { headers: { 'Content-Type': 'image/png' } });
};
