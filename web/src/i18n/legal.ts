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
import { ROUTE_WEB } from '../../site.config.mjs';
import type { Locale } from './index';

export interface LegalSection {
  heading: string;
  /** Rendered as a highlighted box (Legal.astro), for what the reader must not miss (right to object). */
  emphasis?: boolean;
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
          'Website, App und Server sprechen nur über verschlüsselte Verbindungen (HTTPS/TLS).',
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
          '„In meiner Nähe“ ist freiwillig und startet nur, wenn du es antippst. Die App fragt den Standort nur während der Nutzung und nur grob ab (nicht im Hintergrund). Sie rundet ihn auf zwei Nachkommastellen (ca. 1 km) und sendet ihn an unsere Edge Function. Dort wird er auf ein Raster von ca. 1,2 × 0,6 km (Geohash, Stufe 6) gerundet. Nur dieser gerundete Punkt geht an Tankerkönig (Tankerkönig UG (haftungsbeschränkt), Nesselwang), ohne deine IP-Adresse und ohne Nutzerkennung. Tankerkönig erhält also keine personenbezogenen Daten von dir. Der genaue Standort wird nicht gespeichert.',
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
          'Absturzberichte sind standardmäßig aus. Du kannst sie unter Einstellungen, Datenschutz einschalten und jederzeit wieder ausschalten. Dann gehen sie an Sentry (Functional Software, Inc., USA), das als unser Auftragsverarbeiter arbeitet (Auftragsverarbeitungsvertrag). Die Berichte werden in der EU-Region (Frankfurt) gespeichert. Konto- und Projektdaten sowie Support-Daten liegen bei Sentry in den USA. Für Übermittlungen in die USA gilt der Angemessenheitsbeschluss zum EU-US Data Privacy Framework (Sentry ist zertifiziert), hilfsweise Standardvertragsklauseln. Bevor ein Bericht die App verlässt, entfernt sie persönliche Angaben.',
          `Sentry löscht die Berichte nach ${deDaysDat(r.sentry_days)}.`,
          'Gesendet werden: der Typ des Fehlers und der Stack-Trace (Funktions-, Datei- und Paketnamen, Zeile, Spalte), Betriebssystem und Version, Dart-Laufzeit, App-Name und -Version, Zeitpunkt, technische Kennungen zur Zuordnung des Codes, die Namen der aufgerufenen Bildschirme und Befehle. Technisch bedingt sieht Sentry beim Empfang auch die IP-Adresse.',
          'Nicht gesendet werden: Fehlertexte, Namen, Titel, Notizen, Beträge, IBAN, E-Mail-Adressen, Telefonnummern, Gerätename oder -modell, Screenshots. Es gibt keine Nutzerkennung.',
          'Rechtsgrundlage ist deine Einwilligung (Art. 6 Abs. 1 lit. a DSGVO, § 25 Abs. 1 TDDDG), widerruflich mit dem Schalter.',
        ],
      },
      {
        heading: 'Server (Supabase)',
        paragraphs: [
          'Unser Server läuft bei Supabase (Supabase Pte. Ltd., Singapur) in der Region eu-central-1 (Frankfurt). Supabase ist unser Auftragsverarbeiter. Es gilt ein Auftragsverarbeitungsvertrag. Weil Supabase ihren Sitz in Singapur hat, stützen sich Übermittlungen in Drittländer auf Standardvertragsklauseln (Art. 46 Abs. 2 lit. c DSGVO), die Teil dieses Vertrags sind. Unterauftragsverarbeiter sind AWS, Cloudflare und Google.',
          'Heute läuft dort nur die Abfrage von Spritpreisen und Wechselkursen sowie die Annahme von Nachrichten aus dem Kontaktformular. Konten, Gruppen-Synchronisierung und Push-Nachrichten gibt es noch nicht.',
          `Die Plattform-Logs von Supabase (technische Protokolle der Anfragen an den Server) werden höchstens ${deDays(r.platform_logs_max_days)} aufbewahrt. Die genaue Dauer legt Supabase fest.`,
        ],
      },
      {
        heading: 'Website',
        paragraphs: [
          'Die Website ist eine statische Seite bei Firebase Hosting (Google Ireland Limited, Gordon House, Barrow Street, Dublin 4, Irland; Google LLC, USA, ist Konzerngesellschaft). Google ist unser Auftragsverarbeiter (Firebase-Auftragsverarbeitungsbedingungen). Für Übermittlungen in die USA gilt der EU-US Data Privacy Framework (Google LLC ist zertifiziert), hilfsweise Standardvertragsklauseln.',
          'Bei jedem Aufruf übermittelt dein Browser technisch notwendige Verbindungsdaten: IP-Adresse, Datum und Uhrzeit, aufgerufene URL, HTTP-Status, übertragene Datenmenge, Referrer sowie Browser und Betriebssystem (User-Agent). Google nennt für Firebase Hosting ausdrücklich die IP-Adresse (zur Missbrauchserkennung und für Nutzungsstatistiken); welche der weiteren Angaben Google protokolliert, legt Google fest. Wir haben keinen Zugriff auf diese Logs und werten sie nicht aus. Rechtsgrundlage: Art. 6 Abs. 1 lit. f DSGVO.',
          'Die Seite setzt keine Cookies und speichert nichts im Browser. Sie nutzt keine Analyse- oder Werbedienste und lädt keine externen Schriften oder Skripte.',
          'Der Rechner läuft in deinem Browser. Deine Eingaben verlassen ihn nicht.',
          'Zeigt der Rechner Spritpreise an, ruft dein Browser unseren Server ab, ohne Cookies und ohne Referrer. Die Folgen sind wie oben unter „Spritpreise“ beschrieben: Standort nur, wenn du „In meiner Nähe“ antippst. Der Link „Per WhatsApp teilen“ öffnet erst beim Anklicken WhatsApp.',
        ],
      },
      {
        heading: 'Kontaktformular',
        paragraphs: [
          'Im Kontaktformular auf der Website gibst du eine Nachricht, deine E-Mail-Adresse und optional deinen Namen ein. Pflicht sind nur E-Mail-Adresse und Nachricht. Diese Angaben gehen über eine Edge Function unseres Servers (Supabase) an Resend (Plus Five Five, Inc., USA, handelt unter dem Namen Resend), unseren Auftragsverarbeiter. Es gilt ein Auftragsverarbeitungsvertrag. Wir lassen die Mails über Resends Region Irland versenden. Resend speichert Konto-Daten, Mail-Metadaten und Protokolle nach eigenen Angaben aber in den USA. Für Übermittlungen in die USA gilt der EU-US Data Privacy Framework (Resend ist zertifiziert), hilfsweise Standardvertragsklauseln. Resend stellt die Nachricht in unser Postfach bei unserem E-Mail-Anbieter zu.',
          'Auf unserem Server wird nichts gespeichert außer den Rate-Limit-Einträgen: ein Hash deiner IP-Adresse mit geheimem Zusatz (Salt) und ein Zähler, dazu ein einziger globaler Tageszähler ohne Bezug zu dir (siehe „Missbrauchsschutz“). Fehlerprotokolle des Servers enthalten nie Nachricht, E-Mail-Adresse, Name oder IP-Adresse.',
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
          'Server-Logs der Website bei Firebase Hosting: verarbeitet Google. Nach Angaben von Google bleibt die IP-Adresse dort einige Monate gespeichert. Wir haben keinen Zugriff darauf und werten sie nicht aus.',
          'Versandprotokolle bei Resend: legt Resend fest.',
          `E-Mails und Nachrichten aus dem Kontaktformular: ${deMonths(r.email_months)} nach der letzten Nachricht.`,
          `Datenschutzanfragen und unsere Antworten: ${deYears(r.privacy_request_years)}, um nachzuweisen, dass wir deine Rechte erfüllt haben (Rechenschaftspflicht, Art. 5 Abs. 2 DSGVO).`,
        ],
      },
      {
        heading: 'App Store und Google Play',
        paragraphs: [
          'Wenn du die App über den Apple App Store oder Google Play lädst, verarbeiten Apple bzw. Google deine Daten (z. B. Konto, Zahlung, Download) als eigene Verantwortliche nach ihren Datenschutzerklärungen. Wir erhalten von ihnen keine personenbezogenen Daten über dich.',
        ],
      },
      {
        heading: 'Empfänger',
        items: [
          'Supabase Pte. Ltd. (Auftragsverarbeiter): unser Server, siehe „Server (Supabase)“.',
          'Resend, Plus Five Five, Inc. (Auftragsverarbeiter): Versand der Kontaktformular-Nachrichten, siehe „Kontaktformular“.',
          'Google Ireland Limited (Auftragsverarbeiter): Firebase Hosting der Website, siehe „Website“.',
          'Functional Software, Inc. (Sentry) (Auftragsverarbeiter): Absturzberichte, nur mit deiner Einwilligung, siehe „Absturzberichte“.',
          'Tankerkönig UG (haftungsbeschränkt): erhält nur den gerundeten Punkt, keine personenbezogenen Daten, siehe „Spritpreise“.',
          'Europäische Kommission: sieht beim direkten Download des Weekly Oil Bulletin deine IP-Adresse, siehe „Spritpreise“.',
          'Apple und Google (App Stores): eigene Verantwortliche, siehe „App Store und Google Play“.',
          'Unser E-Mail-Anbieter: hält das Postfach, in dem Nachrichten an contact@ und privacy@mitlio.de landen.',
        ],
      },
      {
        heading: 'Bereitstellung der Daten und automatisierte Entscheidungen',
        paragraphs: [
          'Du bist weder gesetzlich noch vertraglich verpflichtet, uns Daten bereitzustellen. Ohne sie kannst du das Kontaktformular nicht nutzen bzw. „In meiner Nähe“ nicht verwenden. Die App und der Rechner funktionieren ohne beides.',
          'Es findet keine automatisierte Entscheidungsfindung einschließlich Profiling nach Art. 22 DSGVO statt.',
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
      {
        heading: 'Widerspruchsrecht (Art. 21 DSGVO)',
        emphasis: true,
        paragraphs: [
          'Du kannst jederzeit aus Gründen, die sich aus deiner besonderen Situation ergeben, Widerspruch gegen eine Verarbeitung einlegen, die wir auf berechtigte Interessen stützen (Art. 6 Abs. 1 lit. f DSGVO). Wir verarbeiten deine Daten dann nicht mehr, es sei denn, wir können zwingende schutzwürdige Gründe nachweisen, die deine Interessen überwiegen, oder die Verarbeitung dient der Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen.',
          'Auf berechtigte Interessen stützen wir: den Missbrauchsschutz (Rate Limit), die Server-Logs der Website bei Firebase Hosting, den direkten Download des Weekly Oil Bulletin bei der Europäischen Kommission und das Kontaktformular, soweit deine Nachricht nicht die Nutzung der App betrifft.',
          'Wir betreiben keine Direktwerbung. Deine Daten werden dafür nicht verwendet.',
          'Schreib uns den Widerspruch an privacy@mitlio.de.',
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
          'Website, app and server talk only over encrypted connections (HTTPS/TLS).',
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
          '“Near me” is optional and starts only when you tap it. The app asks for your location only while you use it and only roughly (never in the background). It rounds it to two decimals (about 1 km) and sends it to our Edge Function. There it is rounded to a grid cell of about 1.2 × 0.6 km (geohash, precision 6). Only that rounded point goes to Tankerkönig (Tankerkönig UG (haftungsbeschränkt), Nesselwang, Germany), without your IP address and without any user ID. Tankerkönig therefore receives no personal data from you. The exact location is not stored.',
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
          'Crash reports are off by default. You can turn them on under Settings, Privacy, and off again at any time. They then go to Sentry (Functional Software, Inc., USA), which acts as our processor (data processing agreement). The reports are stored in the EU region (Frankfurt). Account and project data and support data are held by Sentry in the USA. Transfers to the USA rely on the adequacy decision for the EU-US Data Privacy Framework (Sentry is certified) and, as a fallback, standard contractual clauses. Before a report leaves the app, the app removes personal details.',
          `Sentry deletes the reports after ${enDays(r.sentry_days)}.`,
          'What is sent: the error type and stack trace (function, file and package names, line, column), operating system and version, Dart runtime, app name and version, time, technical identifiers to match the code, and the names of the screens and commands used. By the nature of the connection, Sentry also sees the IP address on receipt.',
          'What is not sent: error messages, names, titles, notes, amounts, IBAN, email addresses, phone numbers, device name or model, screenshots. There is no user ID.',
          'Legal basis is your consent (Art. 6(1)(a) GDPR, § 25(1) TDDDG), which you can withdraw with the switch.',
        ],
      },
      {
        heading: 'Server (Supabase)',
        paragraphs: [
          'Our server runs at Supabase (Supabase Pte. Ltd., Singapore) in region eu-central-1 (Frankfurt). Supabase is our processor under a data processing agreement. Because Supabase is based in Singapore, transfers to third countries rely on standard contractual clauses (Art. 46(2)(c) GDPR), which are part of that agreement. Sub-processors are AWS, Cloudflare and Google.',
          'Today it only serves fuel prices and exchange rates and receives messages from the contact form. There are no accounts, group sync or push notifications yet.',
          `Supabase’s platform logs (technical records of requests to the server) are kept for ${enDays(r.platform_logs_max_days)} at most. Supabase decides the exact period.`,
        ],
      },
      {
        heading: 'Website',
        paragraphs: [
          'The website is a static site on Firebase Hosting (Google Ireland Limited, Gordon House, Barrow Street, Dublin 4, Ireland; Google LLC, USA, is a group company). Google is our processor (Firebase data processing terms). Transfers to the USA rely on the EU-US Data Privacy Framework (Google LLC is certified) and, as a fallback, standard contractual clauses.',
          'With every request your browser sends technically necessary connection data: IP address, date and time, requested URL, HTTP status, amount of data transferred, referrer, and browser and operating system (user agent). Google explicitly names the IP address for Firebase Hosting (to detect abuse and for usage statistics); which of the other items Google logs is up to Google. We have no access to these logs and do not evaluate them. Legal basis: Art. 6(1)(f) GDPR.',
          'The site sets no cookies and stores nothing in your browser. It uses no analytics or advertising services and loads no external fonts or scripts.',
          'The calculator runs in your browser. Your input does not leave it.',
          'If the calculator shows fuel prices, your browser calls our server, without cookies and without a referrer. The same applies as under “Fuel prices” above: your location is used only if you tap “Near me”. The “Share via WhatsApp” link opens WhatsApp only when you click it.',
        ],
      },
      {
        heading: 'Contact form',
        paragraphs: [
          'In the contact form on the website you enter a message, your email address and optionally your name. Only the email address and the message are required. This data goes through an Edge Function on our server (Supabase) to Resend (Plus Five Five, Inc., USA, operating as Resend), our processor, under a data processing agreement. We have the mails sent from Resend’s Ireland region. By its own account, however, Resend stores account data, mail metadata and logs in the USA. Transfers to the USA rely on the EU-US Data Privacy Framework (Resend is certified) and, as a fallback, standard contractual clauses. Resend delivers the message to our mailbox at our email provider.',
          'Nothing is stored on our server except the rate-limit entries: a hash of your IP address with a secret salt and a counter, plus a single global daily counter that has no link to you (see “Abuse protection”). The server’s error logs never contain the message, email address, name or IP address.',
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
          'Website server logs at Firebase Hosting: processed by Google. According to Google, the IP address is kept there for a few months. We have no access to them and do not evaluate them.',
          'Sending logs at Resend: set by Resend.',
          `Emails and contact form messages: ${enMonths(r.email_months)} after the last message.`,
          `Data protection requests and our replies: ${enYears(r.privacy_request_years)}, to prove that we met your rights (accountability, Art. 5(2) GDPR).`,
        ],
      },
      {
        heading: 'App Store and Google Play',
        paragraphs: [
          'If you download the app from the Apple App Store or Google Play, Apple or Google process your data (for example account, payment, download) as independent controllers under their own privacy policies. We receive no personal data about you from them.',
        ],
      },
      {
        heading: 'Recipients',
        items: [
          'Supabase Pte. Ltd. (processor): our server, see “Server (Supabase)”.',
          'Resend, Plus Five Five, Inc. (processor): sending contact form messages, see “Contact form”.',
          'Google Ireland Limited (processor): Firebase Hosting of the website, see “Website”.',
          'Functional Software, Inc. (Sentry) (processor): crash reports, only with your consent, see “Crash reports”.',
          'Tankerkönig UG (haftungsbeschränkt): receives only the rounded point, no personal data, see “Fuel prices”.',
          'European Commission: sees your IP address when the Weekly Oil Bulletin is downloaded directly, see “Fuel prices”.',
          'Apple and Google (app stores): independent controllers, see “App Store and Google Play”.',
          'Our email provider: hosts the mailbox where messages to contact@ and privacy@mitlio.de arrive.',
        ],
      },
      {
        heading: 'Providing data and automated decisions',
        paragraphs: [
          'You are neither legally nor contractually required to provide us with data. Without it you simply cannot use the contact form or “Near me”. The app and the calculator work without either.',
          'There is no automated decision-making, including profiling, under Art. 22 GDPR.',
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
      {
        heading: 'Right to object (Art. 21 GDPR)',
        emphasis: true,
        paragraphs: [
          'You can object at any time, on grounds relating to your particular situation, to processing that we base on legitimate interests (Art. 6(1)(f) GDPR). We then stop processing your data unless we can show compelling legitimate grounds that override your interests, or the processing serves to establish, exercise or defend legal claims.',
          'We rely on legitimate interests for: abuse protection (rate limit), the website server logs at Firebase Hosting, the direct download of the Weekly Oil Bulletin from the European Commission, and the contact form where your message does not concern using the app.',
          'We do no direct marketing. Your data is not used for it.',
          'Send your objection to privacy@mitlio.de.',
        ],
      },
    ],
  },
} as const satisfies Record<LegalKey, LegalText>;

// ---------------------------------------------------------------------------------------------------------------
// Sync (anonymous sign-in, shared groups on the server, invite links). Rendered when
// `SYNC_PRIVACY_RENDERED` is true; keep it in step with whether app/config/prod.json carries a Supabase URL.
//
// Every statement below was checked against supabase/migrations/0001 to 0014, docs/data-deletion.md,
// docs/data-flows.md and the sync code (app/lib/features/sync). Where the server stores something, the table is
// named in the comment next to it. Re-check when a migration or the sync payload changes.
//
// Rendered since the first sync release (2026-11-21). Push notifications do not ship with it, so the push
// section and its recipient and retention lines were removed; add them back together with push (P6b).
// The production build fails if SUPABASE_URL is set in app/config/prod.json while this is false
// (assertSyncDisclosed in src/lib/legal.ts, docs/release.md).
// ---------------------------------------------------------------------------------------------------------------

/** Renders the sync sections and the changed live sections. Flip together with SUPABASE_URL in prod.json. */
export const SYNC_PRIVACY_RENDERED = true;

type SectionChange = (live: LegalSection) => LegalSection;

export interface SyncPrivacy {
  /** Heading of the live section after which `sections` are inserted. */
  insertAfter: string;
  /** New sections, only rendered when sync is live. */
  sections: readonly LegalSection[];
  /** Changes to live sections (keyed by heading) that are only true once sync is live. */
  changes: Readonly<Record<string, SectionChange>>;
}

/** The live text plus the sync variant. Throws when a heading it refers to no longer exists. */
export function withSync(live: LegalText, sync: SyncPrivacy): LegalText {
  const headings = live.sections.map((s) => s.heading);
  for (const heading of [sync.insertAfter, ...Object.keys(sync.changes)]) {
    if (!headings.includes(heading)) throw new Error(`Sync privacy text refers to unknown section "${heading}"`);
  }
  const changed = live.sections.map((s) => sync.changes[s.heading]?.(s) ?? s);
  const at = headings.indexOf(sync.insertAfter) + 1;
  return { sections: [...changed.slice(0, at), ...sync.sections, ...changed.slice(at)] };
}

const paragraph = (s: LegalSection, i: number): string => {
  const p = s.paragraphs?.[i];
  if (p === undefined) throw new Error(`Section "${s.heading}" has no paragraph ${i}`);
  return p;
};

export const futurePrivacySectionsDe: readonly LegalSection[] = [
  {
    heading: 'Geteilte Gruppen (Synchronisierung)',
    paragraphs: [
      'Sobald du eine Gruppe teilst oder über einen Einladungslink einer Gruppe beitrittst, meldet sich die App anonym bei unserem Server an. Dafür brauchst du keine E-Mail-Adresse und keinen Namen. Wir speichern eine zufällige Konto-Kennung und die technischen Daten der Anmeldung (Sitzungen und Zeitpunkte, die Supabase Auth dafür anlegt). Gruppen, die du nicht teilst, bleiben auf deinem Gerät.',
      'Für eine geteilte Gruppe speichert unser Server:',
    ],
    items: [
      'Gruppe: Name, Währung, Zeitpunkte und die Kennung des Kontos, das sie angelegt hat.',
      'Mitglieder: Namen und Reihenfolge, die Verknüpfung mit einem Konto und, falls du sie eingetragen hast, ein PayPal.Me-Name und ein gekürzter IBAN-Hinweis (zum Beispiel „DE89 …3000“).',
      'Ausgaben: Titel, Kategorie, Betrag, Währung und Wechselkurs, Datum, Art und Aufteilung, wer wie viel bezahlt hat und wer welchen Anteil trägt, bei Abrechnungen von Fahrten Zeitraum, Fahrer und die zugehörigen Fahrten.',
      'Ausgleichszahlungen: wer wem wie viel wann bezahlt hat und auf welche Weise (PayPal, SEPA, bar, andere).',
      'Fahrten: Datum, Entfernung (nicht Start und Ziel), Hin- und Rückfahrt, Maut, Fahrzeug, Fahrer, Mitfahrende und der Kraftstoffpreis.',
      'Fahrzeuge (Name, Kraftstoffart, Verbrauch, Verschleiß, Kilometersatz) und Fahrtvorlagen (Name, Entfernung, Fahrzeug, Fahrer, Mitfahrende, Maut).',
      'Änderungsverlauf: bei jeder Änderung oder Löschung einer Ausgabe der vorherige Stand, der Zeitpunkt und das Mitglied, das die Änderung gemacht hat.',
      'Zugehörigkeit: welches Konto zu welcher Gruppe gehört, mit welchem Mitglied es verbunden ist und ob es die Gruppe angelegt hat.',
      'Einladungen: nur ein Hash des Tokens (nicht der Link selbst), das Konto, das sie erstellt hat, und die Zeitpunkte.',
    ],
  },
  {
    heading: 'Geteilte Gruppen: was auf dem Gerät bleibt und wer was sieht',
    paragraphs: [
      'Nicht an den Server gesendet werden: die vollständige IBAN mit BIC und Kontoinhaber, gespeicherte Orte („Zuhause“, „Arbeit“), die Texte und Orte aus der Streckenberechnung (nur die Entfernung kommt in die Fahrt), dein Standort und deine Entscheidung zu Absturzberichten.',
      'Die Daten einer Gruppe sind in der App nur für die Konten sichtbar, die mit dieser Gruppe verbunden sind. Das erzwingt die Datenbank selbst (Zugriffsregeln auf Zeilenebene). Jedes verbundene Mitglied sieht alles in der Gruppe: Namen, Beträge, Fahrten, Ausgleichszahlungen.',
      'Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO: Das Teilen einer Gruppe ist die Funktion, die du nutzt. Für Personen, die mitlio nicht nutzen, gilt der nächste Abschnitt.',
    ],
  },
  {
    heading: 'Personen in geteilten Gruppen, die mitlio nicht nutzen (Art. 14 DSGVO)',
    paragraphs: [
      'Mitglieder können in einer Gruppe auch Namen von Personen eintragen, die mitlio selbst nicht nutzen, zum Beispiel Mitfahrende. In einer geteilten Gruppe liegen diese Angaben auf unserem Server. Weil wir diese Personen nicht kennen und nicht erreichen können, informieren wir sie hier (Art. 14 Abs. 5 lit. b DSGVO).',
      'Quelle: die Mitglieder der Gruppe, die den Namen eingetragen haben. Die Daten stammen nicht von der betroffenen Person.',
      'Kategorien: der eingetragene Name und alles, was in dieser Gruppe damit verknüpft ist: bezahlte Beträge, Anteile an Ausgaben, Ausgleichszahlungen, Fahrten als Fahrer oder Mitfahrende (Datum, Entfernung) und, falls ein Mitglied sie eingetragen hat, ein PayPal.Me-Name oder ein gekürzter IBAN-Hinweis.',
      'Zweck und Rechtsgrundlage: die gemeinsamen Kosten der Gruppe fair berechnen und für alle Mitglieder nachvollziehbar halten. Das ist ein berechtigtes Interesse der Gruppe und von uns (Art. 6 Abs. 1 lit. f DSGVO). Wir verwenden die Daten für nichts anderes. Empfänger sind die Mitglieder der Gruppe und Supabase als unser Auftragsverarbeiter.',
      `Speicherdauer: solange die Gruppe besteht. Sie wird gelöscht, wenn kein Konto mehr mit ihr verbunden ist. Anonyme Konten löschen wir nach ${deMonths(r.inactive_account_months)} ohne Aktivität.`,
      'Deine Rechte: Du hast alle Rechte aus „Deine Rechte“, auch Auskunft, Berichtigung, Löschung und Widerspruch. So wirst du entfernt: Bitte die Gruppe, deinen Namen zu ändern oder dich zu entfernen. Oder schreib an privacy@mitlio.de und nenne uns die Gruppe und den Namen, unter dem du dort stehst. Beträge und Salden der anderen Mitglieder müssen dabei richtig bleiben, deshalb ersetzen wir den Namen gegebenenfalls durch einen neutralen.',
    ],
  },
  {
    heading: 'Einladungslinks',
    paragraphs: [
      'Ein Einladungslink enthält ein Token, mit dem andere der Gruppe beitreten können. Wir speichern nur einen Hash des Tokens, nicht das Token selbst. Der Link läuft nicht von selbst ab. Wer die Gruppe angelegt hat, kann einen neuen Link erzeugen: Dann werden alle älteren Links ungültig. Ein Link lässt sich auch widerrufen.',
      'Beim Beitritt begrenzen wir die Zahl der Versuche je Konto (Rate Limit, die Kennung nur als Hash). Erfolgreiche Beitritte und das Verbinden mit einem Mitglied halten wir in einem Protokoll fest (Konto, Gruppe, Mitglied, Zeitpunkt), zum Schutz vor Missbrauch (Art. 6 Abs. 1 lit. f DSGVO).',
      `Das Beitrittsprotokoll löschen wir nach ${deDaysDat(r.join_audit_days)}. Abgelaufene Einladungen löschen wir ${deDaysDat(r.expired_invites_days_after_expiry)} nach Ablauf. Widerrufene und ersetzte Links bleiben als Hash, bis die Gruppe gelöscht wird.`,
    ],
  },
  {
    heading: 'Alle meine Daten löschen und geteilte Gruppen',
    paragraphs: [
      'Hast du Gruppen geteilt, ruft die App beim Löschen zuerst unseren Server auf und leert erst danach dein Gerät. Schlägt der Aufruf fehl, bleibt alles erhalten und du kannst es erneut versuchen.',
      'Auf dem Server werden gelöscht: deine Verbindungen zu den Gruppen (du kannst sie nicht mehr öffnen), die Verknüpfung zwischen deinem Konto und deinem Mitglied und dein anonymes Konto samt Sitzungen, den von dir erstellten Einladungen und deinen Einträgen im Beitrittsprotokoll. Hast du die Gruppe angelegt, geht die Rolle an das am längsten verbundene Mitglied.',
      'Es bleiben die Gruppendaten, die du mit anderen teilst: Gruppe, Namen der Mitglieder (auch deiner, dann ohne Verbindung zu einem Konto), Ausgaben, Ausgleichszahlungen, Fahrten und Änderungsverlauf. Sie gehören zur Gruppe, und ihr Löschen würde die Salden der anderen verändern. Willst du auch deinen Namen dort loswerden, bitte die Gruppe, ihn zu ändern oder zu entfernen, oder schreib an privacy@mitlio.de. Auch Kopien auf den Geräten der anderen Mitglieder können wir nicht löschen.',
      'Warst du das letzte verbundene Konto, löschen wir die Gruppe mit allen Daten im täglichen Löschlauf, also etwa einen Tag später.',
    ],
  },
];

export const futurePrivacySectionsEn: readonly LegalSection[] = [
  {
    heading: 'Shared groups (sync)',
    paragraphs: [
      'As soon as you share a group or join one through an invite link, the app signs in to our server anonymously. You need no email address and no name for that. We store a random account ID and the technical data of the sign-in (sessions and timestamps that Supabase Auth creates for it). Groups you do not share stay on your device.',
      'For a shared group our server stores:',
    ],
    items: [
      'Group: name, currency, timestamps and the ID of the account that created it.',
      'Members: names and order, the link to an account and, if you entered them, a PayPal.Me name and a shortened IBAN hint (for example “DE89 …3000”).',
      'Expenses: title, category, amount, currency and exchange rate, date, type and split, who paid how much and who bears which share, and for ride settlements the period, driver and the rides involved.',
      'Settlements: who paid whom how much, when and how (PayPal, SEPA, cash, other).',
      'Rides: date, distance (not start and destination), round trip, tolls, vehicle, driver, passengers and the fuel price.',
      'Vehicles (name, fuel type, consumption, wear, per-kilometre rate) and ride templates (name, distance, vehicle, driver, passengers, tolls).',
      'Edit history: for every change or deletion of an expense, the previous version, the time and the member who made the change.',
      'Membership: which account belongs to which group, which member it is linked to and whether it created the group.',
      'Invites: only a hash of the token (not the link itself), the account that created it and the timestamps.',
    ],
  },
  {
    heading: 'Shared groups: what stays on your device and who sees what',
    paragraphs: [
      'Not sent to the server: the full IBAN with BIC and account holder, saved places (“Home”, “Work”), the text and places from the route lookup (only the distance goes into the ride), your location and your crash-report choice.',
      'The data of a group is visible in the app only to the accounts linked to that group. The database itself enforces this (row-level security). Every linked member sees everything in the group: names, amounts, rides, settlements.',
      'Legal basis is Art. 6(1)(b) GDPR: sharing a group is the feature you use. For people who do not use mitlio, the next section applies.',
    ],
  },
  {
    heading: 'People in shared groups who do not use mitlio (Art. 14 GDPR)',
    paragraphs: [
      'Members can also enter the names of people who do not use mitlio themselves, for example passengers. In a shared group this data is stored on our server. Because we do not know these people and cannot reach them, we inform them here (Art. 14(5)(b) GDPR).',
      'Source: the members of the group who entered the name. The data does not come from the person concerned.',
      'Categories: the entered name and everything linked to it in that group: amounts paid, shares of expenses, settlements, rides as driver or passenger (date, distance) and, if a member entered them, a PayPal.Me name or a shortened IBAN hint.',
      'Purpose and legal basis: to calculate the group’s shared costs fairly and keep them traceable for all members. This is a legitimate interest of the group and of ours (Art. 6(1)(f) GDPR). We use the data for nothing else. Recipients are the members of the group and Supabase as our processor.',
      `Retention: as long as the group exists. It is deleted when no account is linked to it any more. We delete anonymous accounts after ${enMonths(r.inactive_account_months)} without activity.`,
      'Your rights: you have all the rights under “Your rights”, including access, rectification, erasure and objection. To be removed: ask the group to change your name or remove you. Or write to privacy@mitlio.de and tell us the group and the name under which you appear there. The other members’ amounts and balances must stay correct, so we may replace the name with a neutral one.',
    ],
  },
  {
    heading: 'Invite links',
    paragraphs: [
      'An invite link contains a token that lets others join the group. We store only a hash of the token, not the token itself. The link does not expire on its own. Whoever created the group can generate a new link: all older links then stop working. A link can also be revoked.',
      'When joining, we limit the number of attempts per account (rate limit, the ID only as a hash). We keep a log of successful joins and of linking to a member (account, group, member, time) to prevent abuse (Art. 6(1)(f) GDPR).',
      `We delete the join log after ${enDays(r.join_audit_days)}. We delete expired invites ${enDays(r.expired_invites_days_after_expiry)} after they expire. Revoked and replaced links stay as a hash until the group is deleted.`,
    ],
  },
  {
    heading: 'Delete all my data and shared groups',
    paragraphs: [
      'If you shared groups, the app first calls our server when you delete and only then wipes your device. If the call fails, everything is kept and you can try again.',
      'Deleted on the server: your links to the groups (you can no longer open them), the link between your account and your member and your anonymous account including its sessions, the invites you created and your entries in the join log. If you created the group, that role passes to the member who has been linked the longest.',
      'What stays is the group data you share with others: the group, member names (including yours, then without a link to any account), expenses, settlements, rides and edit history. It belongs to the group, and deleting it would change the others’ balances. If you also want your name gone there, ask the group to change or remove it, or write to privacy@mitlio.de. We also cannot delete copies on the other members’ devices.',
      'If you were the last linked account, we delete the group with all its data in the daily cleanup run, so about a day later.',
    ],
  },
];

const syncDe: SyncPrivacy = {
  insertAfter: 'App: Daten auf deinem Gerät',
  sections: futurePrivacySectionsDe,
  changes: {
    'Kurz gesagt': (s) => ({
      ...s,
      items: [
        'Ohne Teilen bleiben deine Daten auf deinem Gerät. Es gibt keine Werbung und kein Konto mit E-Mail-Adresse oder Namen.',
        'Teilst du eine Gruppe oder trittst du einer bei, meldet sich die App anonym an. Die Daten dieser Gruppe (Namen, Ausgaben, Beträge, Fahrten) liegen dann auf unserem Server, damit die anderen Mitglieder sie sehen.',
        'Deine vollständige IBAN, gespeicherte Orte und deine Wahl zu Absturzberichten bleiben auf deinem Gerät.',
        'Der Server liefert außerdem Spritpreise und Wechselkurse und nimmt Nachrichten aus dem Kontaktformular entgegen.',
        ...(s.items ?? []).slice(3),
      ],
    }),
    'App: Daten auf deinem Gerät': (s) => ({
      ...s,
      paragraphs: [
        'Gruppen, Mitglieder, Ausgaben, Fahrten, Ausgleichszahlungen und deine Einstellungen speichert die App auf deinem Gerät. Gruppen, die du nicht teilst, bleiben dort, und wir erhalten sie nicht. Für geteilte Gruppen gilt „Geteilte Gruppen (Synchronisierung)“.',
        'Die IBAN wird verschlüsselt gespeichert. Der Schlüssel liegt im Schlüsselbund (iOS Keychain) bzw. Keystore (Android) deines Geräts. Die vollständige IBAN wird nicht synchronisiert und nicht an uns gesendet.',
        'Nur auf dem Gerät bleiben außerdem gespeicherte Orte („Zuhause“, „Arbeit“) und deine Entscheidung zu Absturzberichten.',
        paragraph(s, 2),
        'Du kannst alles jederzeit löschen: Einstellungen, Datenschutz, „Alle meine Daten löschen“. Das entfernt alle Daten, die IBAN und ihren Schlüssel von diesem Gerät. Hast du Gruppen geteilt, löscht es auch dein Konto auf dem Server (siehe „Alle meine Daten löschen und geteilte Gruppen“). Das Löschen lässt sich nicht rückgängig machen.',
      ],
    }),
    'Server (Supabase)': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'Dort laufen die Abfrage von Spritpreisen und Wechselkursen, die Annahme von Nachrichten aus dem Kontaktformular und, sobald du eine Gruppe teilst, die Speicherung der Gruppendaten, deines anonymen Kontos und der Einladungen (siehe „Geteilte Gruppen (Synchronisierung)“). Supabase verarbeitet diese Inhalte nur in unserem Auftrag.',
        paragraph(s, 2),
      ],
    }),
    Speicherdauer: (s) => {
      const items = s.items ?? [];
      return {
        ...s,
        items: [
          items[0] ?? '',
          'Geteilte Gruppen auf dem Server: solange die Gruppe besteht. Sie besteht, solange mindestens ein Konto mit ihr verbunden ist. Ist keins mehr übrig, löschen wir sie mit allen Daten im täglichen Löschlauf, also etwa einen Tag später.',
          `Anonyme Konten: ${deMonths(r.inactive_account_months)} ohne Aktivität. Aktivität heißt, dass sich die App in dieser Zeit am Server angemeldet oder ihre Anmeldung erneuert hat. Dann löschen wir das Konto so, als hättest du „Alle meine Daten löschen“ gewählt.`,
          `Änderungsverlauf einer Ausgabe: die letzten ${r.expense_revisions_per_expense} Stände, ältere werden automatisch entfernt. Der Verlauf bleibt, solange die Gruppe besteht, auch wenn die Ausgabe gelöscht wurde (sie bleibt als gelöscht markiert, damit alle Geräte die Löschung übernehmen).`,
          `Beitrittsprotokoll: ${deDays(r.join_audit_days)}. Einladungen: ${deDays(r.expired_invites_days_after_expiry)} nach Ablauf. Widerrufene und ersetzte Links bleiben als Hash, bis die Gruppe gelöscht wird.`,
          ...items.slice(1),
        ],
      };
    },
    Empfänger: (s) => ({
      ...s,
      items: [
        ...(s.items ?? []),
        'Mitglieder deiner geteilten Gruppen: sehen die Daten der Gruppe, siehe „Geteilte Gruppen (Synchronisierung)“.',
      ],
    }),
    'Bereitstellung der Daten und automatisierte Entscheidungen': (s) => ({
      ...s,
      paragraphs: [
        'Du bist weder gesetzlich noch vertraglich verpflichtet, uns Daten bereitzustellen. Ohne sie kannst du das Kontaktformular nicht nutzen, „In meiner Nähe“ nicht verwenden und keine Gruppe teilen oder einer beitreten. Die App und der Rechner funktionieren ohne all das.',
        paragraph(s, 1),
      ],
    }),
    'Deine Rechte': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'Schreib uns dafür an privacy@mitlio.de. Dein Konto ist anonym: Wir kennen weder deinen Namen noch eine E-Mail-Adresse und können dich nicht allein anhand deiner Nachricht einem Konto zuordnen. Nenne uns deshalb die Gruppe und den Namen, unter dem du dort stehst. Daten, die zu anderen Mitgliedern gehören, geben wir nicht heraus, soweit deren Rechte entgegenstehen (Art. 15 Abs. 4 DSGVO). Dein Konto und die Verbindung zu deinen Gruppen löschst du am schnellsten selbst mit „Alle meine Daten löschen“. Die Daten auf deinem Gerät kannst du ebenfalls selbst löschen.',
        paragraph(s, 2),
      ],
    }),
    'Widerspruchsrecht (Art. 21 DSGVO)': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'Auf berechtigte Interessen stützen wir: den Missbrauchsschutz (Rate Limit, auch beim Beitritt zu Gruppen mit dem Beitrittsprotokoll), die Server-Logs der Website bei Firebase Hosting, den direkten Download des Weekly Oil Bulletin bei der Europäischen Kommission, das Kontaktformular, soweit deine Nachricht nicht die Nutzung der App betrifft, und die Daten von Personen, die mitlio nicht nutzen und von anderen in eine Gruppe eingetragen wurden.',
        paragraph(s, 2),
        paragraph(s, 3),
      ],
    }),
  },
};

const syncEn: SyncPrivacy = {
  insertAfter: 'App: data on your device',
  sections: futurePrivacySectionsEn,
  changes: {
    'In short': (s) => ({
      ...s,
      items: [
        'Unless you share, your data stays on your device. There are no ads and no account with an email address or name.',
        'If you share a group or join one, the app signs in anonymously. That group’s data (names, expenses, amounts, rides) is then stored on our server so the other members can see it.',
        'Your full IBAN, saved places and your crash-report choice stay on your device.',
        'The server also serves fuel prices and exchange rates and receives messages from the contact form.',
        ...(s.items ?? []).slice(3),
      ],
    }),
    'App: data on your device': (s) => ({
      ...s,
      paragraphs: [
        'Groups, members, expenses, rides, settlements and your settings are stored on your device. Groups you do not share stay there, and we do not receive them. For shared groups, “Shared groups (sync)” applies.',
        'The IBAN is stored encrypted. The key is kept in your device’s Keychain (iOS) or Keystore (Android). The full IBAN is not synced and not sent to us.',
        'Saved places (“Home”, “Work”) and your crash-report choice also stay on the device only.',
        paragraph(s, 2),
        'You can delete everything at any time: Settings, Privacy, “Delete all my data”. This removes all data, the IBAN and its key from this device. If you shared groups, it also deletes your account on the server (see “Delete all my data and shared groups”). It cannot be undone.',
      ],
    }),
    'Server (Supabase)': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'It serves fuel prices and exchange rates, receives messages from the contact form and, as soon as you share a group, stores the group data, your anonymous account and the invites (see “Shared groups (sync)”). Supabase processes this content only on our behalf.',
        paragraph(s, 2),
      ],
    }),
    Retention: (s) => {
      const items = s.items ?? [];
      return {
        ...s,
        items: [
          items[0] ?? '',
          'Shared groups on the server: as long as the group exists. It exists as long as at least one account is linked to it. When none is left, we delete it with all its data in the daily cleanup run, so about a day later.',
          `Anonymous accounts: ${enMonths(r.inactive_account_months)} without activity. Activity means the app signed in to the server or renewed its sign-in during that time. We then delete the account as if you had chosen “Delete all my data”.`,
          `Edit history of an expense: the last ${r.expense_revisions_per_expense} versions, older ones are removed automatically. The history stays as long as the group exists, even if the expense was deleted (it stays marked as deleted so all devices pick up the deletion).`,
          `Join log: ${enDays(r.join_audit_days)}. Invites: ${enDays(r.expired_invites_days_after_expiry)} after they expire. Revoked and replaced links stay as a hash until the group is deleted.`,
          ...items.slice(1),
        ],
      };
    },
    Recipients: (s) => ({
      ...s,
      items: [
        ...(s.items ?? []),
        'Members of your shared groups: see the group data, see “Shared groups (sync)”.',
      ],
    }),
    'Providing data and automated decisions': (s) => ({
      ...s,
      paragraphs: [
        'You are neither legally nor contractually required to provide us with data. Without it you cannot use the contact form or “Near me”, and you cannot share or join a group. The app and the calculator work without any of it.',
        paragraph(s, 1),
      ],
    }),
    'Your rights': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'Write to privacy@mitlio.de. Your account is anonymous: we know neither your name nor an email address and cannot link your message to an account on its own. So tell us the group and the name under which you appear there. We do not hand out data that belongs to other members where their rights stand in the way (Art. 15(4) GDPR). The quickest way to delete your account and its link to your groups is “Delete all my data” yourself. You can also delete the data on your device yourself.',
        paragraph(s, 2),
      ],
    }),
    'Right to object (Art. 21 GDPR)': (s) => ({
      ...s,
      paragraphs: [
        paragraph(s, 0),
        'We rely on legitimate interests for: abuse protection (rate limit, also when joining groups, with the join log), the website server logs at Firebase Hosting, the direct download of the Weekly Oil Bulletin from the European Commission, the contact form where your message does not concern use of the app, and the data of people who do not use mitlio and were entered into a group by others.',
        paragraph(s, 2),
        paragraph(s, 3),
      ],
    }),
  },
};

// ---------------------------------------------------------------------------------------------------------------
// From-to route field on the website (PW-T12, issue #207). Signed off by the owner (2026-11-23).
// Rendered only when the website is built with ROUTE_WEB=1 (site.config.mjs), the same flag that renders the field.
//
// Checked against docs/route-distance-api.md and supabase/functions/_shared/route.ts: the typed text goes to our
// Edge Function, which sends it to openrouteservice; only the function's egress IP reaches the provider; the
// function logs neither text nor coordinates; rate limiting keeps only a salted hash.
// ---------------------------------------------------------------------------------------------------------------

export const routePrivacySectionDe: LegalSection = {
  heading: 'Strecke berechnen (Website)',
  paragraphs: [
    'Im Rechner auf der Website kannst du optional „Start und Ziel eingeben, Strecke berechnen“ aufklappen. Erst wenn du dort mindestens 3 Zeichen tippst, sendet dein Browser den Text an unseren Server (Edge Function bei Supabase). Beim Laden der Seite wird nichts gesendet. Die Eingabe ist verzögert (ca. 0,3 Sekunden nach dem letzten Tastendruck), damit nicht jeder Buchstabe einzeln gesendet wird.',
    'Unser Server leitet den Text für die Adressvorschläge und, nach deiner Auswahl, die Koordinaten von Start und Ziel für die Streckenberechnung an openrouteservice weiter (HeiGIT gGmbH, Heidelberg, Deutschland). openrouteservice sieht nur die Adresse unseres Servers, nicht deine IP-Adresse und keine Nutzerkennung. Eine Adresse, die du tippst, kann ein personenbezogenes Datum sein (zum Beispiel deine Wohnadresse). Wir speichern weder den Text noch die Koordinaten und schreiben sie nicht in Protokolle.',
    'Für den Missbrauchsschutz gilt „Missbrauchsschutz (Rate Limit)“: Dort liegt nur ein gesalzener Hash deiner Anfrage-Kennung, nie der Text.',
    'Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO (du löst die Berechnung selbst aus). Die Funktion ist freiwillig. Die Kilometer kannst du jederzeit von Hand eintragen. Die Karten- und Routendaten stammen von OpenStreetMap-Mitwirkenden (ODbL), bereitgestellt über openrouteservice.',
  ],
};

export const routePrivacySectionEn: LegalSection = {
  heading: 'Calculating a route (website)',
  paragraphs: [
    'In the calculator on the website you can optionally open “Enter start and destination, calculate distance”. Only once you type at least 3 characters there does your browser send the text to our server (an Edge Function at Supabase). Nothing is sent when the page loads. Input is debounced (about 0.3 seconds after the last keystroke) so that not every single letter is sent.',
    'Our server forwards the text for the address suggestions and, after you pick, the coordinates of start and destination for the route calculation to openrouteservice (HeiGIT gGmbH, Heidelberg, Germany). openrouteservice only sees the address of our server, not your IP address and no user ID. An address you type can be personal data (for example your home address). We store neither the text nor the coordinates and do not write them to logs.',
    'For abuse protection, “Abuse protection (rate limit)” applies: only a salted hash of your request identifier is kept there, never the text.',
    'The legal basis is Art. 6(1)(b) GDPR (you trigger the calculation yourself). The feature is optional. You can always enter the kilometres by hand. Map and route data come from OpenStreetMap contributors (ODbL), provided via openrouteservice.',
  ],
};

const routeRecipientDe = 'HeiGIT gGmbH (openrouteservice): erhält Adresstext und Koordinaten ohne deine IP-Adresse, siehe „Strecke berechnen (Website)“.';
const routeRecipientEn = 'HeiGIT gGmbH (openrouteservice): receives address text and coordinates without your IP address, see “Calculating a route (website)”.';

/** The privacy text plus the route section after the fuel section and a recipient line. Throws on a renamed heading. */
export function withRoute(text: LegalText, section: LegalSection, insertAfter: string, recipients: string, recipient: string): LegalText {
  const headings = text.sections.map((s) => s.heading);
  for (const heading of [insertAfter, recipients]) {
    if (!headings.includes(heading)) throw new Error(`Route privacy text refers to unknown section "${heading}"`);
  }
  const withRecipient = text.sections.map((s) => (s.heading === recipients ? { ...s, items: [...(s.items ?? []), recipient] } : s));
  const at = headings.indexOf(insertAfter) + 1;
  return { sections: [...withRecipient.slice(0, at), section, ...withRecipient.slice(at)] };
}

/** Both languages: the live text, plus the sync variant when `syncLive` and the route section when `routeLive`. */
export function buildLegalTexts(syncLive: boolean, routeLive = false): Record<Locale, Record<LegalKey, LegalText>> {
  const privacyDe = syncLive ? withSync(de.privacy, syncDe) : de.privacy;
  const privacyEn = syncLive ? withSync(en.privacy, syncEn) : en.privacy;
  return {
    de: {
      imprint: de.imprint,
      privacy: routeLive ? withRoute(privacyDe, routePrivacySectionDe, 'Spritpreise', 'Empfänger', routeRecipientDe) : privacyDe,
    },
    en: {
      imprint: en.imprint,
      privacy: routeLive ? withRoute(privacyEn, routePrivacySectionEn, 'Fuel prices', 'Recipients', routeRecipientEn) : privacyEn,
    },
  };
}

export const legalTexts = buildLegalTexts(SYNC_PRIVACY_RENDERED, ROUTE_WEB);

/** The sections that must be part of the rendered privacy text once the app talks to a Supabase project. */
export const syncPrivacySections: Record<Locale, readonly LegalSection[]> = {
  de: futurePrivacySectionsDe,
  en: futurePrivacySectionsEn,
};
