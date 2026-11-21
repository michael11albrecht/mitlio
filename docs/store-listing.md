# App Store listing and App Privacy answers (draft for owner review)

Primary language German (Germany), second localization English. Bundle id `app.mitlio`, SKU `mitlio-ios`.
Limits are Apple's: name 30, subtitle 30, promotional text 170, keywords 100 (comma separated, no spaces), description 4000.
Feature claims checked against the code (l10n strings and merged sync PRs #196 to #208) on 2026-11-21. Facts below come from `docs/data-flows.md`, `docs/retention.md` and the app features on `main`. Items marked **OWNER** need a decision or an input only the owner has.

## Listing: German (primary)

| Field | Text | Chars |
|---|---|---|
| Name | mitlio | 6 |
| Subtitle | Fahrtkosten fair teilen | 23 |
| Promotional text | Wer fährt, wer zahlt, wer schuldet wem? mitlio rechnet Fahrten und Gruppenausgaben fair ab. Ohne Werbung, ohne Tracking. | 120 |
| Keywords | Fahrgemeinschaft,Spritkosten,Kilometer,Pendeln,Reisekasse,Ausgaben,teilen,Urlaub,WG,Schulden | 92 |
| Category | Primary: Finance. Secondary: Travel (or Utilities, **OWNER**) | |
| Support URL | https://mitlio.de/kontakt/ | |
| Marketing URL | https://mitlio.de/ | |
| Privacy policy URL | https://mitlio.de/datenschutz/ | |
| Copyright | 2026 Michael Albrecht | |

Description:

```
mitlio ist das private Taxometer: Es teilt Fahrtkosten und Gruppenausgaben fair auf. Ergebnis zuerst, wenige Taps, keine Werbung.

FAHRTEN
- Strecke, Spritpreis und Verbrauch eintragen, die Kosten pro Person stehen sofort da
- Aktuelle Spritpreise als Vorschlag: Bundesdurchschnitt oder in deiner Nähe (nur nach deinem Tipp)
- Optional Verschleiß pro Kilometer einrechnen
- Strecke aus Start und Ziel berechnen lassen oder einfach Kilometer eingeben
- Regelmäßig fahren? Fahrten sammeln und einmal im Monat abrechnen

GRUPPEN-AUSGABEN
- Urlaub, WG, Ausflug: Ausgaben erfassen, mehrere Zahler, gleich oder individuell aufteilen
- Faire Rundung auf den Cent, keine Rechenfehler
- Wer schuldet wem? mitlio fasst Schulden mit möglichst wenigen Überweisungen zusammen
- Fremdwährungen mit festgehaltenem Wechselkurs

BEZAHLEN UND TEILEN
- PayPal.Me-Link oder Überweisungs-QR direkt aus der Abrechnung
- Export als Tabelle (CSV): alle Ausgaben und Salden
- Gruppen per Einladungslink gemeinsam nutzen (anonym, ohne Konto mit E-Mail)

PRIVAT
- Kein Konto mit E-Mail nötig, keine Werbung, kein Tracking, keine Weitergabe an Werbenetzwerke
- Deine Daten liegen auf dem Gerät. Nur bei geteilten Gruppen liegen die Gruppendaten auf einem Server in Frankfurt (EU)
- Absturzberichte nur, wenn du sie erlaubst
- "Alle meine Daten löschen" jederzeit in den Einstellungen

Kostenlos. Gebaut von einer einzelnen Person, ohne Anzeigen.
```

## Listing: English

| Field | Text | Chars |
|---|---|---|
| Subtitle | Split ride costs fairly | 23 |
| Promotional text | Who drove, who pays, who owes whom? mitlio splits ride costs and group expenses fairly. No ads, no tracking. | 108 |
| Keywords | carpool,fuel cost,mileage,commute,trip,expenses,split,roommates,debts,passengers,settle,shared | 94 |

Description: same structure as the German text, translated. Write it in the language the app UI uses (du-form equivalent: plain, friendly).

## What is in this release

Sync is gated: it only runs when `app/config/prod.json` carries a Supabase URL (and the privacy text for server-stored group data is rendered, `docs/release.md`). The first upload (build 2) has an empty URL, so the app contacts none of our servers; fuel prices come straight from the public EU Commission file. **Submit the listing text above with or without the "Gruppen per Einladungslink" line to match what the submitted build really does.**

## App Privacy ("nutrition label") answers

Apple's question: "Do you or your third-party partners collect data from this app?" Answer for the build that has sync on (prod Supabase). Without sync, only the first row applies, and even that is optional.

| Data type | Collected? | Linked to identity | Used for tracking | Purpose | Why |
|---|---|---|---|---|---|
| Crash data, performance data | Yes, only if the user opts in (Sentry) | No | No | App functionality | Opt-in crash reports (processor Sentry, EU region); no user id attached |
| User ID | Yes (sync only) | Yes | No | App functionality | random anonymous Supabase account id, no email or name |
| Other user content | Yes (sync only) | Yes | No | App functionality | group content: member names, expenses, rides, settlements, optional PayPal.Me name, masked IBAN hint |
| Name | Yes (sync only) | Yes | No | App functionality | names of members typed into a group (can be real names, also of non-users) |
| Coarse location | **OWNER decision** | No | No | App functionality | Only after an explicit tap, rounded to about 1 km, sent to our fuel-price function, not stored. Apple counts data as collected unless it is processed only in real time and not retained; the conservative answer is "Coarse Location, not linked, not tracking, app functionality". |
| Search history / other | **OWNER decision** | No | No | App functionality | route lookup text goes through our proxy to the routing provider and is not stored; same real-time reasoning as location |

Everything else: **not collected** (contacts, financial info, health, browsing history, identifiers for advertising, purchases, diagnostics beyond opt-in crashes).
**Tracking: No.** No ad, analytics or attribution SDK exists in the app (repo rule), so no App Tracking Transparency prompt is needed.
Note: IBAN and bank details stay on the device (`local_member_bank`, `local_profile_bank`); only a masked hint syncs. Full IBAN is never "collected".

## Other App Store Connect fields

- **Price:** Free. **Availability:** start with Germany, Austria, Switzerland (DE speaking), add the EU later (**OWNER**).
- **Age rating:** answer "None" to every content question: 4+. No user-generated content shown to strangers (groups are invite-only), no web browsing, no gambling.
- **Export compliance:** `ITSAppUsesNonExemptEncryption=false` is already in Info.plist (standard HTTPS only).
- **Content rights:** the app uses third-party data (EU Weekly Oil Bulletin, OpenStreetMap via openrouteservice or Geoapify, Frankfurter FX rates), all credited in the app. Answer "yes, I have the rights" and keep the credits visible.
- **Account deletion (guideline 5.1.1(v)):** there are no email accounts. "Alle meine Daten löschen" in Settings removes local data and the anonymous session (`docs/data-deletion.md`). Mention this in the review notes.
- **Sign in with Apple:** not required, because there is no third-party login.
- **Location purpose string** (already in Info.plist): "Um Spritpreise in deiner Nähe zu zeigen."
- **App Review notes:** no login needed. How to test: open the app, enter a ride (distance 100 km, price 1,80 €, 3 people) and see the result; open Settings to see the data deletion. Fuel price chips need no permission; "in der Nähe" asks for location once. Say that sync groups use anonymous accounts created on first share.
- **Review contact:** owner's phone and email (**OWNER**).

## Screenshots (required: 6.9" iPhone; 6.5" is optional if 6.9" is supplied)

Suggested five, in German: 1. ride result with fuel chips, 2. trip with monthly "Abrechnen", 3. group expenses with split, 4. balances: who owes whom, 5. payment (PayPal.Me or QR). Caption each with one short sentence. Use realistic names and amounts; no real people.
**Icon:** `docs/brand.md` calls the current icon a v1 placeholder; the owner is expected to replace it before the store listing (**OWNER**). A 1024 x 1024 icon without transparency is needed in App Store Connect.

## Before pressing "Submit for review"

1. Privacy policy live and matching the answers above (`docs/data-flows.md` is the source; `SYNC_PRIVACY_RENDERED` true before prod Supabase goes live).
2. Mailboxes contact@mitlio.de and privacy@mitlio.de exist (the pages name them).
3. TestFlight build smoke-tested on a real iPhone.
4. Run `docs/release.md` gates.
