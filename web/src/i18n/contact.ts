import type { Locale } from './index';

/** Contact form strings (de/en). Du-form; every error says what happened and what to do. */
export const contactMessages = {
  de: {
    title: 'Kontakt | mitlio',
    heading: 'Kontakt',
    description: 'Schreib dem mitlio-Team eine Nachricht.',
    lead: 'Schreib uns eine Nachricht. Wir melden uns per E-Mail bei dir.',
    direct: 'Du erreichst uns auch direkt unter',
    labelName: 'Name (optional)',
    labelEmail: 'Deine E-Mail-Adresse',
    labelMessage: 'Deine Nachricht',
    send: 'Nachricht senden',
    sending: 'Wird gesendet …',
    success: 'Danke! Wir melden uns per E-Mail.',
    errorEmail: 'Diese E-Mail-Adresse sieht nicht richtig aus. Prüf sie bitte noch einmal.',
    errorMessageShort: 'Deine Nachricht ist zu kurz. Schreib bitte mindestens 10 Zeichen.',
    errorMessageLong: 'Deine Nachricht ist zu lang. Schreib bitte höchstens 5000 Zeichen.',
    errorNameLong: 'Dein Name ist zu lang. Nutze bitte höchstens 100 Zeichen.',
    errorRateLimitedOne: 'Zu viele Nachrichten. Versuch es in 1 Minute wieder.',
    errorRateLimitedMany: 'Zu viele Nachrichten. Versuch es in {minutes} Minuten wieder.',
    errorNetwork:
      'Keine Verbindung zum Server. Prüf dein Netz und versuch es noch einmal. Deine Nachricht bleibt hier stehen.',
    errorNotConfigured: 'Das Formular ist gerade nicht erreichbar. Schreib uns an contact@mitlio.de.',
    errorSendFailed:
      'Deine Nachricht ist nicht angekommen. Versuch es in ein paar Minuten noch einmal oder schreib uns an contact@mitlio.de.',
    noForm: 'Das Formular ist hier gerade nicht verfügbar. Schreib uns an contact@mitlio.de.',
    noscript: 'Für das Formular brauchst du JavaScript. Oder schreib uns an contact@mitlio.de.',
    privacyBefore: 'Deine Angaben nutzen wir nur, um dir zu antworten. Mehr dazu in der',
    privacyLink: 'Datenschutzerklärung',
    privacyAfter: '.',
  },
  en: {
    title: 'Contact | mitlio',
    heading: 'Contact',
    description: 'Send the mitlio team a message.',
    lead: 'Send us a message. We will reply by email.',
    direct: 'You can also reach us directly at',
    labelName: 'Name (optional)',
    labelEmail: 'Your email address',
    labelMessage: 'Your message',
    send: 'Send message',
    sending: 'Sending …',
    success: 'Thanks! We will get back to you by email.',
    errorEmail: 'This email address does not look right. Please check it and try again.',
    errorMessageShort: 'Your message is too short. Please write at least 10 characters.',
    errorMessageLong: 'Your message is too long. Please write at most 5000 characters.',
    errorNameLong: 'Your name is too long. Please use at most 100 characters.',
    errorRateLimitedOne: 'Too many messages. Try again in 1 minute.',
    errorRateLimitedMany: 'Too many messages. Try again in {minutes} minutes.',
    errorNetwork: 'No connection to the server. Check your network and try again. Your message stays here.',
    errorNotConfigured: 'The form is not reachable right now. Write to us at contact@mitlio.de.',
    errorSendFailed:
      'Your message did not arrive. Try again in a few minutes or write to us at contact@mitlio.de.',
    noForm: 'The form is not available here right now. Write to us at contact@mitlio.de.',
    noscript: 'The form needs JavaScript. Or write to us at contact@mitlio.de.',
    privacyBefore: 'We only use your details to reply to you. More in the',
    privacyLink: 'privacy policy',
    privacyAfter: '.',
  },
} as const satisfies Record<Locale, Record<string, string>>;

export type ContactMessageKey = keyof (typeof contactMessages)['de'];
