import { assertEquals } from "jsr:@std/assert@1.0.8";
import {
  buildResendPayload,
  buildSubject,
  type ContactConfig,
  corsHeaders,
  type Deps,
  GLOBAL_ID,
  handleContact,
  isHoneypot,
  mapProviderStatus,
  rateLimitDecision,
  readConfig,
  retryAfterSeconds,
  validateContact,
} from "./contact.ts";
import { hashClient } from "./fuel.ts";

// Same salt as ENV below; the global bucket key is hashed like the per-client one.
const GLOBAL_KEY = await hashClient(GLOBAL_ID, "salt");

const valid = {
  name: "Mia",
  email: "mia@example.org",
  message: "Hallo, eine Frage zur App.",
  locale: "de" as const,
};
const config: ContactConfig = {
  apiKey: "re_key",
  to: "contact@mitlio.de",
  from: "kontakt@mitlio.de",
};
const ENV: Record<string, string> = {
  RESEND_API_KEY: "re_key",
  CONTACT_TO: "contact@mitlio.de",
  CONTACT_FROM: "kontakt@mitlio.de",
  CONTACT_ALLOWED_ORIGINS: "https://mitlio.test",
  CONTACT_RATE_LIMIT_SALT: "salt",
};

Deno.test("validate: accepts a valid body and trims", () => {
  const r = validateContact({ ...valid, name: "  Mia ", email: " mia@example.org " });
  assertEquals(r, { ok: true, value: { ...valid } });
});

Deno.test("validate: name is optional", () => {
  const r = validateContact({ ...valid, name: undefined });
  assertEquals(r.ok && r.value.name, "");
});

Deno.test("validate: error codes", () => {
  const code = (patch: Record<string, unknown>) => {
    const r = validateContact({ ...valid, ...patch });
    return r.ok ? "ok" : r.error;
  };
  assertEquals(code({ email: "nope" }), "invalid_email");
  assertEquals(code({ email: "a b@c.de" }), "invalid_email");
  assertEquals(code({ email: "a@b" }), "invalid_email");
  assertEquals(code({ email: `${"a".repeat(250)}@b.de` }), "invalid_email");
  assertEquals(code({ email: 5 }), "invalid_email");
  assertEquals(code({ message: "kurz" }), "message_too_short");
  assertEquals(code({ message: "         x         " }), "message_too_short");
  assertEquals(code({ message: "x".repeat(10) }), "ok");
  assertEquals(code({ message: "x".repeat(5000) }), "ok");
  assertEquals(code({ message: "x".repeat(5001) }), "message_too_long");
  assertEquals(code({ name: "n".repeat(100) }), "ok");
  assertEquals(code({ name: "n".repeat(101) }), "name_too_long");
  assertEquals(code({ locale: "fr" }), "invalid_locale");
  assertEquals(validateContact(null), { ok: false, error: "invalid_json" });
  assertEquals(validateContact([]), { ok: false, error: "invalid_json" });
});

Deno.test("honeypot", () => {
  assertEquals(isHoneypot({ website: "http://spam" }), true);
  assertEquals(isHoneypot({ website: "  " }), false);
  assertEquals(isHoneypot({ website: "" }), false);
  assertEquals(isHoneypot({}), false);
  assertEquals(isHoneypot(null), false);
  assertEquals(isHoneypot("x"), false);
});

Deno.test("config: all three secrets are required", () => {
  const get = (m: Record<string, string>) => (n: string) => m[n] ?? "";
  assertEquals(readConfig(get(ENV)), config);
  assertEquals(readConfig(get({ ...ENV, RESEND_API_KEY: "" })), null);
  assertEquals(readConfig(get({ ...ENV, CONTACT_TO: " " })), null);
  assertEquals(readConfig(get({ ...ENV, CONTACT_FROM: "" })), null);
});

Deno.test("subject: prefix, 60 characters, one line", () => {
  assertEquals(buildSubject("Hallo"), "mitlio Kontakt: Hallo");
  assertEquals(buildSubject("a".repeat(100)), `mitlio Kontakt: ${"a".repeat(60)}`);
  assertEquals(
    buildSubject("Zeile1\r\nBcc: evil@x.de\n\nZeile3"),
    "mitlio Kontakt: Zeile1 Bcc: evil@x.de Zeile3",
  );
  assertEquals(buildSubject("😀".repeat(70)), `mitlio Kontakt: ${"😀".repeat(60)}`);
});

Deno.test("payload: reply_to is the user, to/from from config", () => {
  const p = buildResendPayload({ ...valid, locale: "de" }, config);
  assertEquals(p.from, "kontakt@mitlio.de");
  assertEquals(p.to, ["contact@mitlio.de"]);
  assertEquals(p.reply_to, "mia@example.org");
  assertEquals(p.subject, "mitlio Kontakt: Hallo, eine Frage zur App.");
  assertEquals(
    p.text,
    "Name: Mia\nE-Mail: mia@example.org\nSprache: de\n\nHallo, eine Frage zur App.",
  );
  assertEquals(
    buildResendPayload({ ...valid, name: "", locale: "en" }, config).text.startsWith("Name: -\n"),
    true,
  );
});

Deno.test("rate limit decision and retry-after", () => {
  assertEquals(retryAfterSeconds(5), 720);
  assertEquals(retryAfterSeconds(7), 515);
  assertEquals(rateLimitDecision(true, 5), { status: 200 });
  assertEquals(rateLimitDecision(false, 5), { status: 429, retryAfter: 720 });
});

Deno.test("provider status mapping", () => {
  assertEquals(mapProviderStatus(200), "ok");
  assertEquals(mapProviderStatus(202), "ok");
  assertEquals(mapProviderStatus(400), "send_failed");
  assertEquals(mapProviderStatus(429), "send_failed");
  assertEquals(mapProviderStatus(500), "send_failed");
});

Deno.test("cors: only allowlisted origins, POST allowed", () => {
  assertEquals(corsHeaders("https://evil.test", "https://mitlio.test"), {});
  assertEquals(corsHeaders(null, "https://mitlio.test"), {});
  const h = corsHeaders("https://mitlio.test", "https://mitlio.test");
  assertEquals(h["Access-Control-Allow-Origin"], "https://mitlio.test");
  assertEquals(h["Access-Control-Allow-Methods"], "POST, OPTIONS");
});

interface Harness {
  deps: Deps;
  sent: { url: string; init: RequestInit }[];
  keys: { key: string; capacity: number; refill: number }[];
  logs: string[];
}

function harness(
  opts: {
    env?: Record<string, string>;
    allowed?: boolean;
    globalAllowed?: boolean;
    limiterThrows?: boolean;
    provider?: () => Response | Promise<Response>;
  } = {},
): Harness {
  const env = opts.env ?? ENV;
  const h: Harness = {
    sent: [],
    keys: [],
    logs: [],
    deps: {
      env: (n) => env[n] ?? "",
      log: (line) => h.logs.push(line),
      fetch: (url, init) => {
        h.sent.push({ url, init });
        return Promise.resolve((opts.provider ?? (() => Response.json({ id: "1" })))());
      },
      takeToken: (key, capacity, refill) => {
        // rate_limits.key_hash is checked to be 16..128 chars (migration 0005): a short key fails in the RPC.
        assertEquals(key.length >= 16 && key.length <= 128, true, `bad key length: ${key.length}`);
        h.keys.push({ key, capacity, refill });
        if (opts.limiterThrows) return Promise.reject(new Error("db down"));
        if (key === GLOBAL_KEY) return Promise.resolve(opts.globalAllowed ?? true);
        return Promise.resolve(opts.allowed ?? true);
      },
    },
  };
  return h;
}

const post = (body: unknown, headers: Record<string, string> = {}) =>
  new Request("https://f.test/contact", {
    method: "POST",
    headers: { "content-type": "application/json", "x-forwarded-for": "203.0.113.9", ...headers },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });

Deno.test("handler: success sends one mail through Resend", async () => {
  const h = harness();
  const res = await handleContact(post(valid, { origin: "https://mitlio.test" }), h.deps);
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { ok: true });
  assertEquals(res.headers.get("access-control-allow-origin"), "https://mitlio.test");
  assertEquals(h.sent.length, 1);
  assertEquals(h.sent[0].url, "https://api.resend.com/emails");
  const headers = h.sent[0].init.headers as Record<string, string>;
  assertEquals(headers["Authorization"], "Bearer re_key");
  const payload = JSON.parse(h.sent[0].init.body as string);
  assertEquals(payload.reply_to, "mia@example.org");
  // The limiter key is a salted hash: neither the IP nor anything from the message is in it.
  assertEquals(h.keys.length, 2);
  assertEquals(/^[0-9a-f]{64}$/.test(h.keys[0].key), true);
  assertEquals(h.keys[0].capacity, 5);
  assertEquals(h.keys[0].refill, 5 / 3600);
  // Global cap: salted hash of a fixed id (no client data), 50 per day.
  assertEquals(h.keys[1].key.length, 64);
  assertEquals(h.keys[1], { key: GLOBAL_KEY, capacity: 50, refill: 50 / 86400 });
});

Deno.test("handler: honeypot answers 200 and sends and counts nothing", async () => {
  const h = harness();
  const res = await handleContact(post({ ...valid, website: "http://spam.test" }), h.deps);
  assertEquals(res.status, 200);
  assertEquals(h.sent.length, 0);
  assertEquals(h.keys.length, 0);
});

Deno.test("handler: validation errors are 400 codes and cost no token", async () => {
  const h = harness();
  const res = await handleContact(post({ ...valid, email: "x" }), h.deps);
  assertEquals(res.status, 400);
  assertEquals(await res.json(), { error: "invalid_email" });
  assertEquals((await handleContact(post("{not json"), h.deps)).status, 400);
  assertEquals(h.sent.length, 0);
  assertEquals(h.keys.length, 0);
});

Deno.test("handler: 429 with Retry-After", async () => {
  const h = harness({ allowed: false });
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("retry-after"), "720");
  assertEquals(await res.json(), { error: "rate_limited", retryAfter: 720 });
  assertEquals(h.sent.length, 0);
  assertEquals(h.keys.length, 1);
});

Deno.test("handler: custom limit", async () => {
  const h = harness({ env: { ...ENV, CONTACT_RATE_LIMIT_PER_HOUR: "10" }, allowed: false });
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.headers.get("retry-after"), "360");
});

Deno.test("handler: salt falls back to the fuel salt, then the service key", async () => {
  const a = harness({ env: { ...ENV, CONTACT_RATE_LIMIT_SALT: "" } });
  const b = harness({ env: { ...ENV, CONTACT_RATE_LIMIT_SALT: "", FUEL_RATE_LIMIT_SALT: "f" } });
  const c = harness({
    env: { ...ENV, CONTACT_RATE_LIMIT_SALT: "", SUPABASE_SERVICE_ROLE_KEY: "s" },
  });
  for (const h of [a, b, c]) await handleContact(post(valid), h.deps);
  assertEquals(new Set([a.keys[0].key, b.keys[0].key, c.keys[0].key]).size, 3);
});

Deno.test("handler: missing config is 503 not_configured, nothing sent", async () => {
  const h = harness({ env: { ...ENV, RESEND_API_KEY: "" } });
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.status, 503);
  assertEquals(await res.json(), { error: "not_configured" });
  assertEquals(h.sent.length, 0);
});

Deno.test("handler: broken limiter keeps the endpoint closed", async () => {
  const h = harness({ limiterThrows: true });
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.status, 503);
  assertEquals(await res.json(), { error: "rate_limit_unavailable" });
  assertEquals(h.sent.length, 0);
});

Deno.test("handler: provider error and network failure are 502 send_failed", async () => {
  const bad = harness({ provider: () => Response.json({ message: "x" }, { status: 422 }) });
  const r1 = await handleContact(post(valid), bad.deps);
  assertEquals(r1.status, 502);
  assertEquals(await r1.json(), { error: "send_failed" });
  const down = harness({ provider: () => Promise.reject(new Error("net")) });
  assertEquals((await handleContact(post(valid), down.deps)).status, 502);
});

Deno.test("handler: OPTIONS and wrong method", async () => {
  const h = harness();
  const pre = await handleContact(
    new Request("https://f.test/", {
      method: "OPTIONS",
      headers: { origin: "https://mitlio.test" },
    }),
    h.deps,
  );
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get("access-control-allow-origin"), "https://mitlio.test");
  assertEquals((await handleContact(new Request("https://f.test/"), h.deps)).status, 405);
});

Deno.test("handler: global daily cap answers 429 busy and sends nothing", async () => {
  const h = harness({ globalAllowed: false });
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.status, 429);
  assertEquals(res.headers.get("retry-after"), "1728");
  assertEquals(await res.json(), { error: "busy", retryAfter: 1728 });
  assertEquals(h.sent.length, 0);
  const custom = harness({ env: { ...ENV, CONTACT_GLOBAL_PER_DAY: "100" } });
  await handleContact(post(valid), custom.deps);
  assertEquals(custom.keys[1].capacity, 100);
});

Deno.test("handler: broken limiter on the global bucket keeps the endpoint closed", async () => {
  const h = harness();
  h.deps.takeToken = (key) =>
    key === GLOBAL_KEY ? Promise.reject(new Error("db down")) : Promise.resolve(true);
  const res = await handleContact(post(valid), h.deps);
  assertEquals(res.status, 503);
  assertEquals(h.sent.length, 0);
});

Deno.test("handler: provider failure logs one line with status and type only", async () => {
  const secret = {
    name: "Geheim Person",
    email: "geheim@example.org",
    message: "Streng vertraulicher Text hier",
    locale: "de",
  };
  const h = harness({
    provider: () =>
      Response.json({
        statusCode: 422,
        name: "validation_error",
        message: "geheim@example.org bad",
      }, {
        status: 422,
      }),
  });
  const res = await handleContact(post(secret, { "x-forwarded-for": "198.51.100.77" }), h.deps);
  assertEquals(res.status, 502);
  assertEquals(h.logs, ["contact send failed: status=422 type=validation_error"]);
  const all = h.logs.join("\n");
  for (const bad of ["Geheim", "geheim@", "vertraulich", "198.51.100.77", "re_key"]) {
    assertEquals(all.includes(bad), false);
  }
});

Deno.test("handler: failure log with unparsable body or network error", async () => {
  const junk = harness({ provider: () => new Response("<html>boom</html>", { status: 500 }) });
  await handleContact(post(valid), junk.deps);
  assertEquals(junk.logs, ["contact send failed: status=500 type=unknown"]);
  const odd = harness({
    provider: () =>
      Response.json({ name: "Evil Name With Spaces geheim@example.org" }, { status: 400 }),
  });
  await handleContact(post(valid), odd.deps);
  assertEquals(odd.logs, ["contact send failed: status=400 type=unknown"]);
  const down = harness({
    provider: () => Promise.reject(new DOMException("m@x.de", "TimeoutError")),
  });
  await handleContact(post(valid), down.deps);
  assertEquals(down.logs, ["contact send failed: status=0 type=TimeoutError"]);
  const plain = harness({ provider: () => Promise.reject(new Error("m@x.de")) });
  await handleContact(post(valid), plain.deps);
  assertEquals(plain.logs, ["contact send failed: status=0 type=Error"]);
});

Deno.test("handler: limiter failure logs a fixed line", async () => {
  const h = harness({ limiterThrows: true });
  await handleContact(post(valid), h.deps);
  assertEquals(h.logs, ["contact rate limiter failed"]);
});

Deno.test("every key passed to takeToken fits rate_limits.key_hash (16..128 chars)", async () => {
  const h = harness();
  await handleContact(post(valid), h.deps);
  assertEquals(h.keys.length, 2);
  for (const k of h.keys) assertEquals(/^[0-9a-f]{64}$/.test(k.key), true);
  assertEquals(h.keys[0].key === h.keys[1].key, false);
});
