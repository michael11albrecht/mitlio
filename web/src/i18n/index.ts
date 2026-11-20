export const locales = ['de', 'en'] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = 'de';

export type RouteKey = 'home' | 'imprint' | 'privacy' | 'contact';

/** Path of every route per locale. Keep in sync with src/pages. */
export const paths: Record<RouteKey, Record<Locale, string>> = {
  home: { de: '/', en: '/en/' },
  imprint: { de: '/impressum/', en: '/en/imprint/' },
  privacy: { de: '/datenschutz/', en: '/en/privacy/' },
  contact: { de: '/kontakt/', en: '/en/contact/' },
};

/** Path of a landing page (or, without slug, the home page) in a locale. */
export const landingPath = (locale: Locale, slug?: string): string =>
  slug ? `${locale === 'de' ? '' : '/en'}/${slug}/` : paths.home[locale];

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
    contact: 'Kontakt',
    creditLead: 'Mit',
    creditMid: 'gemacht von',
    otherLanguage: 'English',
    otherLanguageLang: 'en',
    notFoundTitle: 'Seite nicht gefunden | mitlio',
    notFoundHeading: 'Seite nicht gefunden',
    notFoundLead: 'Diese Seite gibt es nicht.',
    backHome: 'Zur Startseite',
    joinTitle: 'Einladung zu mitlio',
    joinHeading: 'Öffne den Link auf deinem Handy mit mitlio',
    joinLead:
      'Dieser Link ist eine Einladung in eine mitlio-Gruppe. Ist mitlio auf deinem Handy installiert, tippe den Link dort noch einmal an. Dann öffnet sich die App.',
    joinNoApp: 'Noch kein mitlio? Lade die App zuerst herunter und tippe den Link danach noch einmal an.',
    joinStoresSoon: 'mitlio ist bald im App Store und bei Google Play.',
    joinPrivacy: 'Dieser Link wird auf dieser Seite nicht gespeichert und nirgendwohin gesendet.',
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
    contact: 'Contact',
    creditLead: 'Made with',
    creditMid: 'by',
    otherLanguage: 'Deutsch',
    otherLanguageLang: 'de',
    notFoundTitle: 'Page not found | mitlio',
    notFoundHeading: 'Page not found',
    notFoundLead: 'This page does not exist.',
    backHome: 'Back to home',
    joinTitle: 'Invitation to mitlio',
    joinHeading: 'Open this link on your phone with mitlio',
    joinLead:
      'This link is an invitation to a mitlio group. If mitlio is installed on your phone, tap the link there again. The app opens.',
    joinNoApp: 'No mitlio yet? Download the app first, then tap the link again.',
    joinStoresSoon: 'mitlio is coming soon to the App Store and Google Play.',
    joinPrivacy: 'This page does not store the link and sends it nowhere.',
  },
} as const satisfies Record<Locale, Record<string, string>>;
