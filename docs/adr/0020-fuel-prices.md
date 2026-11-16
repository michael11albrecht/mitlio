# ADR-20: Fuel prices

- **Status:** accepted
- **Date:** 2026-11-13

## Decision

Germany: **Tankerkönig API** (MTS-K data, CC BY 4.0, free API key) proxied + cached by a Supabase Edge Function; Austria: E-Control Spritpreisrechner API; elsewhere: EU Weekly Oil Bulletin national averages; EV: manual kWh price with a sensible default. Client never sees API keys; attribution shown

## Rationale

Live clickable prices are the core differentiator; caching keeps us inside provider rate limits and terms

## Revisit when

Verify terms + limits in P1-T01 spike before building

## Amendment 2026-11-15: direct EU source in the app

- **Status:** accepted (owner decision)
- **Context:** the backend is not deployed, so the app (chips hidden without `SUPABASE_URL`) showed no prices at all. The owner considers the national average enough for now.
- **Decision:** without a configured backend the app reads the national average (Germany) directly from the public EU Weekly Oil Bulletin (prices with taxes, XLSX, no key, no location): Euro-super 95 is E5, Automotive gas oil is Diesel, E10 is the E5 value marked "≈" (as in the Edge Function). Parsing is a Dart port of `supabase/functions/_shared/oil_bulletin.ts` without a new dependency (`dart:io` `ZLibCodec` for the zip). The quote is stored in a file on the device and not refetched within 12 h; offline the last file is shown with its date. With a backend configured the Edge Function stays the source and keeps nearby/postcode (Tankerkönig). Without a backend, "in meiner Nähe" and postcode are hidden.
- **Consequences:** the device contacts `energy.ec.europa.eu` over HTTPS (IP address visible to the European Commission, nothing else sent) and the privacy policy must say so. If the bulletin file layout changes, the app shows no price until the parser is updated (the same risk as the Edge Function).
