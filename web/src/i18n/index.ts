export const locales = ['de', 'en'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'de';

export type RouteKey = 'home' | 'imprint' | 'privacy';

/** Path of every route per locale. Keep in sync with src/pages. */
export const paths: Record<RouteKey, Record<Locale, string>> = {
  home: { de: '/', en: '/en/' },
  imprint: { de: '/impressum/', en: '/en/imprint/' },
  privacy: { de: '/datenschutz/', en: '/en/privacy/' },
};

export const htmlLang: Record<Locale, string> = { de: 'de-DE', en: 'en' };

export const messages = {
  de: {
    siteName: 'mitlio',
    skipLink: 'Zum Inhalt springen',
    homeTitle: 'Fahrtkosten fair teilen | mitlio',
    homeDescription:
      'Fahrtkosten und Spritkosten fair auf alle Mitfahrenden aufteilen. Kostenlos, ohne Anmeldung, ohne Werbung.',
    heroTitle: 'Fahrtkosten fair teilen',
    heroLead: 'Strecke, Verbrauch und Spritpreis eingeben und sofort sehen, was jede Person zahlt.',
    calculatorLabel: 'Fahrtkostenrechner',
    imprint: 'Impressum',
    privacy: 'Datenschutz',
    otherLanguage: 'English',
    otherLanguageLang: 'en',
    legalPlaceholder: 'TODO owner: Rechtstext wird vom Betreiber ergänzt.',
    notFoundTitle: 'Seite nicht gefunden | mitlio',
    notFoundHeading: 'Seite nicht gefunden',
    notFoundLead: 'Diese Seite gibt es nicht.',
    backHome: 'Zur Startseite',
  },
  en: {
    siteName: 'mitlio',
    skipLink: 'Skip to content',
    homeTitle: 'Split trip costs fairly | mitlio',
    homeDescription:
      'Split car trip and fuel costs fairly between everyone on board. Free, no sign-up, no ads.',
    heroTitle: 'Split trip costs fairly',
    heroLead: 'Enter distance, consumption and fuel price and see what each person pays.',
    calculatorLabel: 'Trip cost calculator',
    imprint: 'Imprint',
    privacy: 'Privacy',
    otherLanguage: 'Deutsch',
    otherLanguageLang: 'de',
    legalPlaceholder: 'TODO owner: legal text is to be provided by the operator.',
    notFoundTitle: 'Page not found | mitlio',
    notFoundHeading: 'Page not found',
    notFoundLead: 'This page does not exist.',
    backHome: 'Back to home',
  },
} as const satisfies Record<Locale, Record<string, string>>;
