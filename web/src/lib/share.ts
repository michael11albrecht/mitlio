// Share text and links for the calculator result. Pure and DOM-free.
// Result first: "Fahrtkosten: 4 Personen, je 18,20 € (Gesamt 72,80 €) — berechnet mit mitlio <url>".
import { calculatorMessages } from '../i18n/calculator';
import { fill, formatMoney, sanitizeTripName, type Locale } from '../calculator/core';

export interface ShareInput {
  locale: Locale;
  /** People who pay (passengers only when the driver does not pay). */
  payers: number;
  /** True when the driver pays nothing, so the payers are passengers. */
  passengersOnly: boolean;
  /** Share per paying person in cents (the larger one when rounding splits). */
  perPersonCents: number;
  /** True when shares differ by cent rounding. */
  rounded: boolean;
  totalCents: number;
  /** Optional trip name; replaces the generic lead. */
  trip?: string;
  /** Link carrying the calculator state. */
  url: string;
}

export function buildShareText(input: ShareInput): string {
  const m = calculatorMessages[input.locale];
  const who = input.passengersOnly
    ? fill(m.shareWhoPassengers, { n: input.payers })
    : input.payers === 1
      ? m.shareWhoOne
      : fill(m.shareWhoMany, { n: input.payers });
  const summary = fill(input.rounded ? m.shareSummaryRounded : m.shareSummary, {
    who,
    each: formatMoney(input.perPersonCents, input.locale),
    total: formatMoney(input.totalCents, input.locale),
  });
  const lead = sanitizeTripName(input.trip ?? '') || m.shareLead;
  return `${lead}: ${summary} — ${m.shareFooter} ${input.url}`;
}

/** WhatsApp click-to-chat link. No tracking parameters. */
export function whatsappHref(text: string): string {
  return `https://wa.me/?text=${encodeURIComponent(text)}`;
}
