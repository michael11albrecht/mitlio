// ENTWURF, vor Veröffentlichung prüfen lassen (z. B. Anwalt oder Generator wie eRecht24).
// DRAFT, have it reviewed before publishing (e.g. a lawyer or a generator such as eRecht24).
//
// Source of truth for the Impressum / Datenschutzerklärung and their English versions (imprint / privacy).
// Every statement is based on the code and docs; the PR that introduced this file lists where each one was
// checked. Change a statement here only together with the behaviour it describes.
//
// Placeholders look like `[[...]]`. The postal address is injected at build time from LEGAL_STREET and
// LEGAL_CITY (see src/lib/legal.ts); it is never written into the repository. A production build fails while
// any placeholder is left (docs/release.md, "Legal texts").
//
// Every retention period in the text is interpolated from supabase/retention.json (docs/retention.md), so the
// text cannot drift from the code. Change a period there, not here.
import retention from '../../../supabase/retention.json' with { type: 'json' };
import type { Locale } from './index';

export interface LegalSection {
  heading: string;
  paragraphs?: readonly string[];
  items?: readonly string[];
}

export interface LegalText {
  sections: readonly LegalSection[];
}

export type LegalKey = 'imprint' | 'privacy';

const r = retention;
const plural = (n: number, one: string, many: string): string => `${n} ${n === 1 ? one : many}`;
const deDays = (n: number): string => plural(n, 'Tag', 'Tage');
const deDaysDat = (n: number): string => plural(n, 'Tag', 'Tagen');
const deMonths = (n: number): string => plural(n, 'Monat', 'Monate');
const deYears = (n: number): string => plural(n, 'Jahr', 'Jahre');
const enDays = (n: number): string => plural(n, 'day', 'days');
const enMonths = (n: number): string => plural(n, 'month', 'months');
const enYears = (n: number): string => plural(n, 'year', 'years');

const de = {
  imprint: {
    sections: [
      {
        heading: 'Angaben gemäß § 5 DDG',
        paragraphs: ['Michael Albrecht', '[[STRASSE HAUSNUMMER]]', '[[PLZ ORT]]'],
      },
      {
        heading: 'Kontakt',
        paragraphs: ['E-Mail: contact@mitlio.de', 'Kontaktformular: mitlio.de/kontakt/'],
      },
      {
        heading: 'Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV',
        paragraphs: ['Michael Albrecht, Anschrift wie oben.'],
      },
    ],
  },
  privacy: {
    sections: [
      {
        heading: 'Kurz gesagt',
        items: [
          'Die App speichert deine Daten auf deinem Gerät. Es gibt kein Konto und keine Werbung.',
          'Deine IBAN bleibt verschlüsselt auf dem Gerät und wird nie übertragen.',
          'Unser Server liefert nur Spritpreise und Wechselkurse und nimmt Nachrichten aus dem Kontaktformular entgegen.',
          'Dein Standort und Absturzberichte werden nur mit deiner Zustimmung verwendet.',
          'Die Website setzt keine Cookies und nutzt keine Analyse- oder Werbedienste.',
        ],
      },
      {
        heading: 'Verantwortlicher',
        paragraphs: ['Michael Albrecht, [[STRASSE HAUSNUMMER]], [[PLZ ORT]], E-Mail: privacy@mitlio.de'],
      },
      {
        heading: 'App: Daten auf deinem Gerät',
        paragraphs: [
          'Gruppen, Mitglieder, Ausgaben, Fahrten, Ausgleichszahlungen und deine Einstellungen speichert die App nur auf deinem Gerät. Wir erhalten sie nicht.',
          'Die IBAN wird verschlüsselt gespeichert. Der Schlüssel liegt im Schlüsselbund (iOS Keychain) bzw. Keystore (Android) deines Geräts. Die IBAN wird nicht synchronisiert und nicht an uns gesendet.',
          'Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO (die App soll für dich funktionieren). Die Speicherung auf dem Gerät ist dafür unbedingt erforderlich (§ 25 Abs. 2 Nr. 2 TDDDG).',
          'Du kannst alles jederzeit löschen: Einstellungen, Datenschutz, „Alle meine Daten löschen“. Das entfernt alle Daten, die IBAN und ihren Schlüssel von diesem Gerät. Das Löschen lässt sich nicht rückgängig machen.',
        ],
      },
      {
        heading: 'Spritpreise',
        paragraphs: [
          'Der Bundesdurchschnitt kommt aus dem Weekly Oil Bulletin der EU. Ist kein Server eingerichtet, lädt die App diese öffentliche Datei direkt bei der Europäischen Kommission (energy.ec.europa.eu) herunter, höchstens alle 12 Stunden. Dabei sieht die Kommission wie bei jedem Download deine IP-Adresse. Die App sendet sonst nichts: kein Konto, keinen Standort, keine Gruppendaten. Rechtsgrundlage ist unser berechtigtes Interesse, dir aktuelle Preise anzuzeigen (Art. 6 Abs. 1 lit. f DSGVO). Ruft unser Server die Datei ab, werden dabei keine Nutzerdaten übertragen.',
          '„In meiner Nähe“ ist freiwillig und startet nur, wenn du es antippst. Die App fragt den Standort nur während der Nutzung und nur grob ab (nicht im Hintergrund). Sie rundet ihn auf zwei Nachkommastellen (ca. 1 km) und sendet ihn an unsere Edge Function. Dort wird er auf ein Raster von ca. 1,2 × 0,6 km (Geohash, Stufe 6) gerundet. Nur dieser gerundete Punkt geht an Tankerkönig, ohne IP-Adresse und ohne Nutzerkennung. Der genaue Standort wird nicht gespeichert.',
          'Bei einer Postleitzahl senden wir sie an unseren Server. Wir geben sie nicht an Tankerkönig weiter, sondern ordnen ihr einen festen Ort zu.',
          'Rechtsgrundlage für den Standort ist deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO, § 25 Abs. 1 TDDDG). Du kannst sie jederzeit in den Systemeinstellungen deines Geräts widerrufen. Für die Postleitzahl gilt Art. 6 Abs. 1 lit. b DSGVO.',
          'Preisdaten: MTS-K über Tankerkönig (CC BY 4.0).',
        ],
      },
      {
        heading: 'Wechselkurse',
        paragraphs: [
          'Für Ausgaben in anderer Währung fragt die App bei unserem Server einen Kurs an. Sie sendet nur die Währungscodes und gegebenenfalls ein Datum, keine Beträge und keine Gruppendaten. Der Server holt EZB-Referenzkurse über Frankfurter. Diese Anfrage enthält nur das Währungspaar und den Tag, keine Angaben zu dir.',
          'Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO.',
        ],
      },
      {
        heading: 'Missbrauchsschutz (Rate Limit)',
        paragraphs: [
          'Damit niemand unseren Server überlastet, begrenzen wir die Zahl der Anfragen pro Gerät oder Netz. Dafür speichern wir deine IP-Adresse nur als Hash mit geheimem Zusatz (Salt), nicht im Klartext.',
          `Die Einträge werden täglich bereinigt, wenn sie älter als ${deDays(r.rate_limits_days)} sind. Sie liegen also höchstens etwa ${deDays(r.rate_limits_days + 1)} vor.`,
          'Rechtsgrundlage: berechtigtes Interesse an einem sicheren Betrieb, Art. 6 Abs. 1 lit. f DSGVO.',
        ],
      },
      {
        heading: 'Bezahlen und Ausgleichen',
        paragraphs: [
          'Ein PayPal.Me-Link öffnet PayPal in einer anderen App oder im Browser. Ab dann gilt die Datenschutzerklärung von PayPal, die dafür selbst verantwortlich ist. Wir übertragen dabei nichts.',
          'Der SEPA-QR-Code wird auf deinem Gerät erzeugt. Dabei wird nichts gesendet.',
        ],
      },
      {
        heading: 'Absturzberichte (freiwillig)',
        paragraphs: [
          'Absturzberichte sind standardmäßig aus. Du kannst sie unter Einstellungen, Datenschutz einschalten und jederzeit wieder ausschalten. Dann gehen sie an Sentry (EU-Region). Bevor ein Bericht die App verlässt, entfernt sie persönliche Angaben.',
          `Sentry löscht die Berichte nach ${deDaysDat(r.sentry_days)}.`,
          'Gesendet werden: der Typ des Fehlers und der Stack-Trace (Funktions-, Datei- und Paketnamen, Zeile, Spalte), Betriebssystem und Version, Dart-Laufzeit, App-Name und -Version, Zeitpunkt, technische Kennungen zur Zuordnung des Codes, die Namen der aufgerufenen Bildschirme und Befehle. Technisch bedingt sieht Sentry beim Empfang auch die IP-Adresse.',
          'Nicht gesendet werden: Fehlertexte, Namen, Titel, Notizen, Beträge, IBAN, E-Mail-Adressen, Telefonnummern, Gerätename oder -modell, Screenshots. Es gibt keine Nutzerkennung.',
          'Rechtsgrundlage ist deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO, § 25 Abs. 1 TDDDG), widerruflich mit dem Schalter.',
        ],
      },
      {
        heading: 'Server (Supabase)',
        paragraphs: [
          'Unser Server läuft bei Supabase (Supabase Pte. Ltd.) in der Region eu-central-1 (Frankfurt). Supabase ist unser Auftragsverarbeiter. Es gilt ein Auftragsverarbeitungsvertrag. Übermittlungen in Drittländer sichern Standardvertragsklauseln. Unterauftragsverarbeiter sind AWS, Cloudflare und Google.',
          'Heute läuft dort nur die Abfrage von Spritpreisen und Wechselkursen sowie die Annahme von Nachrichten aus dem Kontaktformular. Konten, Gruppen-Synchronisierung und Push-Nachrichten gibt es noch nicht.',
          `Die Plattform-Logs von Supabase (technische Protokolle der Anfragen an den Server) werden höchstens ${deDays(r.platform_logs_max_days)} aufbewahrt. Die genaue Dauer legt Supabase fest.`,
        ],
      },
      {
        heading: 'Website',
        paragraphs: [
          'Die Website ist eine statische Seite bei Firebase Hosting (Google). Beim Aufruf verarbeitet der Hosting-Anbieter technisch notwendige Verbindungsdaten (u. a. IP-Adresse, Zeitpunkt, aufgerufene Seite) in Server-Logs. Diese Logs verarbeitet Google. Wir haben keinen Zugriff darauf und werten sie nicht aus. Rechtsgrundlage: Art. 6 Abs. 1 lit. f DSGVO.',
          'Die Seite setzt keine Cookies und speichert nichts im Browser. Sie nutzt keine Analyse- oder Werbedienste und lädt keine externen Schriften oder Skripte.',
          'Der Rechner läuft in deinem Browser. Deine Eingaben verlassen ihn nicht.',
          'Zeigt der Rechner Spritpreise an, ruft dein Browser unseren Server ab, ohne Cookies und ohne Referrer. Die Folgen sind wie oben unter „Spritpreise“ beschrieben: Standort nur, wenn du „In meiner Nähe“ antippst. Der Link „Per WhatsApp teilen“ öffnet erst beim Anklicken WhatsApp.',
        ],
      },
      {
        heading: 'Kontaktformular',
        paragraphs: [
          'Im Kontaktformular auf der Website gibst du eine Nachricht, deine E-Mail-Adresse und optional deinen Namen ein. Diese Angaben gehen über eine Edge Function unseres Servers (Supabase) an Resend (Resend, Inc., EU-Region), unseren Auftragsverarbeiter. Es gilt ein Auftragsverarbeitungsvertrag. Für eine mögliche Übermittlung in Drittländer gelten Standardvertragsklauseln. Resend stellt die Nachricht in unser Postfach zu.',
          'Auf unserem Server wird nichts gespeichert außer dem Rate-Limit-Eintrag mit dem Hash deiner IP-Adresse (siehe „Missbrauchsschutz“).',
          'Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO, wenn deine Nachricht die Nutzung der App betrifft, sonst unser berechtigtes Interesse, Anfragen zu beantworten (Art. 6 Abs. 1 lit. f DSGVO).',
          `Wir löschen die Nachricht ${deMonths(r.email_months)} nach der letzten Nachricht in diesem Austausch.`,
        ],
      },
      {
        heading: 'Speicherdauer',
        items: [
          'Daten auf deinem Gerät: bis du sie löschst oder die App deinstallierst.',
          `Rate-Limit-Hashes auf dem Server: ${deDays(r.rate_limits_days)}, höchstens etwa ${deDays(r.rate_limits_days + 1)}.`,
          `Absturzberichte bei Sentry (nur mit deiner Einwilligung): ${deDays(r.sentry_days)}.`,
          `Plattform-Logs bei Supabase: höchstens ${deDays(r.platform_logs_max_days)}. Die Dauer legt der Anbieter fest.`,
          'Server-Logs der Website bei Firebase Hosting: verarbeitet Google. Wir haben keinen Zugriff darauf und werten sie nicht aus.',
          `E-Mails und Nachrichten aus dem Kontaktformular: ${deMonths(r.email_months)} nach der letzten Nachricht.`,
          `Datenschutzanfragen und unsere Antworten: ${deYears(r.privacy_request_years)}, um nachzuweisen, dass wir deine Rechte erfüllt haben (Rechenschaftspflicht, Art. 5 Abs. 2 DSGVO).`,
        ],
      },
      {
        heading: 'Deine Rechte',
        paragraphs: [
          'Du hast das Recht auf Auskunft (Art. 15), Berichtigung (Art. 16), Löschung (Art. 17), Einschränkung der Verarbeitung (Art. 18), Datenübertragbarkeit (Art. 20) und Widerspruch (Art. 21 DSGVO). Eine Einwilligung kannst du jederzeit mit Wirkung für die Zukunft widerrufen (Art. 7 Abs. 3).',
          'Schreib uns dafür an privacy@mitlio.de. Weil die App keine Konten hat, können wir dich auf dem Server in der Regel nicht zuordnen. Die Daten auf deinem Gerät kannst du selbst löschen.',
          'Du kannst dich bei einer Datenschutz-Aufsichtsbehörde beschweren. Zuständig ist: Bayerisches Landesamt für Datenschutzaufsicht (BayLDA), Promenade 18, 91522 Ansbach, www.lda.bayern.de.',
        ],
      },
    ],
  },
} as const satisfies Record<LegalKey, LegalText>;

const en = {
  imprint: {
    sections: [
      {
        heading: 'Information according to § 5 DDG',
        paragraphs: ['Michael Albrecht', '[[STRASSE HAUSNUMMER]]', '[[PLZ ORT]]'],
      },
      {
        heading: 'Contact',
        paragraphs: ['Email: contact@mitlio.de', 'Contact form: mitlio.de/en/contact/'],
      },
      {
        heading: 'Responsible for content under § 18 (2) MStV',
        paragraphs: ['Michael Albrecht, address as above.'],
      },
    ],
  },
  privacy: {
    sections: [
      {
        heading: 'In short',
        items: [
          'The app stores your data on your device. There is no account and there are no ads.',
          'Your IBAN stays encrypted on the device and is never transmitted.',
          'Our server only provides fuel prices and exchange rates and receives messages from the contact form.',
          'Your location and crash reports are only used with your consent.',
          'The website sets no cookies and uses no analytics or advertising services.',
        ],
      },
      {
        heading: 'Controller',
        paragraphs: ['Michael Albrecht, [[STRASSE HAUSNUMMER]], [[PLZ ORT]], email: privacy@mitlio.de'],
      },
      {
        heading: 'App: data on your device',
        paragraphs: [
          'Groups, members, expenses, rides, settlements and your settings are stored on your device only. We do not receive them.',
          'The IBAN is stored encrypted. The key is kept in your device’s Keychain (iOS) or Keystore (Android). The IBAN is not synced and not sent to us.',
          'Legal basis: Art. 6(1)(b) GDPR (making the app work for you). Storing data on the device is strictly necessary for this (§ 25(2) no. 2 TDDDG).',
          'You can delete everything at any time: Settings, Privacy, “Delete all my data”. This removes all data, the IBAN and its key from this device. It cannot be undone.',
        ],
      },
      {
        heading: 'Fuel prices',
        paragraphs: [
          'The national average comes from the EU Weekly Oil Bulletin. Without a configured server, the app downloads this public file directly from the European Commission (energy.ec.europa.eu), at most every 12 hours. As with any download, the Commission sees your IP address. The app sends nothing else: no account, no location, no group data. The legal basis is our legitimate interest in showing you current prices (Art. 6(1)(f) GDPR). When our server fetches the file, no user data is sent.',
          '“Near me” is optional and starts only when you tap it. The app asks for your location only while you use it and only roughly (never in the background). It rounds it to two decimals (about 1 km) and sends it to our Edge Function. There it is rounded to a grid cell of about 1.2 × 0.6 km (geohash, precision 6). Only that rounded point goes to Tankerkönig, without IP address and without any user ID. The exact location is not stored.',
          'If you enter a postcode, we send it to our server. We do not pass it on to Tankerkönig; we map it to a fixed place instead.',
          'Legal basis for the location is your consent (Art. 6(1)(a) GDPR, § 25(1) TDDDG). You can withdraw it at any time in your device settings. For the postcode, Art. 6(1)(b) GDPR applies.',
          'Price data: MTS-K via Tankerkönig (CC BY 4.0).',
        ],
      },
      {
        heading: 'Exchange rates',
        paragraphs: [
          'For expenses in another currency the app asks our server for a rate. It sends only the currency codes and possibly a date, no amounts and no group data. The server fetches ECB reference rates via Frankfurter. That request contains only the currency pair and the day, nothing about you.',
          'Legal basis: Art. 6(1)(b) GDPR.',
        ],
      },
      {
        heading: 'Abuse protection (rate limit)',
        paragraphs: [
          'To keep anyone from overloading our server we limit the number of requests per device or network. For this we store your IP address only as a hash with a secret salt, never in plain text.',
          `Entries older than ${enDays(r.rate_limits_days)} are removed by a daily clean-up, so they exist for about ${enDays(r.rate_limits_days + 1)} at most.`,
          'Legal basis: legitimate interest in secure operation, Art. 6(1)(f) GDPR.',
        ],
      },
      {
        heading: 'Paying and settling up',
        paragraphs: [
          'A PayPal.Me link opens PayPal in another app or in the browser. From then on PayPal’s privacy policy applies; PayPal is responsible for that processing. We transmit nothing in the process.',
          'The SEPA QR code is generated on your device. Nothing is sent.',
        ],
      },
      {
        heading: 'Crash reports (optional)',
        paragraphs: [
          'Crash reports are off by default. You can turn them on under Settings, Privacy, and off again at any time. They then go to Sentry (EU region). Before a report leaves the app, the app removes personal details.',
          `Sentry deletes the reports after ${enDays(r.sentry_days)}.`,
          'What is sent: the error type and stack trace (function, file and package names, line, column), operating system and version, Dart runtime, app name and version, time, technical identifiers to match the code, and the names of the screens and commands used. By the nature of the connection, Sentry also sees the IP address on receipt.',
          'What is not sent: error messages, names, titles, notes, amounts, IBAN, email addresses, phone numbers, device name or model, screenshots. There is no user ID.',
          'Legal basis is your consent (Art. 6(1)(a) GDPR, § 25(1) TDDDG), which you can withdraw with the switch.',
        ],
      },
      {
        heading: 'Server (Supabase)',
        paragraphs: [
          'Our server runs at Supabase (Supabase Pte. Ltd.) in region eu-central-1 (Frankfurt). Supabase is our processor under a data processing agreement. Transfers to third countries are covered by standard contractual clauses. Sub-processors are AWS, Cloudflare and Google.',
          'Today it only serves fuel prices and exchange rates and receives messages from the contact form. There are no accounts, group sync or push notifications yet.',
          `Supabase’s platform logs (technical records of requests to the server) are kept for ${enDays(r.platform_logs_max_days)} at most. Supabase decides the exact period.`,
        ],
      },
      {
        heading: 'Website',
        paragraphs: [
          'The website is a static site on Firebase Hosting (Google). When you visit it, the hosting provider processes technically necessary connection data (including IP address, time, page requested) in server logs. Google processes these logs. We have no access to them and do not evaluate them. Legal basis: Art. 6(1)(f) GDPR.',
          'The site sets no cookies and stores nothing in your browser. It uses no analytics or advertising services and loads no external fonts or scripts.',
          'The calculator runs in your browser. Your input does not leave it.',
          'If the calculator shows fuel prices, your browser calls our server, without cookies and without a referrer. The same applies as under “Fuel prices” above: your location is used only if you tap “Near me”. The “Share via WhatsApp” link opens WhatsApp only when you click it.',
        ],
      },
      {
        heading: 'Contact form',
        paragraphs: [
          'In the contact form on the website you enter a message, your email address and optionally your name. This data goes through an Edge Function on our server (Supabase) to Resend (Resend, Inc., EU region), our processor, under a data processing agreement. Standard contractual clauses cover any transfer to a third country. Resend delivers the message to our mailbox.',
          'Nothing is stored on our server except the rate-limit entry with the hash of your IP address (see “Abuse protection”).',
          'Legal basis: Art. 6(1)(b) GDPR if your message concerns using the app, otherwise our legitimate interest in answering enquiries (Art. 6(1)(f) GDPR).',
          `We delete the message ${enMonths(r.email_months)} after the last message in that exchange.`,
        ],
      },
      {
        heading: 'Retention',
        items: [
          'Data on your device: until you delete it or uninstall the app.',
          `Rate-limit hashes on the server: ${enDays(r.rate_limits_days)}, about ${enDays(r.rate_limits_days + 1)} at most.`,
          `Crash reports at Sentry (only with your consent): ${enDays(r.sentry_days)}.`,
          `Platform logs at Supabase: ${enDays(r.platform_logs_max_days)} at most. The provider decides the period.`,
          'Website server logs at Firebase Hosting: processed by Google. We have no access to them and do not evaluate them.',
          `Emails and contact form messages: ${enMonths(r.email_months)} after the last message.`,
          `Data protection requests and our replies: ${enYears(r.privacy_request_years)}, to prove that we met your rights (accountability, Art. 5(2) GDPR).`,
        ],
      },
      {
        heading: 'Your rights',
        paragraphs: [
          'You have the right of access (Art. 15), rectification (Art. 16), erasure (Art. 17), restriction of processing (Art. 18), data portability (Art. 20) and objection (Art. 21 GDPR). You can withdraw consent at any time with effect for the future (Art. 7(3)).',
          'Write to privacy@mitlio.de. Because the app has no accounts, we usually cannot link anything on the server to you. You can delete the data on your device yourself.',
          'You can lodge a complaint with a data protection supervisory authority. The competent one is: Bavarian Data Protection Authority (BayLDA), Promenade 18, 91522 Ansbach, www.lda.bayern.de.',
        ],
      },
    ],
  },
} as const satisfies Record<LegalKey, LegalText>;

export const legalTexts: Record<Locale, Record<LegalKey, LegalText>> = { de, en };

// TODO(owner): enable when sync/push ships. NOT rendered today, so the live text matches reality. When the
// features go live, move these sections into `privacy.sections` above (and add them to the English text),
// then re-check every sentence against the shipped behaviour and docs/data-deletion.md.
export const futurePrivacySectionsDe: readonly LegalSection[] = [
  {
    heading: 'Anonyme Anmeldung und Gruppen-Synchronisierung',
    paragraphs: [
      'Wenn du eine Gruppe teilst, meldet sich die App anonym bei unserem Server an. Gruppen, Mitglieder, Ausgaben und Fahrten dieser Gruppe werden dann mit den anderen Mitgliedern synchronisiert. Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO.',
    ],
  },
  {
    heading: 'Einladungslinks',
    paragraphs: [
      'Ein Einladungslink enthält ein Token, mit dem andere der Gruppe beitreten können. Beim Beitritt begrenzen wir die Zahl der Versuche (Rate Limit) und halten erfolgreiche Beitritte in einem Protokoll fest, zum Schutz vor Missbrauch (Art. 6 Abs. 1 lit. f DSGVO).',
      `Das Beitrittsprotokoll löschen wir nach ${deDaysDat(r.join_audit_days)}. Abgelaufene Einladungen löschen wir ${deDaysDat(r.expired_invites_days_after_expiry)} nach Ablauf.`,
    ],
  },
  {
    heading: 'Push-Nachrichten',
    paragraphs: [
      'Für Push-Nachrichten speichern wir ein Geräte-Token und deine Benachrichtigungseinstellungen. Zugestellt wird über Firebase Cloud Messaging (Google, Datenübertragung in die USA auf Grundlage des EU-US Data Privacy Framework) und auf iOS über Apples Push-Dienst (APNs). Rechtsgrundlage: deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO).',
    ],
  },
];

export const futurePrivacySectionsEn: readonly LegalSection[] = [
  {
    heading: 'Anonymous sign-in and group sync',
    paragraphs: [
      'When you share a group, the app signs in to our server anonymously. The group’s members, expenses and rides are then synced with the other members. Legal basis: Art. 6(1)(b) GDPR.',
    ],
  },
  {
    heading: 'Invite links',
    paragraphs: [
      'An invite link contains a token that lets others join the group. When joining, we limit the number of attempts (rate limit) and keep a log of successful joins to prevent abuse (Art. 6(1)(f) GDPR).',
      `We delete the join log after ${enDays(r.join_audit_days)}. We delete expired invites ${enDays(r.expired_invites_days_after_expiry)} after they expire.`,
    ],
  },
  {
    heading: 'Push notifications',
    paragraphs: [
      'For push notifications we store a device token and your notification settings. They are delivered through Firebase Cloud Messaging (Google, transfer to the USA under the EU-US Data Privacy Framework) and, on iOS, Apple’s push service (APNs). Legal basis: your consent (Art. 6(1)(a) GDPR).',
    ],
  },
];
