import { assert, assertEquals } from "jsr:@std/assert@1.0.8";
import { classifyFcmError, createFcmClient, parseServiceAccount, signJwt } from "./fcm.ts";

// The PEM armor is assembled from parts: the key itself is generated per test run (never stored),
// and a literal armor line in the repo would look like a committed key to secret scanners.
const PEM_LABEL = ["PRIVATE", "KEY"].join(" ");
const unb64 = (x: string) => atob(x.replace(/-/g, "+").replace(/_/g, "/"));

async function testAccount() {
  const pair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pkcs8 = btoa(String.fromCharCode(...der));
  const body = pkcs8.match(/.{1,64}/g)!.join("\n");
  const sa = {
    client_email: "sender@example.iam.gserviceaccount.com",
    private_key: `-----BEGIN ${PEM_LABEL}-----\n${body}\n-----END ${PEM_LABEL}-----\n`,
    token_uri: "https://oauth.test/token",
  };
  return { sa, publicKey: pair.publicKey };
}

Deno.test("parseServiceAccount: valid JSON, invalid inputs", () => {
  const ok = parseServiceAccount(
    JSON.stringify({ client_email: "a@b", private_key: "k", token_uri: "https://t", extra: 1 }),
  );
  assertEquals(ok, { client_email: "a@b", private_key: "k", token_uri: "https://t" });
  assertEquals(parseServiceAccount(""), null);
  assertEquals(parseServiceAccount("not json"), null);
  assertEquals(parseServiceAccount("[]"), null);
  assertEquals(parseServiceAccount("null"), null);
  assertEquals(parseServiceAccount(JSON.stringify({ client_email: "a@b" })), null);
  assertEquals(
    parseServiceAccount(JSON.stringify({ client_email: "a", private_key: 1, token_uri: "t" })),
    null,
  );
});

Deno.test("signJwt: RS256 JWT with the messaging scope that verifies", async () => {
  const { sa, publicKey } = await testAccount();
  const jwt = await signJwt(sa, 1_000_000);
  const [h, p, s] = jwt.split(".");
  assertEquals(JSON.parse(unb64(h)), { alg: "RS256", typ: "JWT" });
  const claims = JSON.parse(unb64(p));
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.aud, sa.token_uri);
  assertEquals(claims.scope, "https://www.googleapis.com/auth/firebase.messaging");
  assertEquals(claims.iat, 1_000_000);
  assertEquals(claims.exp, 1_003_600);
  const sig = Uint8Array.from(unb64(s), (c) => c.charCodeAt(0));
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    sig,
    new TextEncoder().encode(`${h}.${p}`),
  );
  assert(ok);
});

Deno.test("classifyFcmError", () => {
  const detail = (errorCode: unknown) => ({ error: { status: "X", details: [{ errorCode }] } });
  assertEquals(classifyFcmError(404, detail("UNREGISTERED")), {
    kind: "invalid_token",
    code: "UNREGISTERED",
  });
  assertEquals(classifyFcmError(400, { error: { status: "INVALID_ARGUMENT" } }), {
    kind: "invalid_token",
    code: "INVALID_ARGUMENT",
  });
  assertEquals(classifyFcmError(429, { error: { status: "RESOURCE_EXHAUSTED" } }), {
    kind: "retryable",
    code: "RESOURCE_EXHAUSTED",
  });
  assertEquals(classifyFcmError(503, null), { kind: "retryable", code: "HTTP_503" });
  assertEquals(classifyFcmError(401, { error: { status: "UNAUTHENTICATED" } }).kind, "retryable");
  assertEquals(classifyFcmError(403, {}).kind, "retryable");
  assertEquals(classifyFcmError(403, detail(5)).code, "X");
  assertEquals(classifyFcmError(403, { error: { details: "x" } }).code, "HTTP_403");
  assertEquals(classifyFcmError(403, { error: "x" }).code, "HTTP_403");
  assertEquals(classifyFcmError(403, { error: { status: 3 } }).code, "HTTP_403");
  assertEquals(classifyFcmError(400, detail("SENDER_ID_MISMATCH")), {
    kind: "permanent",
    code: "SENDER_ID_MISMATCH",
  });
});

Deno.test("createFcmClient: OAuth token is cached, message goes to the endpoint", async () => {
  const { sa } = await testAccount();
  const calls: { url: string; init: RequestInit }[] = [];
  let tokens = 0;
  const fetchFn = (url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (url === sa.token_uri) {
      tokens++;
      return Promise.resolve(Response.json({ access_token: `at-${tokens}`, expires_in: 3600 }));
    }
    return Promise.resolve(Response.json({ name: "projects/p/messages/1" }));
  };
  let nowMs = 0;
  const client = createFcmClient({
    endpoint: "https://fcm.test/v1/projects/p/messages:send",
    serviceAccount: sa,
    fetch: fetchFn,
    now: () => nowMs,
  });
  assertEquals(await client.send({ token: "t1" }), { ok: true });
  assertEquals(await client.send({ token: "t2" }), { ok: true });
  assertEquals(tokens, 1);
  const sends = calls.filter((c) => c.url !== sa.token_uri);
  assertEquals(sends.length, 2);
  assertEquals(sends[0].url, "https://fcm.test/v1/projects/p/messages:send");
  const headers = sends[0].init.headers as Record<string, string>;
  assertEquals(headers.Authorization, "Bearer at-1");
  assertEquals(JSON.parse(sends[0].init.body as string), { message: { token: "t1" } });
  const form = String(calls[0].init.body);
  assert(
    form.startsWith("grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion="),
  );
  nowMs = 3_600_000;
  await client.send({ token: "t3" });
  assertEquals(tokens, 2, "refreshed after expiry");
});

Deno.test("createFcmClient: error mapping and token endpoint failures", async () => {
  const { sa } = await testAccount();
  let tokenStatus = 200;
  let tokenBody: unknown = { access_token: "at", expires_in: 3600 };
  let sendResponse: () => Response = () => Response.json({}, { status: 200 });
  let sendThrows = false;
  const fetchFn = (url: string) => {
    if (url === sa.token_uri) {
      return Promise.resolve(Response.json(tokenBody, { status: tokenStatus }));
    }
    if (sendThrows) return Promise.reject(new Error("network down"));
    return Promise.resolve(sendResponse());
  };
  const mk = () =>
    createFcmClient({
      endpoint: "https://fcm.test/send",
      serviceAccount: sa,
      fetch: fetchFn,
      now: () => 0,
    });

  tokenStatus = 500;
  assertEquals(await mk().send({}), { ok: false, kind: "retryable", code: "auth_unavailable" });
  tokenStatus = 200;
  tokenBody = { nope: true };
  assertEquals(await mk().send({}), { ok: false, kind: "retryable", code: "auth_unavailable" });
  tokenBody = { access_token: "at", expires_in: "x" };
  assertEquals((await mk().send({})).ok, true, "missing expiry falls back to a short lifetime");
  tokenBody = { access_token: "at", expires_in: 3600 };

  sendResponse = () =>
    Response.json({ error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] } }, {
      status: 404,
    });
  assertEquals(await mk().send({}), { ok: false, kind: "invalid_token", code: "UNREGISTERED" });
  sendResponse = () => new Response("<html>", { status: 502 });
  assertEquals(await mk().send({}), { ok: false, kind: "retryable", code: "HTTP_502" });
  sendThrows = true;
  assertEquals(await mk().send({}), { ok: false, kind: "retryable", code: "network_error" });
});
