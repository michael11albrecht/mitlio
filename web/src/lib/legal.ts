// Release gate for the legal texts (src/i18n/legal.ts): a production build must not ship `[[PLACEHOLDER]]`s.
import type { LegalText } from '../i18n/legal';

/** The stand-in origin used until the real domain exists (see site.config.mjs). */
export const STAND_IN_ORIGIN = 'https://mitlio.web.app';

/** Every `[[...]]` placeholder left in the text, in order, without duplicates. */
export function findPlaceholders(text: LegalText): string[] {
  const all = text.sections.flatMap((s) => [s.heading, ...(s.paragraphs ?? []), ...(s.items ?? [])]);
  const found = all.flatMap((line) => line.match(/\[\[[^\]]+\]\]/g) ?? []);
  return [...new Set(found)];
}

/**
 * A production site is any origin other than the stand-in and local hosts, or any build with
 * LEGAL_STRICT=1 (for example a release build that keeps the stand-in origin).
 */
export function isProductionSite(siteUrl: string, strict = false): boolean {
  if (strict) return true;
  const { origin, hostname } = new URL(siteUrl);
  if (origin === STAND_IN_ORIGIN) return false;
  return !['localhost', '127.0.0.1', '[::1]'].includes(hostname);
}

/** Throws (failing the build) when a production site would publish placeholders. */
export function assertNoPlaceholders(text: LegalText, siteUrl: string, strict = false): void {
  const left = findPlaceholders(text);
  if (left.length > 0 && isProductionSite(siteUrl, strict)) {
    throw new Error(
      `Legal text still has placeholders (${left.join(', ')}) and SITE_URL is ${siteUrl}. ` +
        'Fill them in src/i18n/legal.ts (see docs/release.md, "Legal texts").',
    );
  }
}
