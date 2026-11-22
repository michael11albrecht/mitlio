// Integration test of the submit-feedback Edge Function: real `supabase functions serve` + local Postgres and
// Storage + GitHub stub. Driven by tests/run_integration.sh (env: FEEDBACK_FUNCTION_URL, ANON_KEY,
// SERVICE_ROLE_KEY, API_URL, STUB_URL, PHASE = key | nokey).
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1.0.8";

const need = (n: string) => {
  const v = Deno.env.get(n);
  if (!v) throw new Error(`missing env ${n}`);
  return v;
};
const FUNCTION_URL = need("FEEDBACK_FUNCTION_URL");
const ANON_KEY = need("ANON_KEY");
const SERVICE_ROLE_KEY = need("SERVICE_ROLE_KEY");
const API_URL = need("API_URL");
const STUB_URL = need("STUB_URL");
const PHASE = need("PHASE");
const TOKEN = "test-github-token";

// 1x1 PNG
const PNG = Uint8Array.from(
  atob(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
  ),
  (c) => c.charCodeAt(0),
);
const b64 = (b: Uint8Array) => btoa(String.fromCharCode(...b));

const body = (patch: Record<string, unknown> = {}) => ({
  type: "problem",
  message: "Integration test: the settlement shows a wrong amount.",
  email: "",
  locale: "en",
  diagnostics: null,
  screenshots: [],
  ...patch,
});

function post(ip: string, payload: unknown) {
  return fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "Content-Type": "application/json",
      "cf-connecting-ip": ip,
    },
    body: JSON.stringify(payload),
  });
}

const githubCalls = async (): Promise<{ headers: Record<string, string>; body: string }[]> =>
  (await (await fetch(`${STUB_URL}/__stats`)).json()).github;

const keyTest = (name: string, fn: () => Promise<void>) =>
  Deno.test({ name, ignore: PHASE !== "key", fn });
const noKeyTest = (name: string, fn: () => Promise<void>) =>
  Deno.test({ name, ignore: PHASE !== "nokey", fn });

noKeyTest(
  "without the GitHub token: probe and submit answer 503 provider_unconfigured",
  async () => {
    const probe = await fetch(FUNCTION_URL, {
      headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
    });
    assertEquals(probe.status, 503);
    assertEquals(await probe.json(), { error: "provider_unconfigured" });
    const res = await post("198.51.100.201", body());
    assertEquals(res.status, 503);
    assertEquals(await res.json(), { error: "provider_unconfigured" });
  },
);

keyTest("probe says available", async () => {
  const probe = await fetch(FUNCTION_URL, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assertEquals(probe.status, 200);
  assertEquals(await probe.json(), { available: true });
});

keyTest("submit: issue with fixed labels, private screenshot, token never leaves", async () => {
  await fetch(`${STUB_URL}/__reset`).then((r) => r.text());
  const res = await post(
    "198.51.100.202",
    body({
      email: "mia@example.org",
      screenshots: [{ data: b64(PNG) }],
      diagnostics: { appVersion: "0.4.0", os: "iOS 18", locale: "en" },
    }),
  );
  assertEquals(res.status, 200);
  const text = await res.text();
  assertEquals(JSON.parse(text), { ok: true });
  assertFalse(text.includes(TOKEN));

  const calls = await githubCalls();
  assertEquals(calls.length, 1);
  assertEquals(calls[0].headers["authorization"], `Bearer ${TOKEN}`);
  const issue = JSON.parse(calls[0].body);
  assertEquals(issue.labels, ["user-feedback", "needs-triage"]);
  assertFalse(calls[0].body.includes("mia@example.org"), "no e-mail in the public issue");
  assert(issue.body.includes("**App:** 0.4.0, iOS 18, en"));
  const id = /Feedback id: `([0-9a-f-]{36})`/.exec(issue.body)?.[1];
  assert(id, "issue names the feedback id");

  // The stored files exist for the service role ...
  const list = await fetch(`${API_URL}/storage/v1/object/list/feedback-screenshots`, {
    method: "POST",
    headers: {
      apikey: SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ prefix: id, limit: 10 }),
  });
  const names = (await list.json()).map((o: { name: string }) => o.name).sort();
  assertEquals(names, ["1.png", "contact.json"]);
  // ... and are not reachable with the public anon key.
  const anon = await fetch(`${API_URL}/storage/v1/object/feedback-screenshots/${id}/1.png`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assert(anon.status >= 400, `anon read must fail, got ${anon.status}`);
  await anon.body?.cancel();
  const anonPublic = await fetch(
    `${API_URL}/storage/v1/object/public/feedback-screenshots/${id}/1.png`,
  );
  assert(anonPublic.status >= 400, `public URL must fail, got ${anonPublic.status}`);
  await anonPublic.body?.cancel();
});

keyTest("validation errors create no issue", async () => {
  await fetch(`${STUB_URL}/__reset`).then((r) => r.text());
  const res = await post("198.51.100.203", body({ message: "kurz" }));
  assertEquals(res.status, 400);
  assertEquals(await res.json(), { error: "message_too_short" });
  const notImage = await post(
    "198.51.100.203",
    body({ screenshots: [{ data: btoa("not an image at all") }] }),
  );
  assertEquals(notImage.status, 400);
  assertEquals(await notImage.json(), { error: "invalid_screenshot" });
  assertEquals((await githubCalls()).length, 0);
});

keyTest("rate limit: 429 with retryAfter after the per-client bucket is empty", async () => {
  const ip = "198.51.100.204";
  // FEEDBACK_RATE_LIMIT_PER_HOUR=3 in run_integration.sh
  for (let i = 0; i < 3; i++) {
    const ok = await post(ip, body());
    assertEquals(ok.status, 200);
    await ok.body?.cancel();
  }
  const limited = await post(ip, body());
  assertEquals(limited.status, 429);
  const json = await limited.json();
  assertEquals(json.error, "rate_limited");
  assert(json.retryAfter > 0);
  const raw = await fetch(`${API_URL}/rest/v1/rate_limits?select=*`, {
    headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` },
  });
  assertFalse((await raw.text()).includes(ip), "no raw IP stored");
});

keyTest("cleanup needs its token", async () => {
  const wrong = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "x-feedback-cleanup": "nope",
    },
  });
  assertEquals(wrong.status, 401);
  await wrong.body?.cancel();
  const ok = await fetch(FUNCTION_URL, {
    method: "POST",
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      "x-feedback-cleanup": "integration-cleanup-token",
    },
  });
  assertEquals(ok.status, 200);
  const out = await ok.json();
  assertEquals(out.ok, true);
  assertEquals(out.deleted, 0, "nothing is older than 90 days");
});
