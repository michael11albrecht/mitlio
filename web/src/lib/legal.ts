// Release gate for the legal texts (src/i18n/legal.ts): a production build must not ship `[[PLACEHOLDER]]`s.
import type { LegalSection, LegalText } from '../i18n/legal';

/** The stand-in origin used until the real domain exists (see site.config.mjs). */
export const STAND_IN_ORIGIN = 'https://mitlio.web.app';

const ADDRESS_PLACEHOLDERS = [
  ['[[STRASSE HAUSNUMMER]]', 'LEGAL_STREET'],
  ['[[PLZ ORT]]', 'LEGAL_CITY'],
] as const;

/**
 * Replaces the address placeholders with the build env vars LEGAL_STREET and LEGAL_CITY. A missing or blank
 * variable keeps its placeholder, so `assertNoPlaceholders` still fails a production build. The address is
 * never stored in the repository (it is public).
 */
export function fillAddress(text: LegalText, env: Record<string, string | undefined>): LegalText {
  const fill = (line: string): string =>
    ADDRESS_PLACEHOLDERS.reduce((acc, [placeholder, name]) => {
      const value = env[name]?.trim();
      return value ? acc.replaceAll(placeholder, value) : acc;
    }, line);
  return {
    sections: text.sections.map((s) => ({
      heading: fill(s.heading),
      ...(s.emphasis && { emphasis: true }),
      ...(s.paragraphs && { paragraphs: s.paragraphs.map(fill) }),
      ...(s.items && { items: s.items.map(fill) }),
    })),
  };
}

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

/**
 * Release gate for sync: once the app is configured with a Supabase project (non-empty SUPABASE_URL in
 * app/config/prod.json) it talks to the server, so the privacy text must contain every sync section
 * (src/i18n/legal.ts, SYNC_PRIVACY_RENDERED). Throws, failing the build, when one is missing. Without a URL
 * nothing is checked, so the live text can stay as it is.
 */
export function assertSyncDisclosed(
  supabaseUrl: string | undefined,
  rendered: LegalText,
  syncSections: readonly LegalSection[],
): void {
  if (!supabaseUrl?.trim()) return;
  const present = new Set(rendered.sections.map((s) => s.heading));
  const missing = syncSections.map((s) => s.heading).filter((h) => !present.has(h));
  if (missing.length > 0) {
    throw new Error(
      `app/config/prod.json sets SUPABASE_URL, but the privacy text does not contain the sync sections ` +
        `(${missing.join(', ')}). Set SYNC_PRIVACY_RENDERED to true in src/i18n/legal.ts and have the text ` +
        'reviewed (see docs/release.md, "Legal texts").',
    );
  }
}
