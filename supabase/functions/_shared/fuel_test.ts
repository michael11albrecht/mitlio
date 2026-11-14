import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert@1.0.8";
import {
  allowedOrigin,
  cacheKey,
  type CacheRow,
  clientIp,
  constantTimeEquals,
  corsHeaders,
  geohashCenter,
  geohashEncode,
  hashClient,
  isFresh,
  median,
  NATIONAL_SAMPLE,
  nationalStep,
  openStationPrices,
  parseStationList,
  plzCoordinate,
  pricesFromStations,
  providerArea,
  shapeResponse,
  snapToCell,
  summarize,
  toPriceMilli,
  TTL_SECONDS,
  validateParams,
} from "./fuel.ts";

const q = (s: string) => validateParams(new URLSearchParams(s));

Deno.test("validateParams: national, nearby, plz", () => {
  assertEquals(q("type=e5"), { type: "e5", scope: "national" });
  assertEquals(q("type=diesel&lat=52.52&lng=13.405&radius=7"), {
    type: "diesel",
    scope: "nearby",
    lat: 52.52,
    lng: 13.405,
    radius: 7,
  });
  assertEquals(q("type=e10&lat=-33&lng=-70.5"), {
    type: "e10",
    scope: "nearby",
    lat: -33,
    lng: -70.5,
    radius: 5,
  });
  assertEquals(q("type=e10&plz=10115"), { type: "e10", scope: "plz", plz: "10115" });
  assertEquals((q("type=e5&lat=1&lng=1&radius=2.6") as { radius: number }).radius, 3);
  assertEquals((q("type=e5&lat=1&lng=1&radius=1") as { radius: number }).radius, 1);
  assertEquals((q("type=e5&lat=1&lng=1&radius=10") as { radius: number }).radius, 10);
  assertEquals((q("type=e5&lat=90&lng=180") as { lat: number }).lat, 90);
  assertEquals((q("type=e5&lat=-90&lng=-180") as { lat: number }).lat, -90);
});

Deno.test("validateParams: rejects invalid input", () => {
  const bad = [
    "",
    "type=lpg",
    "type=E5",
    "type=e5&lat=52",
    "type=e5&lng=13",
    "type=e5&lat=abc&lng=13",
    "type=e5&lat=91&lng=0",
    "type=e5&lat=0&lng=181",
    "type=e5&lat=1e1&lng=0",
    "type=e5&lat=&lng=0",
    "type=e5&lat=1&lng=1&radius=0.9",
    "type=e5&lat=1&lng=1&radius=11",
    "type=e5&lat=1&lng=1&radius=x",
    "type=e5&radius=5",
    "type=e5&plz=1011",
    "type=e5&plz=101155",
    "type=e5&plz=1011a",
    "type=e5&plz=05123",
    "type=e5&plz=10115&lat=1&lng=1",
    "type=e5&plz=10115&lat=1",
    "type=e5&plz=10115&lng=1",
    "type=e5&plz=10115&radius=5",
  ];
  for (const s of bad) assertEquals(q(s), null, s);
});

Deno.test("geohash: known vectors and round trip", () => {
  assertEquals(geohashEncode(57.64911, 10.40744, 11), "u4pruydqqvj");
  assertEquals(geohashEncode(52.52, 13.405), "u33dc0");
  assertEquals(geohashEncode(-33.8688, 151.2093), "r3gx2f");
  const c = geohashCenter("u33dc0");
  assertEquals(geohashEncode(c.lat, c.lng), "u33dc0");
  assertEquals(geohashEncode(0, 0, 1), "s");
});

Deno.test("snapToCell: exact location is not recoverable, same cell for nearby points", () => {
  const a = snapToCell(52.520008, 13.404954);
  const b = snapToCell(52.5201, 13.4051);
  assertEquals(a, b);
  assertNotEquals(a.lat, 52.520008);
  assertNotEquals(a.lng, 13.404954);
  assert(Math.abs(a.lat - 52.520008) < 0.01 && Math.abs(a.lng - 13.404954) < 0.01);
  assertEquals(String(a.lat).split(".")[1].length <= 5, true);
  assertNotEquals(snapToCell(52.55, 13.4).hash, a.hash);
});

Deno.test("plzCoordinate and national sample", () => {
  assertEquals(plzCoordinate("10115"), { lat: 52.52, lng: 13.4 });
  assertEquals(plzCoordinate("99999"), { lat: 50.98, lng: 11.03 });
  assertEquals(plzCoordinate("01000"), { lat: 51.05, lng: 13.74 });
  for (const zone of ["05", "11", "43", "62"]) assertEquals(plzCoordinate(zone + "000"), null);
  assertEquals(NATIONAL_SAMPLE.length, 16);
});

Deno.test("cacheKey and providerArea never use exact coordinates", () => {
  const near = q("type=e5&lat=52.520008&lng=13.404954&radius=3")!;
  if (near.scope !== "nearby") throw new Error("scope");
  assertEquals(cacheKey(near), { scope: "nearby", scopeKey: "u33dc0:3" });
  const area = providerArea(near);
  assertEquals(area.radius, 3);
  assertNotEquals(area.lat, 52.520008);
  assertNotEquals(area.lng, 13.404954);
  assertEquals(cacheKey(q("type=e5&plz=10115")!), { scope: "plz", scopeKey: "10115" });
  assertEquals(cacheKey(q("type=e5")!), { scope: "national", scopeKey: "de" });
  const plz = q("type=e5&plz=80331")!;
  if (plz.scope !== "plz") throw new Error("scope");
  assertEquals(providerArea(plz), { lat: 48.14, lng: 11.58, radius: 10 });
});

Deno.test("median", () => {
  assertEquals(median([]), null);
  assertEquals(median([5]), 5);
  assertEquals(median([3, 1, 2]), 2);
  assertEquals(median([1700, 1800]), 1750);
  assertEquals(median([1700, 1701]), 1701);
  assertEquals(median([4, 1, 3, 2]), 3);
  const input = [3, 1, 2];
  median(input);
  assertEquals(input, [3, 1, 2]);
});

Deno.test("toPriceMilli", () => {
  assertEquals(toPriceMilli(1.799), 1799);
  assertEquals(toPriceMilli(1.8), 1800);
  assertEquals(toPriceMilli(0.5), 500);
  assertEquals(toPriceMilli(5), 5000);
  assertEquals(toPriceMilli(0.499), null);
  assertEquals(toPriceMilli(5.001), null);
  assertEquals(toPriceMilli(false), null);
  assertEquals(toPriceMilli(null), null);
  assertEquals(toPriceMilli("1.8"), null);
  assertEquals(toPriceMilli(NaN), null);
  assertEquals(toPriceMilli(Infinity), null);
});

Deno.test("parseStationList", () => {
  assertEquals(parseStationList(null), null);
  assertEquals(parseStationList("x"), null);
  assertEquals(parseStationList({ ok: false, stations: [] }), null);
  assertEquals(parseStationList({ ok: true }), null);
  assertEquals(parseStationList({ ok: true, stations: "x" }), null);
  assertEquals(parseStationList({ ok: true, stations: [{ a: 1 }, null, 3] }), [{ a: 1 }]);
});

const stations = [
  { e5: 1.8, e10: 1.74, diesel: 1.6, isOpen: true },
  { e5: 1.9, e10: false, diesel: 1.7, isOpen: true },
  { e5: 1.5, e10: 1.5, diesel: 1.5, isOpen: false },
  { e5: null, e10: 1.76, diesel: 1.65, isOpen: true },
  { e5: 1.85, e10: 1.8, diesel: "x", isOpen: "true" },
];

Deno.test("openStationPrices / pricesFromStations / summarize", () => {
  assertEquals(openStationPrices(stations, "e5"), [1800, 1900]);
  assertEquals(openStationPrices(stations, "e10"), [1740, 1760]);
  assertEquals(openStationPrices(stations, "diesel"), [1600, 1700, 1650]);
  const s = summarize(pricesFromStations(stations));
  assertEquals(s.e5, { priceMilli: 1850, stations: 2 });
  assertEquals(s.e10, { priceMilli: 1750, stations: 2 });
  assertEquals(s.diesel, { priceMilli: 1650, stations: 3 });
  assertEquals(summarize({ e5: [], e10: [], diesel: [] }), { e5: null, e10: null, diesel: null });
});

Deno.test("isFresh and TTLs", () => {
  assertEquals(TTL_SECONDS, { nearby: 600, plz: 1800, national: 3600, bulletin: 43200 });
  assert(isFresh(1000, 1000, 10));
  assert(isFresh(0, 9999, 10));
  assert(!isFresh(0, 10000, 10));
  assert(!isFresh(2000, 1000, 10));
});

Deno.test("nationalStep", () => {
  const base = { hasKey: true, providerFresh: true, bulletinFresh: true, force: false };
  assertEquals(nationalStep(base), "serve_provider");
  assertEquals(nationalStep({ ...base, providerFresh: false }), "fetch_provider");
  assertEquals(nationalStep({ ...base, force: true }), "fetch_provider");
  assertEquals(nationalStep({ ...base, hasKey: false }), "serve_bulletin");
  assertEquals(nationalStep({ ...base, hasKey: false, bulletinFresh: false }), "fetch_bulletin");
  assertEquals(nationalStep({ ...base, hasKey: false, force: true }), "fetch_bulletin");
  assertEquals(nationalStep({ ...base, hasKey: false, providerFresh: false }), "serve_bulletin");
});

Deno.test("shapeResponse", () => {
  const row: CacheRow = {
    type: "e5",
    scope: "nearby",
    scope_key: "u33dc0:5",
    price_milli: 1799,
    stations: 12,
    fetched_at: "2026-11-14T10:00:00+00:00",
    source: "tankerkoenig",
    observed_at: null,
    approximation: null,
  };
  assertEquals(shapeResponse(row), {
    type: "e5",
    priceMilli: 1799,
    source: "tankerkoenig",
    scope: "nearby",
    fetchedAt: "2026-11-14T10:00:00.000Z",
    stations: 12,
    attribution: "Daten: MTS-K via Tankerkönig (CC BY 4.0)",
  });
  const b = shapeResponse({
    ...row,
    scope: "national",
    source: "eu-oil-bulletin",
    observed_at: "2026-11-09T00:00:00Z",
    approximation: "e5",
  });
  assertEquals(b.fetchedAt, "2026-11-09T00:00:00.000Z");
  assertEquals(b.approximation, "e5");
  assertEquals(b.attribution, "Quelle: EU Weekly Oil Bulletin");
});

Deno.test("cors", () => {
  const list = "https://mitlio.app, https://www.mitlio.app,";
  assertEquals(allowedOrigin("https://mitlio.app", list), "https://mitlio.app");
  assertEquals(allowedOrigin("https://www.mitlio.app", list), "https://www.mitlio.app");
  assertEquals(allowedOrigin("https://evil.example", list), null);
  assertEquals(allowedOrigin(null, list), null);
  assertEquals(allowedOrigin("https://mitlio.app", ""), null);
  assertEquals(allowedOrigin("", "https://mitlio.app"), null);
  assertEquals(corsHeaders("https://evil.example", list), {});
  const h = corsHeaders("https://mitlio.app", list);
  assertEquals(h["Access-Control-Allow-Origin"], "https://mitlio.app");
  assertEquals(h["Vary"], "Origin");
  assertEquals(h["Access-Control-Allow-Methods"], "GET, OPTIONS");
});

Deno.test("clientIp, hashClient, constantTimeEquals", async () => {
  assertEquals(clientIp(new Headers({ "cf-connecting-ip": " 1.2.3.4 " })), "1.2.3.4");
  assertEquals(
    clientIp(new Headers({ "x-forwarded-for": "5.6.7.8, 10.0.0.1", "cf-connecting-ip": "" })),
    "5.6.7.8",
  );
  assertEquals(clientIp(new Headers()), "unknown");
  const h = await hashClient("1.2.3.4", "salt");
  assertEquals(h.length, 64);
  assert(/^[0-9a-f]+$/.test(h));
  assert(!h.includes("1.2.3.4"));
  assertEquals(h, await hashClient("1.2.3.4", "salt"));
  assertNotEquals(h, await hashClient("1.2.3.4", "other"));
  assertNotEquals(h, await hashClient("1.2.3.5", "salt"));
  assert(constantTimeEquals("abc", "abc"));
  assert(!constantTimeEquals("abc", "abd"));
  assert(!constantTimeEquals("abc", "ab"));
  assert(constantTimeEquals("", ""));
});
