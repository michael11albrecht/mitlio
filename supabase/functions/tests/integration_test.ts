// Integration test: real `supabase functions serve` + local Postgres + provider stub.
// Driven by tests/run_integration.sh (env: FUNCTION_URL, ANON_KEY, SERVICE_ROLE_KEY, API_URL,
// STUB_URL, PHASE = key | nokey).
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1.0.8";
import { parseBulletinXlsx } from "../_shared/oil_bulletin.ts";

const need = (n: string) => {
  const v = Deno.env.get(n);
  if (!v) throw new Error(`missing env ${n}`);
  return v;
};
const FUNCTION_URL = need("FUNCTION_URL");
const ANON_KEY = need("ANON_KEY");
const SERVICE_ROLE_KEY = need("SERVICE_ROLE_KEY");
const API_URL = need("API_URL");
const STUB_URL = need("STUB_URL");
const PHASE = need("PHASE");
const ORIGIN = "https://mitlio.app";

function call(query: string, ip: string, extra: Record<string, string> = {}) {
  return fetch(`${FUNCTION_URL}?${query}`, {
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "cf-connecting-ip": ip,
      ...extra,
    },
  });
}

async function stats(): Promise<{ list: Record<string, unknown>[]; oil: number }> {
  return await (await fetch(`${STUB_URL}/__stats`)).json();
}
const reset = async () => await (await fetch(`${STUB_URL}/__reset`)).text();

const keyTest = (name: string, fn: () => Promise<void>) =>
  Deno.test({ name, ignore: PHASE !== "key", fn });
const nokeyTest = (name: string, fn: () => Promise<void>) =>
  Deno.test({ name, ignore: PHASE !== "nokey", fn });

keyTest("CORS: preflight and allowlist", async () => {
  const pre = await fetch(FUNCTION_URL, {
    method: "OPTIONS",
    headers: { Origin: ORIGIN, apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get("access-control-allow-origin"), ORIGIN);
  await pre.body?.cancel();

  const ok = await call("type=e5&plz=10115", "198.51.100.1", { Origin: ORIGIN });
  assertEquals(ok.headers.get("access-control-allow-origin"), ORIGIN);
  await ok.body?.cancel();
  const evil = await call("type=e5&plz=10115", "198.51.100.1", { Origin: "https://evil.example" });
  assertEquals(evil.headers.get("access-control-allow-origin"), null);
  await evil.body?.cancel();
});

keyTest("invalid params and methods", async () => {
  const bad = await call("type=lpg", "198.51.100.2");
  assertEquals(bad.status, 400);
  assertEquals(await bad.json(), { error: "invalid_params" });
  const post = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "cf-connecting-ip": "198.51.100.2",
    },
  });
  assertEquals(post.status, 405);
  await post.body?.cancel();
});

keyTest(
  "nearby: median, cached by ~1 km cell, exact location never reaches the provider",
  async () => {
    await reset();
    const first = await call(
      "type=e5&lat=52.520008&lng=13.404954&radius=5",
      "198.51.100.3",
      { Origin: ORIGIN, "x-forwarded-for": "198.51.100.3" },
    );
    assertEquals(first.status, 200);
    const body = await first.json();
    assertEquals(body.priceMilli, 1800);
    assertEquals(body.stations, 3);
    assertEquals(body.scope, "nearby");
    assertEquals(body.source, "tankerkoenig");
    assertEquals(body.attribution, "Daten: MTS-K via Tankerkönig (CC BY 4.0)");
    assert(!Number.isNaN(Date.parse(body.fetchedAt)));

    let s = await stats();
    assertEquals(s.list.length, 1);
    const seen = s.list[0] as {
      lat: string;
      lng: string;
      rad: string;
      apikey: string;
      headers: Record<string, string>;
    };
    assertEquals(seen.rad, "5");
    assertEquals(seen.apikey, "test-key");
    assert(seen.lat !== "52.520008" && seen.lng !== "13.404954", "coordinates must be snapped");
    assert(Math.abs(Number(seen.lat) - 52.520008) < 0.01);
    for (
      const h of [
        "x-forwarded-for",
        "cf-connecting-ip",
        "origin",
        "authorization",
        "apikey",
        "referer",
      ]
    ) {
      assertFalse(h in seen.headers, `header ${h} leaked to provider`);
    }

    // Same ~1 km cell, slightly different point: served from the cache.
    const second = await call("type=e5&lat=52.5201&lng=13.4051&radius=5", "198.51.100.3");
    assertEquals(second.status, 200);
    assertEquals((await second.json()).priceMilli, 1800);
    s = await stats();
    assertEquals(s.list.length, 1, "second call must not hit the provider");

    // Other fuel types of the same cell were cached by the first call.
    const diesel = await call("type=diesel&lat=52.5201&lng=13.4051&radius=5", "198.51.100.3");
    assertEquals((await diesel.json()).priceMilli, 1650);
    assertEquals((await stats()).list.length, 1);
  },
);

keyTest("plz", async () => {
  await reset();
  const r = await call("type=e10&plz=80331", "198.51.100.4");
  assertEquals(r.status, 200);
  const body = await r.json();
  assertEquals(body.scope, "plz");
  assertEquals(body.priceMilli, 1740);
  const s = await stats();
  assertEquals(s.list.length, 1);
  assertEquals((s.list[0] as { lat: string }).lat, "48.14");
  assertEquals((await (await call("type=e10&plz=80331", "198.51.100.4")).json()).priceMilli, 1740);
  assertEquals((await stats()).list.length, 1);
});

keyTest("national with key: provider average, cached; warm token forces a refresh", async () => {
  await reset();
  const r = await call("type=diesel", "198.51.100.5");
  assertEquals(r.status, 200);
  const body = await r.json();
  assertEquals(body.scope, "national");
  assertEquals(body.source, "tankerkoenig");
  assertEquals(body.priceMilli, 1650);
  assertEquals((await stats()).list.length, 16);
  await (await call("type=e5", "198.51.100.5")).body?.cancel();
  assertEquals((await stats()).list.length, 16, "cached");
  const warm = await call("type=e5", "198.51.100.5", { "x-fuel-warm": "warm-secret" });
  assertEquals(warm.status, 200);
  await warm.body?.cancel();
  assertEquals((await stats()).list.length, 32, "warm refresh hits the provider again");
  const wrong = await call("type=e5", "198.51.100.5", { "x-fuel-warm": "nope" });
  await wrong.body?.cancel();
  assertEquals((await stats()).list.length, 32, "wrong token does not force");
});

keyTest("rate limit: 429 after the bucket is empty, no raw IP stored", async () => {
  const ip = "203.0.113.77";
  for (let i = 0; i < 6; i++) {
    const r = await call("type=e5", ip);
    assertEquals(r.status, 200, `request ${i + 1}`);
    await r.body?.cancel();
  }
  const limited = await call("type=e5", ip);
  assertEquals(limited.status, 429);
  assertEquals(await limited.json(), { error: "rate_limited" });
  assert(limited.headers.get("retry-after"));
  // A different client is unaffected.
  const other = await call("type=e5", "203.0.113.78");
  assertEquals(other.status, 200);
  await other.body?.cancel();

  const rows = await (await fetch(`${API_URL}/rest/v1/rate_limits?select=*`, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` },
  })).json();
  assert(rows.length >= 2);
  for (const row of rows) {
    assert(/^[0-9a-f]{64}$/.test(row.key_hash), "key is a sha256 hex digest");
  }
  assertFalse(JSON.stringify(rows).includes("203.0.113"));
});

keyTest("cache table: anon can read, cannot write", async () => {
  const read = await fetch(`${API_URL}/rest/v1/fuel_price_cache?select=type,price_milli`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assertEquals(read.status, 200);
  assert((await read.json()).length > 0);
  const write = await fetch(`${API_URL}/rest/v1/fuel_price_cache`, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      type: "e5",
      scope: "national",
      scope_key: "x",
      price_milli: 1,
      stations: 1,
    }),
  });
  assert(write.status === 401 || write.status === 403, `anon write status ${write.status}`);
  await write.body?.cancel();
});

nokeyTest("no provider key: nearby/plz are 503 provider_unconfigured", async () => {
  await reset();
  const r = await call("type=e5&lat=52.52&lng=13.4", "198.51.100.20");
  assertEquals(r.status, 503);
  assertEquals(await r.json(), { error: "provider_unconfigured" });
  const p = await call("type=e5&plz=10115", "198.51.100.20");
  assertEquals(p.status, 503);
  await p.body?.cancel();
  assertEquals((await stats()).list.length, 0, "provider never called");
});

nokeyTest("no provider key: national falls back to the EU Oil Bulletin", async () => {
  await reset();
  const expected = await parseBulletinXlsx(
    await Deno.readFile(new URL("../_shared/testdata/oil_bulletin_sample.xlsx", import.meta.url)),
  );
  const r = await call("type=e5", "198.51.100.21");
  assertEquals(r.status, 200);
  const body = await r.json();
  assertEquals(body.source, "eu-oil-bulletin");
  assertEquals(body.scope, "national");
  assertEquals(body.priceMilli, expected.e5Milli);
  assertEquals(body.fetchedAt, expected.date.toISOString());
  assertEquals(body.attribution, "Quelle: EU Weekly Oil Bulletin");
  assertEquals(body.approximation, undefined);

  const e10 = await (await call("type=e10", "198.51.100.21")).json();
  assertEquals(e10.priceMilli, expected.e5Milli);
  assertEquals(e10.approximation, "e5");
  const diesel = await (await call("type=diesel", "198.51.100.21")).json();
  assertEquals(diesel.priceMilli, expected.dieselMilli);

  const s = await stats();
  assertEquals(s.oil, 1, "bulletin fetched once, then cached");
  assertEquals(s.list.length, 0);
});
