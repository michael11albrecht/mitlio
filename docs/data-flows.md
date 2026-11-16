# Data flows (draft input for the privacy policy)

Plain-language list of what leaves the device and where it goes. The owner writes the privacy policy
(P7-T07); see also `docs/data-deletion.md`. Keep this file current when a flow is added.

## Fuel prices (chips in the ride and trip form)

| Case | What the device contacts | What is sent | What the recipient can see |
|---|---|---|---|
| No backend configured (current default) | `energy.ec.europa.eu` (European Commission), HTTPS GET of the public EU Weekly Oil Bulletin file | nothing but the request itself: no account, no key, no location, no ride or group data | the device's IP address and user agent, as for any download |
| Backend configured | our Supabase `fuel-prices` Edge Function | fuel type; postcode or position rounded to about 1 km only after the user's explicit tap | see `docs/fuel-prices-api.md` (server side) |

Notes for the policy text:

- Source credit shown in the app: "Quelle: EU Weekly Oil Bulletin (Europäische Kommission)".
- The device stores the last downloaded prices in a local file (no personal data) to work offline and to avoid
  downloading more than every 12 hours. Deleting the app deletes it.
- No cookies, no identifiers, no tracking SDKs involved.
- `web/src/i18n/legal.ts` (PR #124) is not on `main` yet; once merged, add one sentence there: "Für den
  Kraftstoffpreis (Bundesdurchschnitt) ruft die App ohne Server eine öffentliche Datei der Europäischen Kommission
  (energy.ec.europa.eu) ab; dabei ist deine IP-Adresse für die Kommission sichtbar, es werden keine personenbezogenen
  Daten übertragen."

## Route distance (start and destination in the ride and trip form)

Optional: the user opens "Start und Ziel eingeben, Strecke berechnen". Only with a configured backend; without it
the forms have only the manual kilometre field and nothing is sent.

| What the device contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase `route-distance` Edge Function (POST, JSON body) | the text the user typed (from 3 characters, after a 300 ms pause), then the coordinates of the two places the user picked | the proxy forwards them to openrouteservice (HeiGIT, Germany) or, as fallback, Geoapify; those providers see the text/coordinates and the proxy's server address, never the user's IP address or id |

Notes for the policy text:

- Start and destination are personal data (they can reveal home and work). They are **not stored** anywhere on the
  server side: no logs of query text or coordinates, no cache. The proxy keeps only a salted hash of the user id (or
  address) and a counter for rate limiting. What the two providers keep is governed by their terms (DPA to check).
- On the ride only the **distance** is stored (as before). The place labels are never synced to the group.
- Saved places ("Zuhause", "Arbeit": label and coordinates) stay on the device in the local-only table
  `local_places`; they are never synced and are removed by "Alle meine Daten löschen" (`docs/data-deletion.md`).
- Suggestions need no location permission and no GPS.
- Provider data credit shown in the app: "Karten- und Routendaten © OpenStreetMap-Mitwirkende, via openrouteservice"
  (or "via Geoapify").
- No cookies, no identifiers, no tracking SDKs involved. API: `docs/route-distance-api.md`.

## Contact form (website, `/kontakt/` and `/en/contact/`)

Second contact channel next to `contact@mitlio.de` (Impressum). Web only; the app has no contact form. Without a
configured backend the page shows only the e-mail address and sends nothing.

| What the browser contacts | What is sent | What the recipient can see |
|---|---|---|
| our Supabase `contact` Edge Function (POST, JSON body) | the text the user typed: optional name, e-mail address, message, page language | the function forwards it as one e-mail through Resend (EU region, sending domain mitlio.de) to our mailbox; Resend sees the mail and processes it as our processor (DPA to sign); the browser's IP address is seen by Supabase as for any request |

Notes for the policy text:

- **Nothing is stored by the function**: no database rows, no logs of message, e-mail, name or IP. The only server-side
  trace is a salted hash of the IP and a counter in `rate_limits` (5 messages per hour), deleted after a day.
- The message ends up in our mailbox and with the e-mail providers involved; the owner decides retention there.
- Purpose and legal basis: answering the request (Art. 6(1)(b) or (f) GDPR). The honeypot field is not personal data.
- No cookies, no identifiers, no third-party scripts on the page. API: `docs/contact-api.md`.
