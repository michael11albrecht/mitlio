// Integration test of the fx-rates Edge Function: real `supabase functions serve` + local Postgres
// + provider stub. Driven by tests/run_integration.sh (env: FX_FUNCTION_URL, ANON_KEY,
// SERVICE_ROLE_KEY, API_URL, STUB_URL).
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1.0.8";

const need = (n: string) => {
  const v = Deno.env.get(n);
  if (!v) throw new Error(`missing env ${n}`);
  return v;
};
const FUNCTION_URL = need("FX_FUNCTION_URL");
const ANON_KEY = need("ANON_KEY");
const SERVICE_ROLE_KEY = need("SERVICE_ROLE_KEY");
const API_URL = need("API_URL");
const STUB_URL = need("STUB_URL");
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

async function fxCalls(): Promise<{ path: string; headers: Record<string, string> }[]> {
  return (await (await fetch(`${STUB_URL}/__stats`)).json()).fx;
}
const reset = async () => await (await fetch(`${STUB_URL}/__reset`)).text();

Deno.test("CORS: only the allowlist gets headers", async () => {
  const ok = await call("base=USD&quote=CHF", "198.51.100.101", { Origin: ORIGIN });
  // The local gateway overwrites Access-Control-Allow-Origin, so the function's own decision is
  // observed through `Vary: Origin` (exact values are unit-tested in fuel_test.ts).
  assert(ok.headers.get("vary")?.toLowerCase().includes("origin"), "allowed origin gets CORS");
  await ok.body?.cancel();
  const evil = await call("base=USD&quote=CHF", "198.51.100.101", {
    Origin: "https://evil.example",
  });
  assertFalse(evil.headers.get("vary")?.toLowerCase().includes("origin"), "other origins get none");
  await evil.body?.cancel();
});

Deno.test("invalid params and methods", async () => {
  for (
    const q of [
      "base=USD",
      "base=usd&quote=EUR",
      "base=USD&quote=USD",
      "base=USD&quote=EUR&date=2999-01-01",
    ]
  ) {
    const bad = await call(q, "198.51.100.102");
    assertEquals(bad.status, 400, q);
    assertEquals(await bad.json(), { error: "invalid_params" });
  }
  const post = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "cf-connecting-ip": "198.51.100.102",
    },
  });
  assertEquals(post.status, 405);
  await post.body?.cancel();
});

Deno.test("latest: ppm, source day, cached; nothing about the client reaches the provider", async () => {
  await reset();
  const first = await call("base=USD&quote=EUR", "198.51.100.103", {
    Origin: ORIGIN,
    "x-forwarded-for": "198.51.100.103",
  });
  assertEquals(first.status, 200);
  const body = await first.json();
  assertEquals(body.base, "USD");
  assertEquals(body.quote, "EUR");
  assertEquals(body.ratePpm, 920000);
  assertEquals(body.date, "2026-11-13");
  assertEquals(body.source, "frankfurter");
  assertEquals(body.attribution, "Quelle: EZB-Referenzkurse via Frankfurter");
  assert(!Number.isNaN(Date.parse(body.fetchedAt)));

  const calls = await fxCalls();
  assertEquals(calls.length, 1);
  assertEquals(calls[0].path, "/latest?from=USD&to=EUR");
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
    assertFalse(h in calls[0].headers, `header ${h} leaked to provider`);
  }

  const second = await call("base=USD&quote=EUR", "198.51.100.103");
  assertEquals(second.status, 200);
  assertEquals((await second.json()).ratePpm, 920000);
  assertEquals((await fxCalls()).length, 1, "second call must not hit the provider");
});

Deno.test("decimal rates are rounded to whole ppm", async () => {
  const r = await call("base=EUR&quote=USD", "198.51.100.104");
  assertEquals(r.status, 200);
  assertEquals((await r.json()).ratePpm, 1086957);
});

Deno.test("a weekend date returns the last working day, cached under the asked day", async () => {
  await reset();
  const r = await call("base=USD&quote=GBP&date=2025-11-15", "198.51.100.105");
  assertEquals(r.status, 200);
  const body = await r.json();
  assertEquals(body.date, "2025-11-14");
  assertEquals(body.ratePpm, 790000);
  assertEquals((await fxCalls())[0].path, "/2025-11-15?from=USD&to=GBP");
  const again = await call("base=USD&quote=GBP&date=2025-11-15", "198.51.100.105");
  assertEquals((await again.json()).date, "2025-11-14");
  assertEquals((await fxCalls()).length, 1, "past days are cached");
});

Deno.test("a currency the provider does not know is 404 no_data", async () => {
  const r = await call("base=USD&quote=XXX", "198.51.100.106");
  assertEquals(r.status, 404);
  assertEquals(await r.json(), { error: "no_data" });
});

Deno.test("warm token forces a refresh of latest, a wrong token does not", async () => {
  await reset();
  const warm = await call("base=USD&quote=EUR", "198.51.100.107", {
    "x-fx-warm": "fx-warm-secret",
  });
  assertEquals(warm.status, 200);
  await warm.body?.cancel();
  assertEquals((await fxCalls()).length, 1);
  const wrong = await call("base=USD&quote=EUR", "198.51.100.107", { "x-fx-warm": "nope" });
  await wrong.body?.cancel();
  assertEquals((await fxCalls()).length, 1, "wrong token is served from the cache");
});

Deno.test("rate limit: 429 after the bucket is empty, separate from fuel-prices", async () => {
  const ip = "203.0.113.177";
  for (let i = 0; i < 6; i++) {
    const r = await call("base=USD&quote=EUR", ip);
    assertEquals(r.status, 200, `request ${i + 1}`);
    await r.body?.cancel();
  }
  const limited = await call("base=USD&quote=EUR", ip);
  assertEquals(limited.status, 429);
  assertEquals(await limited.json(), { error: "rate_limited" });
  assert(limited.headers.get("retry-after"));
  const other = await call("base=USD&quote=EUR", "203.0.113.178");
  assertEquals(other.status, 200);
  await other.body?.cancel();
});

Deno.test("cache table: anon can read, cannot write", async () => {
  const read = await fetch(`${API_URL}/rest/v1/fx_rates?select=base,quote,rate_ppm`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assertEquals(read.status, 200);
  assert((await read.json()).length > 0);
  const write = await fetch(`${API_URL}/rest/v1/fx_rates`, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      base: "USD",
      quote: "JPY",
      date: "2025-11-14",
      rate_ppm: 1,
      source_date: "2025-11-14",
    }),
  });
  assert(write.status === 401 || write.status === 403, `anon write status ${write.status}`);
  await write.body?.cancel();
  // The service role is the writer (the function used it above).
  const svc = await fetch(`${API_URL}/rest/v1/fx_rates?select=base&limit=1`, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` },
  });
  assertEquals(svc.status, 200);
  await svc.body?.cancel();
});
