import { assertEquals } from "jsr:@std/assert@1.0.8";
import {
  ATTRIBUTION,
  type FxRow,
  isIsoDay,
  isoDay,
  isUsable,
  keyDate,
  LATEST_TTL_SECONDS,
  parseFrankfurter,
  providerPath,
  type Query,
  rateToPpm,
  shapeResponse,
  toRow,
  validateParams,
} from "./fx.ts";

const NOW = Date.parse("2025-11-17T10:00:00Z");
const p = (q: string) => validateParams(new URLSearchParams(q), NOW);

Deno.test("isoDay and isIsoDay", () => {
  assertEquals(isoDay(NOW), "2025-11-17");
  assertEquals(isIsoDay("2025-11-17"), true);
  assertEquals(isIsoDay("2024-02-29"), true);
  assertEquals(isIsoDay("2025-02-29"), false);
  assertEquals(isIsoDay("2025-13-01"), false);
  assertEquals(isIsoDay("2025-1-01"), false);
  assertEquals(isIsoDay("2025-11-17T00:00"), false);
  assertEquals(isIsoDay(""), false);
});

Deno.test("validateParams: base and quote", () => {
  assertEquals(p("base=USD&quote=EUR"), { base: "USD", quote: "EUR", date: null });
  assertEquals(p("base=USD"), null);
  assertEquals(p("quote=EUR"), null);
  assertEquals(p(""), null);
  assertEquals(p("base=usd&quote=EUR"), null);
  assertEquals(p("base=USD&quote=EURO"), null);
  assertEquals(p("base=US&quote=EUR"), null);
  assertEquals(p("base=U1D&quote=EUR"), null);
  assertEquals(p("base=USD&quote=USD"), null);
});

Deno.test("validateParams: date", () => {
  assertEquals(p("base=USD&quote=EUR&date=2025-11-15"), {
    base: "USD",
    quote: "EUR",
    date: "2025-11-15",
  });
  assertEquals(p("base=USD&quote=EUR&date=1999-01-04")?.date, "1999-01-04");
  assertEquals(p("base=USD&quote=EUR&date=1999-01-03"), null);
  assertEquals(p("base=USD&quote=EUR&date=2025-11-18"), null, "future");
  assertEquals(p("base=USD&quote=EUR&date=2025-11-17")?.date, null, "today is latest");
  assertEquals(p("base=USD&quote=EUR&date=2025-02-30"), null);
  assertEquals(p("base=USD&quote=EUR&date=yesterday"), null);
  assertEquals(p("base=USD&quote=EUR&date="), null);
});

Deno.test("keyDate", () => {
  assertEquals(keyDate({ base: "USD", quote: "EUR", date: null }, NOW), "2025-11-17");
  assertEquals(keyDate({ base: "USD", quote: "EUR", date: "2025-11-15" }, NOW), "2025-11-15");
});

Deno.test("rateToPpm rounds half away from zero to a whole ppm", () => {
  assertEquals(rateToPpm(0.92), 920000);
  assertEquals(rateToPpm(1), 1000000);
  assertEquals(rateToPpm(1.0869565), 1086957);
  assertEquals(rateToPpm(0.8651234), 865123);
  assertEquals(rateToPpm(0.8651235), 865124);
  assertEquals(rateToPpm(0.0058), 5800);
  assertEquals(rateToPpm(0.0000015), 2);
  assertEquals(rateToPpm(1_000_000), 1_000_000_000_000);
});

Deno.test("rateToPpm rejects unusable values", () => {
  assertEquals(rateToPpm(0), null);
  assertEquals(rateToPpm(-0.5), null);
  assertEquals(rateToPpm(0.0000001), null, "rounds to 0 ppm");
  assertEquals(rateToPpm(1_000_000.5), null);
  assertEquals(rateToPpm(Number.NaN), null);
  assertEquals(rateToPpm(Infinity), null);
  assertEquals(rateToPpm("0.92"), null);
  assertEquals(rateToPpm(null), null);
  assertEquals(rateToPpm(undefined), null);
});

const q: Query = { base: "USD", quote: "EUR", date: null };
const body = { amount: 1, base: "USD", date: "2025-11-14", rates: { EUR: 0.92 } };

Deno.test("parseFrankfurter", () => {
  assertEquals(parseFrankfurter(body, q), { ppm: 920000, sourceDate: "2025-11-14" });
  assertEquals(parseFrankfurter(null, q), null);
  assertEquals(parseFrankfurter("x", q), null);
  assertEquals(parseFrankfurter({ ...body, base: "GBP" }, q), null, "other base");
  assertEquals(parseFrankfurter({ ...body, date: "14.11.2025" }, q), null);
  assertEquals(parseFrankfurter({ ...body, date: 20251114 }, q), null);
  assertEquals(parseFrankfurter({ ...body, rates: null }, q), null);
  assertEquals(parseFrankfurter({ ...body, rates: "EUR" }, q), null);
  assertEquals(parseFrankfurter({ ...body, rates: { GBP: 0.9 } }, q), null, "other quote");
  assertEquals(parseFrankfurter({ ...body, rates: { EUR: 0 } }, q), null);
  assertEquals(parseFrankfurter({ ...body, rates: { EUR: "0.92" } }, q), null);
});

Deno.test("providerPath", () => {
  assertEquals(providerPath(q), "latest?from=USD&to=EUR");
  assertEquals(providerPath({ ...q, date: "2025-11-15" }), "2025-11-15?from=USD&to=EUR");
});

const row = (over: Partial<FxRow> = {}): FxRow => ({
  base: "USD",
  quote: "EUR",
  date: "2025-11-17",
  rate_ppm: 920000,
  source_date: "2025-11-14",
  fetched_at: "2025-11-17T09:00:00.000Z",
  ...over,
});

Deno.test("isUsable: latest needs today's key and a fresh fetch", () => {
  assertEquals(isUsable(row(), q, NOW), true);
  assertEquals(isUsable(row({ date: "2025-11-16" }), q, NOW), false, "yesterday's key");
  const edge = Date.parse("2025-11-17T09:00:00Z") + LATEST_TTL_SECONDS * 1000;
  assertEquals(isUsable(row(), q, edge - 1), true);
  assertEquals(isUsable(row(), q, edge), false, "expired exactly at the TTL");
});

Deno.test("isUsable: a past day is served as long as the key matches", () => {
  const dated: Query = { ...q, date: "2025-11-15" };
  assertEquals(
    isUsable(row({ date: "2025-11-15", fetched_at: "2025-11-15T09:00:00Z" }), dated, NOW),
    true,
  );
  assertEquals(isUsable(row({ date: "2025-11-14" }), dated, NOW), false);
});

Deno.test("shapeResponse and toRow", () => {
  assertEquals(shapeResponse(row()), {
    base: "USD",
    quote: "EUR",
    date: "2025-11-14",
    ratePpm: 920000,
    source: "frankfurter",
    fetchedAt: "2025-11-17T09:00:00.000Z",
    attribution: ATTRIBUTION,
  });
  assertEquals(ATTRIBUTION, "Quelle: EZB-Referenzkurse via Frankfurter");
  assertEquals(
    toRow(q, { ppm: 920000, sourceDate: "2025-11-14" }, Date.parse("2025-11-17T09:00:00Z")),
    row(),
  );
  assertEquals(
    toRow({ ...q, date: "2025-11-15" }, { ppm: 5, sourceDate: "2025-11-14" }, NOW).date,
    "2025-11-15",
  );
});
