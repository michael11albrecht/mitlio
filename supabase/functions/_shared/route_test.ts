import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.8";
import {
  type Bucket,
  bucketsFor,
  clientIp,
  corsHeaders,
  type Deps,
  type Fetch,
  geoapifyProvider,
  handleRoute,
  hashClient,
  jwtSubject,
  orsProvider,
  parseGeoapifySuggestions,
  parseOrsSuggestions,
  ProviderError,
  secondsToUtcMidnight,
  selectProviders,
  validateRequest,
} from "./route.ts";

const NOW = Date.parse("2026-11-15T23:30:00Z");

const orsSuggest = {
  features: [
    { geometry: { coordinates: [8.4037, 49.0069] }, properties: { label: "Karlsruhe, BW" } },
    { geometry: { coordinates: [8.4037, 49.0069] }, properties: { label: "Karlsruhe, BW" } },
    { geometry: { coordinates: ["x", 1] }, properties: { label: "Bad" } },
    { geometry: { coordinates: [1, 2] }, properties: { label: "  " } },
    { geometry: { coordinates: [9.1829, 48.7758] }, properties: { label: "Stuttgart,\n BW" } },
  ],
};
const geoSuggest = {
  features: [
    { properties: { formatted: "Karlsruhe, Germany", lat: 49.0069, lon: 8.4037 } },
    { properties: { formatted: "no coords" } },
  ],
};

const jsonRes = (body: unknown, status = 200) => Response.json(body, { status });

/** A fetch that answers by URL substring and records what it saw. */
function stubFetch(
  routes: Record<string, () => Response | Promise<Response>>,
  seen: { url: string; init?: RequestInit }[] = [],
): Fetch {
  return (url, init) => {
    seen.push({ url, init });
    for (const [needle, answer] of Object.entries(routes)) {
      if (url.includes(needle)) return Promise.resolve(answer());
    }
    return Promise.reject(new Error(`unexpected ${url}`));
  };
}

// ---------------------------------------------------------------------------

Deno.test("validateRequest: suggest", () => {
  assertEquals(validateRequest({ action: "suggest", text: "  Karls   ruhe " }), {
    action: "suggest",
    text: "Karls ruhe",
    lang: "de",
  });
  assertEquals(validateRequest({ action: "suggest", text: "Bonn", lang: "en" })?.action, "suggest");
  assertEquals(validateRequest({ action: "suggest", text: "ab" }), null);
  assertEquals(validateRequest({ action: "suggest", text: "a".repeat(121) }), null);
  assertEquals(validateRequest({ action: "suggest", text: "a".repeat(120) })?.action, "suggest");
  assertEquals(validateRequest({ action: "suggest", text: "abc\u0000" }), null);
  assertEquals(validateRequest({ action: "suggest", text: "ab\u007f" }), null);
  assertEquals(validateRequest({ action: "suggest", text: 5 }), null);
  assertEquals(validateRequest({ action: "suggest" }), null);
  // three code points, two UTF-16 units each: still three characters
  assertEquals(validateRequest({ action: "suggest", text: "😀😀😀" })?.action, "suggest");
});

Deno.test("validateRequest: distance", () => {
  const ok = { action: "distance", from: { lat: 49, lng: 8 }, to: { lat: -90, lng: 180, x: 1 } };
  assertEquals(validateRequest(ok), {
    action: "distance",
    from: { lat: 49, lng: 8 },
    to: { lat: -90, lng: 180 },
  });
  assertEquals(validateRequest({ ...ok, from: { lat: 91, lng: 0 } }), null);
  assertEquals(validateRequest({ ...ok, from: { lat: 0, lng: -181 } }), null);
  assertEquals(validateRequest({ ...ok, to: { lat: NaN, lng: 0 } }), null);
  assertEquals(validateRequest({ ...ok, to: { lat: "1", lng: 0 } }), null);
  assertEquals(validateRequest({ ...ok, to: null }), null);
  assertEquals(validateRequest({ ...ok, from: 3 }), null);
  assertEquals(validateRequest({ action: "distance" }), null);
});

Deno.test("validateRequest: shapes and unknown actions", () => {
  assertEquals(validateRequest(null), null);
  assertEquals(validateRequest([]), null);
  assertEquals(validateRequest("suggest"), null);
  assertEquals(validateRequest({ action: "geocode", text: "abc" }), null);
  assertEquals(validateRequest({}), null);
});

Deno.test("parsers: dedupe, clean, cap at five, reject non-lists", () => {
  assertEquals(parseOrsSuggestions(orsSuggest), [
    { label: "Karlsruhe, BW", lat: 49.0069, lng: 8.4037 },
    { label: "Stuttgart, BW", lat: 48.7758, lng: 9.1829 },
  ]);
  assertEquals(parseGeoapifySuggestions(geoSuggest), [
    { label: "Karlsruhe, Germany", lat: 49.0069, lng: 8.4037 },
  ]);
  const many = {
    features: Array.from({ length: 9 }, (_, i) => ({
      geometry: { coordinates: [i, i] },
      properties: { label: `Ort ${i}`, formatted: `Ort ${i}`, lat: i, lon: i },
    })),
  };
  assertEquals(parseOrsSuggestions(many).length, 5);
  assertEquals(parseGeoapifySuggestions(many).length, 5);
  assertEquals(parseOrsSuggestions({ features: [] }), []);
  assertEquals(
    parseOrsSuggestions({
      features: [{ geometry: { coordinates: [1, 2] }, properties: { label: "x".repeat(300) } }],
    })[0].label.length,
    160,
  );
  for (const bad of [null, {}, { features: "x" }]) {
    assertEquals(throwsKind(() => parseOrsSuggestions(bad)), "unavailable");
    assertEquals(throwsKind(() => parseGeoapifySuggestions(bad)), "unavailable");
  }
});

function throwsKind(fn: () => unknown): string | null {
  try {
    fn();
    return null;
  } catch (e) {
    return e instanceof ProviderError ? e.kind : "other";
  }
}

// ---------------------------------------------------------------------------
// Adapters

Deno.test("ors adapter: suggest builds the request and parses", async () => {
  const seen: { url: string; init?: RequestInit }[] = [];
  const p = orsProvider(
    "KEY",
    stubFetch({ "/geocode/autocomplete": () => jsonRes(orsSuggest) }, seen),
  );
  assertEquals((await p.suggest("Karls ruhe&x", "en")).length, 2);
  const { url, init } = seen[0];
  assertEquals(
    url.startsWith("https://api.openrouteservice.org/geocode/autocomplete?size=5"),
    true,
  );
  assertEquals(url.includes("lang=en"), true);
  assertEquals(url.includes("text=Karls%20ruhe%26x"), true);
  assertEquals((init!.headers as Record<string, string>).Authorization, "KEY");
  assertEquals(url.includes("KEY"), false);
});

Deno.test("ors adapter: distance asks for the fastest route in lng,lat order", async () => {
  const seen: { url: string; init?: RequestInit }[] = [];
  const p = orsProvider(
    "KEY",
    stubFetch({
      "/v2/directions": () => jsonRes({ routes: [{ summary: { distance: 212345.6 } }] }),
    }, seen),
    "https://ors.test",
  );
  assertEquals(await p.distance({ lat: 49, lng: 8 }, { lat: 48, lng: 9 }), 212346);
  assertEquals(seen[0].url, "https://ors.test/v2/directions/driving-car");
  assertEquals(JSON.parse(seen[0].init!.body as string), {
    coordinates: [[8, 49], [9, 48]],
    preference: "fastest",
    units: "m",
  });
});

Deno.test("ors adapter: failure mapping", async () => {
  const a = { lat: 1, lng: 1 };
  const mk = (res: () => Response) =>
    orsProvider("K", stubFetch({ "/v2/directions": res, "/geocode": res }));
  for (const status of [400, 404]) {
    await assertRejects(
      () => mk(() => jsonRes({}, status)).distance(a, a),
      ProviderError,
      `ors route status ${status}`,
    );
  }
  for (const status of [401, 429, 500, 503]) {
    const e = await assertRejects(
      () => mk(() => jsonRes({}, status)).distance(a, a),
      ProviderError,
    );
    assertEquals(e.kind, "unavailable");
    const s = await assertRejects(
      () => mk(() => jsonRes({}, status)).suggest("abc", "de"),
      ProviderError,
    );
    assertEquals(s.kind, "unavailable");
  }
  const none = await assertRejects(
    () => mk(() => jsonRes({ routes: [] })).distance(a, a),
    ProviderError,
  );
  assertEquals(none.kind, "no_route");
  for (const distance of [-1, 7_000_000, "5", null]) {
    const e = await assertRejects(
      () => mk(() => jsonRes({ routes: [{ summary: { distance } }] })).distance(a, a),
      ProviderError,
    );
    assertEquals(e.kind, distance === null ? "unavailable" : "unavailable");
  }
  const text = await assertRejects(
    () => mk(() => new Response("<html>")).distance(a, a),
    ProviderError,
  );
  assertEquals(text.kind, "unavailable");
});

Deno.test("geoapify adapter: suggest and distance", async () => {
  const seen: { url: string; init?: RequestInit }[] = [];
  const p = geoapifyProvider(
    "GKEY",
    stubFetch({
      "/v1/geocode/autocomplete": () => jsonRes(geoSuggest),
      "/v1/routing": () => jsonRes({ features: [{ properties: { distance: 98765 } }] }),
    }, seen),
  );
  assertEquals(await p.suggest("Karlsruhe", "de"), [
    { label: "Karlsruhe, Germany", lat: 49.0069, lng: 8.4037 },
  ]);
  assertEquals(await p.distance({ lat: 49, lng: 8.5 }, { lat: 48, lng: 9 }), 98765);
  assertEquals(seen[1].url.includes("waypoints=49,8.5|48,9"), true);
  assertEquals(seen[1].url.includes("type=balanced"), true);
  assertEquals(seen[1].url.includes("apiKey=GKEY"), true);
  assertEquals(p.attribution.includes("Geoapify"), true);
});

Deno.test("geoapify adapter: failure mapping", async () => {
  const a = { lat: 1, lng: 1 };
  const mk = (res: () => Response) =>
    geoapifyProvider("K", stubFetch({ "/v1/routing": res, "/v1/geocode": res }));
  for (const status of [400, 404]) {
    const e = await assertRejects(
      () => mk(() => jsonRes({}, status)).distance(a, a),
      ProviderError,
    );
    assertEquals(e.kind, "no_route");
  }
  for (const status of [401, 429, 500]) {
    const e = await assertRejects(
      () => mk(() => jsonRes({}, status)).distance(a, a),
      ProviderError,
    );
    assertEquals(e.kind, "unavailable");
    const s = await assertRejects(
      () => mk(() => jsonRes({}, status)).suggest("abc", "de"),
      ProviderError,
    );
    assertEquals(s.kind, "unavailable");
  }
  const none = await assertRejects(
    () => mk(() => jsonRes({ features: [] })).distance(a, a),
    ProviderError,
  );
  assertEquals(none.kind, "no_route");
  const bad = await assertRejects(
    () => mk(() => jsonRes({ features: [{ properties: { distance: "x" } }] })).distance(a, a),
    ProviderError,
  );
  assertEquals(bad.kind, "unavailable");
});

Deno.test("adapters: network errors never leak the query", async () => {
  const boom: Fetch = (url) => Promise.reject(new Error(`connect failed for ${url}`));
  for (const p of [orsProvider("K", boom), geoapifyProvider("K", boom)]) {
    const e = await assertRejects(() => p.suggest("Geheimstrasse 5", "de"), ProviderError);
    assertEquals(e.kind, "unavailable");
    assertEquals(e.message.includes("Geheim"), false);
  }
});

Deno.test("selectProviders: order and keys come from env", () => {
  const f: Fetch = () => Promise.reject(new Error("unused"));
  const names = (env: Record<string, string>) =>
    selectProviders((n) => env[n] ?? "", f).map((p) => p.name);
  assertEquals(names({ ORS_API_KEY: "a", GEOAPIFY_API_KEY: "b" }), [
    "openrouteservice",
    "geoapify",
  ]);
  assertEquals(names({ ORS_API_KEY: "a" }), ["openrouteservice"]);
  assertEquals(names({ GEOAPIFY_API_KEY: "b" }), ["geoapify"]);
  assertEquals(names({}), []);
  assertEquals(
    names({ ORS_API_KEY: "a", GEOAPIFY_API_KEY: "b", ROUTE_PROVIDER: "geoapify, ORS" }),
    ["geoapify", "openrouteservice"],
  );
  assertEquals(
    names({ ORS_API_KEY: "a", GEOAPIFY_API_KEY: "b", ROUTE_PROVIDER: "geoapify" }),
    ["geoapify"],
  );
  assertEquals(names({ ORS_API_KEY: "a", ROUTE_PROVIDER: "geoapify" }), []);
  assertEquals(names({ ORS_API_KEY: "a", ROUTE_PROVIDER: "nonsense,," }), []);
});

// ---------------------------------------------------------------------------
// Rate limit helpers

Deno.test("bucketsFor: per-user minute bucket then global daily budget", () => {
  const [user, global] = bucketsFor("suggest", "H", NOW, () => "");
  assertEquals(user, { key: "route:suggest:u:H", capacity: 30, refillPerSec: 0.5, retryAfter: 60 });
  assertEquals(global, {
    key: "route:suggest:global:2026-11-15",
    capacity: 1000,
    refillPerSec: 0,
    retryAfter: 1800,
  });
  const [du, dg] = bucketsFor("distance", "H", NOW, () => "");
  assertEquals([du.capacity, dg.capacity], [10, 1500]);
  const env = (n: string) =>
    ({ ROUTE_DISTANCE_PER_MIN: "6", ROUTE_DISTANCE_DAILY: "999999" })[n] ?? "";
  const [eu, eg] = bucketsFor("distance", "H", NOW, env);
  assertEquals([eu.capacity, eu.refillPerSec, eg.capacity], [6, 0.1, 10000]);
  const [su, sg] = bucketsFor(
    "suggest",
    "H",
    NOW,
    (n) => ({ ROUTE_SUGGEST_PER_MIN: "5", ROUTE_SUGGEST_DAILY: "7" })[n] ?? "",
  );
  assertEquals([su.capacity, sg.capacity], [5, 7]);
});

Deno.test("secondsToUtcMidnight", () => {
  assertEquals(secondsToUtcMidnight(Date.parse("2026-11-15T23:59:59.500Z")), 1);
  assertEquals(secondsToUtcMidnight(Date.parse("2026-11-16T00:00:00Z")), 86400);
  assertEquals(secondsToUtcMidnight(Date.parse("2026-12-31T12:00:00Z")), 43200);
});

const b64 = (o: unknown) =>
  btoa(JSON.stringify(o)).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");

Deno.test("jwtSubject", () => {
  assertEquals(jwtSubject(`Bearer h.${b64({ sub: "user-1" })}.s`), "user-1");
  assertEquals(jwtSubject(`bearer h.${b64({ role: "anon" })}.s`), null);
  assertEquals(jwtSubject(`Bearer h.${b64({ sub: "" })}.s`), null);
  assertEquals(jwtSubject(`Bearer h.${b64({ sub: 5 })}.s`), null);
  assertEquals(jwtSubject("Bearer nodots"), null);
  assertEquals(jwtSubject("Bearer h.%%%.s"), null);
  assertEquals(jwtSubject(null), null);
});

Deno.test("clientIp and hashClient", async () => {
  assertEquals(
    clientIp(new Headers({ "cf-connecting-ip": " 1.2.3.4 ", "x-forwarded-for": "9.9.9.9" })),
    "1.2.3.4",
  );
  assertEquals(clientIp(new Headers({ "x-forwarded-for": "5.6.7.8, 10.0.0.1" })), "5.6.7.8");
  assertEquals(clientIp(new Headers()), "unknown");
  const h = await hashClient("1.2.3.4", "salt");
  assertEquals(/^[0-9a-f]{64}$/.test(h), true);
  assertEquals(h === await hashClient("1.2.3.4", "other"), false);
  assertEquals(h === await hashClient("1.2.3.5", "salt"), false);
});

Deno.test("corsHeaders", () => {
  assertEquals(corsHeaders("https://a.test", ""), {});
  assertEquals(corsHeaders(null, "https://a.test"), {});
  assertEquals(corsHeaders("https://b.test", "https://a.test"), {});
  const h = corsHeaders("https://a.test", "https://x.test, https://a.test");
  assertEquals(h["Access-Control-Allow-Origin"], "https://a.test");
  assertEquals(h["Access-Control-Allow-Methods"], "POST, OPTIONS");
  assertEquals(h["Access-Control-Expose-Headers"], "Retry-After");
});

// ---------------------------------------------------------------------------
// Handler

interface Harness {
  deps: Deps;
  buckets: Bucket[];
  logs: string[];
  seen: { url: string; init?: RequestInit }[];
}

function harness(
  routes: Record<string, () => Response | Promise<Response>>,
  env: Record<string, string> = { ORS_API_KEY: "ors", GEOAPIFY_API_KEY: "geo" },
  take: (b: Bucket) => boolean | Promise<boolean> = () => true,
): Harness {
  const h: Harness = { buckets: [], logs: [], seen: [], deps: undefined as unknown as Deps };
  h.deps = {
    env: (n) => env[n] ?? "",
    fetch: stubFetch(routes, h.seen),
    takeToken: (b) => {
      h.buckets.push(b);
      return Promise.resolve(take(b));
    },
    now: () => NOW,
    log: (m) => h.logs.push(m),
  };
  return h;
}

const post = (body: unknown, headers: Record<string, string> = {}) =>
  new Request("https://f.test/route-distance", {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
const suggestBody = { action: "suggest", text: "Karlsruhe Marktplatz" };
const distanceBody = { action: "distance", from: { lat: 49, lng: 8 }, to: { lat: 48, lng: 9 } };
const okRoutes = {
  "/geocode/autocomplete": () => jsonRes(orsSuggest),
  "/v2/directions": () => jsonRes({ routes: [{ summary: { distance: 1234 } }] }),
};

Deno.test("handler: suggest ok with attribution and no-store", async () => {
  const h = harness(okRoutes);
  const res = await handleRoute(post(suggestBody), h.deps);
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("cache-control"), "no-store");
  const body = await res.json();
  assertEquals(body.suggestions.length, 2);
  assertEquals(body.attribution.includes("openrouteservice"), true);
  assertEquals(h.buckets.map((b) => b.key.split(":").slice(0, 3).join(":")), [
    "route:suggest:u",
    "route:suggest:global",
  ]);
});

Deno.test("handler: distance ok", async () => {
  const res = await handleRoute(post(distanceBody), harness(okRoutes).deps);
  assertEquals(res.status, 200);
  assertEquals((await res.json()).meters, 1234);
});

Deno.test("handler: OPTIONS, method, bad body, bad params", async () => {
  const h = harness(okRoutes, { ORS_API_KEY: "k", ROUTE_ALLOWED_ORIGINS: "https://a.test" });
  const pre = await handleRoute(
    new Request("https://f.test/", { method: "OPTIONS", headers: { origin: "https://a.test" } }),
    h.deps,
  );
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get("access-control-allow-origin"), "https://a.test");
  assertEquals((await handleRoute(new Request("https://f.test/"), h.deps)).status, 405);
  assertEquals((await handleRoute(post("{not json"), h.deps)).status, 400);
  assertEquals((await handleRoute(post({ action: "suggest", text: "a" }), h.deps)).status, 400);
  assertEquals(h.buckets.length, 0);
});

Deno.test("handler: no provider configured is 503 provider_unconfigured", async () => {
  const res = await handleRoute(post(suggestBody), harness(okRoutes, {}).deps);
  assertEquals(res.status, 503);
  assertEquals((await res.json()).error, "provider_unconfigured");
});

Deno.test("handler: per-user limit answers 429 with Retry-After 60", async () => {
  const h = harness(okRoutes, undefined, (b) => !b.key.includes(":u:"));
  const res = await handleRoute(post(suggestBody), h.deps);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("retry-after"), "60");
  assertEquals((await res.json()).error, "rate_limited");
  assertEquals(h.seen.length, 0);
});

Deno.test("handler: global daily budget answers 429 until UTC midnight", async () => {
  const h = harness(okRoutes, undefined, (b) => !b.key.includes(":global:"));
  const res = await handleRoute(post(distanceBody), h.deps);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("retry-after"), "1800");
  assertEquals(h.seen.length, 0);
});

Deno.test("handler: a broken limiter fails closed with 503", async () => {
  const h = harness(okRoutes, undefined, () => {
    throw new Error("db down");
  });
  const res = await handleRoute(post(suggestBody), h.deps);
  assertEquals(res.status, 503);
  assertEquals((await res.json()).error, "provider_unavailable");
  assertEquals(h.seen.length, 0);
});

Deno.test("handler: user id from the JWT keys the bucket, else the client address", async () => {
  const a = harness(okRoutes);
  await handleRoute(
    post(suggestBody, { authorization: `Bearer h.${b64({ sub: "u1" })}.s` }),
    a.deps,
  );
  const b = harness(okRoutes);
  await handleRoute(
    post(suggestBody, { authorization: `Bearer h.${b64({ sub: "u1" })}.s` }),
    b.deps,
  );
  const c = harness(okRoutes);
  await handleRoute(
    post(suggestBody, { authorization: `Bearer h.${b64({ sub: "u2" })}.s` }),
    c.deps,
  );
  const d = harness(okRoutes);
  await handleRoute(post(suggestBody, { "cf-connecting-ip": "1.1.1.1" }), d.deps);
  assertEquals(a.buckets[0].key, b.buckets[0].key);
  assertEquals(a.buckets[0].key === c.buckets[0].key, false);
  assertEquals(a.buckets[0].key === d.buckets[0].key, false);
  // global bucket is shared by everyone
  assertEquals(a.buckets[1].key, c.buckets[1].key);
});

Deno.test("handler: falls back to the second provider when the first is down", async () => {
  const h = harness({
    "api.openrouteservice.org": () => jsonRes({}, 503),
    "api.geoapify.com/v1/geocode": () => jsonRes(geoSuggest),
  });
  const res = await handleRoute(post(suggestBody), h.deps);
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.attribution.includes("Geoapify"), true);
  assertEquals(h.logs, ["openrouteservice suggest failed: unavailable"]);
});

Deno.test("handler: ROUTE_PROVIDER switches the primary without code changes", async () => {
  const h = harness(okRoutes, {
    ORS_API_KEY: "o",
    GEOAPIFY_API_KEY: "g",
    ROUTE_PROVIDER: "geoapify",
  });
  await handleRoute(post(distanceBody), h.deps).catch(() => {});
  assertEquals(h.seen.every((s) => s.url.includes("geoapify")), true);
});

Deno.test("handler: all providers down is 503 provider_unavailable", async () => {
  const h = harness({
    "api.openrouteservice.org": () => jsonRes({}, 500),
    "api.geoapify.com": () => jsonRes({}, 500),
  });
  const res = await handleRoute(post(distanceBody), h.deps);
  assertEquals(res.status, 503);
  assertEquals((await res.json()).error, "provider_unavailable");
});

Deno.test("handler: no route is 404 and does not try the fallback", async () => {
  const h = harness({
    "api.openrouteservice.org": () => jsonRes({}, 404),
    "api.geoapify.com": () => jsonRes({ features: [{ properties: { distance: 5 } }] }),
  });
  const res = await handleRoute(post(distanceBody), h.deps);
  assertEquals(res.status, 404);
  assertEquals((await res.json()).error, "no_route");
  assertEquals(h.seen.length, 1);
});

Deno.test("handler: never logs query text or coordinates", async () => {
  const h = harness({
    "api.openrouteservice.org": () => jsonRes({}, 500),
    "api.geoapify.com": () => {
      throw new Error("secret Karlsruhe Marktplatz 49.123");
    },
  });
  const secret = { action: "suggest", text: "Karlsruhe Marktplatz" };
  const res = await handleRoute(post(secret), h.deps);
  assertEquals(res.status, 503);
  const dist = await handleRoute(
    post({ ...distanceBody, from: { lat: 49.123, lng: 8.456 } }),
    h.deps,
  );
  assertEquals(dist.status, 503);
  const all = h.logs.join("\n");
  for (const s of ["Karlsruhe", "Marktplatz", "49.123", "8.456"]) {
    assertEquals(all.includes(s), false);
  }
  assertEquals(h.logs.length > 0, true);
});

Deno.test("handler: a synchronously throwing fetch is a provider failure", async () => {
  const h = harness({ "/geocode": () => jsonRes(orsSuggest) });
  h.deps.fetch = () => {
    throw new TypeError("bug");
  };
  // fetch throwing synchronously is still turned into unavailable by the adapter
  const res = await handleRoute(post(suggestBody), h.deps);
  assertEquals(res.status, 503);
});
