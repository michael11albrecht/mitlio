// Integration test of the notify Edge Function (P6b-T05): real `supabase functions serve` + local
// Postgres + an FCM / OAuth stub that records every request. Driven by tests/run_integration.sh
// (env: NOTIFY_FUNCTION_URL, NOTIFY_TOKEN, ANON_KEY, SERVICE_ROLE_KEY, API_URL, STUB_URL).
// Outbox rows are inserted directly; the triggers that write them are covered by pgTAP.
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1.0.8";

const need = (n: string) => {
  const v = Deno.env.get(n);
  if (!v) throw new Error(`missing env ${n}`);
  return v;
};
const FUNCTION_URL = need("NOTIFY_FUNCTION_URL");
const NOTIFY_TOKEN = need("NOTIFY_TOKEN");
const ANON_KEY = need("ANON_KEY");
const SERVICE_ROLE_KEY = need("SERVICE_ROLE_KEY");
const API_URL = need("API_URL");
const STUB_URL = need("STUB_URL");

const svc = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

async function rest(path: string, init: RequestInit = {}): Promise<Response> {
  return await fetch(`${API_URL}/rest/v1/${path}`, {
    ...init,
    headers: { ...svc, Prefer: "return=representation", ...(init.headers ?? {}) },
  });
}

async function insert(table: string, rows: unknown): Promise<void> {
  const res = await rest(table, { method: "POST", body: JSON.stringify(rows) });
  if (!res.ok) throw new Error(`insert ${table}: ${res.status} ${await res.text()}`);
  await res.body?.cancel();
}

async function select<T>(path: string): Promise<T[]> {
  const res = await rest(path);
  assert(res.ok, `select ${path}: ${res.status}`);
  return await res.json();
}

async function patch(path: string, body: unknown): Promise<void> {
  const res = await rest(path, { method: "PATCH", body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`patch ${path}: ${res.status} ${await res.text()}`);
  await res.body?.cancel();
}

async function createUser(email: string): Promise<string> {
  const res = await fetch(`${API_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: svc,
    body: JSON.stringify({ email, email_confirm: true }),
  });
  const body = await res.text();
  assert(res.ok, `create user: ${res.status} ${body}`);
  return JSON.parse(body).id;
}

function callNotify(headers: Record<string, string> = {}) {
  return fetch(FUNCTION_URL, {
    method: "POST",
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}`, ...headers },
  });
}

const run = () => callNotify({ "x-notify-token": NOTIFY_TOKEN });

// deno-lint-ignore no-explicit-any
type Message = Record<string, any>;
interface Sent {
  authorization: string | null;
  body: { message: Message };
}
async function stats(): Promise<
  { fcm: Sent[]; oauth: { grant_type: string; assertion: string }[] }
> {
  return await (await fetch(`${STUB_URL}/__stats`)).json();
}
const sentTo = async (token: string) =>
  (await stats()).fcm.filter((c) => c.body.message.token === token);

const tag = crypto.randomUUID().slice(0, 8);
const T = (name: string) => `${tag}-${name}`;

const G = crypto.randomUUID();
const [M_ANNA, M_BEN, M_CARA] = [crypto.randomUUID(), crypto.randomUUID(), crypto.randomUUID()];
let anna = "", ben = "", cara = "";

function event(over: Record<string, unknown> = {}, payload: Record<string, unknown> = {}) {
  const entity = crypto.randomUUID();
  return {
    id: crypto.randomUUID(),
    group_id: G,
    actor_user_id: anna,
    event: "expense_added",
    entity_id: entity,
    dedupe_key: `it-${entity}`,
    payload: {
      actor_name: "Anna",
      group_name: "Italy trip",
      title: "Fuel",
      amount_cents: 4200,
      currency: "EUR",
      involved_member_ids: [M_ANNA, M_BEN, M_CARA],
      ...payload,
    },
    ...over,
  };
}

Deno.test("setup: users, group, members, tokens", async () => {
  await (await fetch(`${STUB_URL}/__reset`)).body?.cancel();
  anna = await createUser(`anna-${tag}@example.test`);
  ben = await createUser(`ben-${tag}@example.test`);
  cara = await createUser(`cara-${tag}@example.test`);
  await insert("groups", {
    id: G,
    name: "Italy trip",
    currency: "EUR",
    created_by: anna,
    updated_at: "h1",
  });
  await insert("members", [
    { id: M_ANNA, group_id: G, updated_at: "h1", name: "Anna", position: 0 },
    { id: M_BEN, group_id: G, updated_at: "h1", name: "Ben", position: 1 },
    { id: M_CARA, group_id: G, updated_at: "h1", name: "Cara", position: 2 },
  ]);
  await insert("group_memberships", [
    { group_id: G, user_id: anna, member_id: M_ANNA },
    { group_id: G, user_id: ben, member_id: M_BEN },
    { group_id: G, user_id: cara, member_id: M_CARA },
  ]);
  await insert("device_tokens", [
    { user_id: anna, token: T("anna-ok"), platform: "android", locale: "de" },
    { user_id: ben, token: T("ben-ok"), platform: "android", locale: "de" },
    { user_id: ben, token: T("ben-unregistered"), platform: "android", locale: "de" },
    { user_id: cara, token: T("cara-ok"), platform: "ios", locale: "en-US" },
  ]);
});

Deno.test("only the cron token may run it; wrong method is rejected", async () => {
  const none = await callNotify();
  assertEquals(none.status, 401);
  assertEquals(await none.json(), { error: "unauthorized" });
  const wrong = await callNotify({ "x-notify-token": "nope" });
  assertEquals(wrong.status, 401);
  await wrong.body?.cancel();
  const get = await fetch(FUNCTION_URL, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${ANON_KEY}` },
  });
  assertEquals(get.status, 405);
  await get.body?.cancel();
});

Deno.test("a burst is coalesced, recipients exclude the actor, dead token is removed", async () => {
  await insert("notification_outbox", [event(), event()]);
  const res = await run();
  assertEquals(res.status, 200);
  const s = await res.json();
  assertEquals(s.claimed, 2);
  assertEquals(s.recipients, 2);
  assertEquals(s.messages, 3);
  assertEquals(s.sent, 2);
  assertEquals(s.invalid_tokens, 1);
  assertEquals(s.retried, 0);

  assertEquals((await sentTo(T("anna-ok"))).length, 0, "the actor is not notified");
  const ben1 = await sentTo(T("ben-ok"));
  assertEquals(ben1.length, 1, "two events, one message");
  assertEquals(ben1[0].authorization, "Bearer stub-access-token");
  const android = ben1[0].body.message.android;
  assertEquals(android.notification.body_loc_key, "push_expenses_added");
  assertEquals(android.notification.body_loc_args, ["Anna", "2", "Italy trip"]);
  assertEquals(android.collapse_key, G);
  assertEquals(ben1[0].body.message.data.group_id, G);
  assertFalse(JSON.stringify(ben1[0].body.message).includes("iban"));

  const cara1 = await sentTo(T("cara-ok"));
  assertEquals(cara1.length, 1);
  assertEquals(cara1[0].body.message.apns.payload.aps.alert["loc-key"], "push_expenses_added");
  assertEquals(cara1[0].body.message.apns.headers["apns-collapse-id"], G);

  assertEquals((await sentTo(T("ben-unregistered"))).length, 1);
  const left = await select<{ token: string }>(`device_tokens?token=like.${tag}-*&select=token`);
  assertEquals(
    left.map((r) => r.token).sort(),
    [T("anna-ok"), T("ben-ok"), T("cara-ok")].sort(),
    "UNREGISTERED token deleted",
  );

  const oauth = (await stats()).oauth;
  assertEquals(oauth.length, 1, "one OAuth exchange, token cached");
  assertEquals(oauth[0].grant_type, "urn:ietf:params:oauth:grant-type:jwt-bearer");
  assertEquals(oauth[0].assertion.split(".").length, 3);

  const pending = await select(`notification_outbox?group_id=eq.${G}&processed_at=is.null`);
  assertEquals(pending.length, 0, "claimed rows are processed");

  const again = await (await run()).json();
  assertEquals(again.claimed, 0, "nothing is sent twice");
  assertEquals((await stats()).fcm.length, 3);
});

Deno.test("prefs: none skips the user, hide_amounts sends the generic body", async () => {
  await insert("notification_prefs", [
    { user_id: cara, group_id: G, level: "none", hide_amounts: false },
    { user_id: ben, group_id: G, level: "all", hide_amounts: true },
  ]);
  await fetch(`${STUB_URL}/__reset`).then((r) => r.body?.cancel());
  await insert("notification_outbox", [event({}, { title: "Secret gift" })]);
  const s = await (await run()).json();
  assertEquals(s.claimed, 1);
  assertEquals((await sentTo(T("cara-ok"))).length, 0);
  const ben1 = await sentTo(T("ben-ok"));
  assertEquals(ben1.length, 1);
  assertEquals(ben1[0].body.message.android.notification.body_loc_key, "push_generic");
  assertFalse(JSON.stringify(ben1[0].body.message).includes("Secret gift"));
  await patch(`notification_prefs?group_id=eq.${G}`, { level: "all", hide_amounts: false });
});

Deno.test("retries: 503 re-queues with backoff, succeeds later, gives up at the max", async () => {
  await insert("device_tokens", [
    { user_id: ben, token: T("ben-flaky"), platform: "android", locale: "de" },
  ]);
  await fetch(`${STUB_URL}/__reset`).then((r) => r.body?.cancel());
  const flaky = event();
  await insert("notification_outbox", [flaky]);
  const first = await (await run()).json();
  assertEquals(first.retried, 1);
  assertEquals(first.dropped, 0);
  const [row] = await select<{ processed_at: string | null; attempts: number; last_error: string }>(
    `notification_outbox?id=eq.${flaky.id}&select=processed_at,attempts,last_error`,
  );
  assertEquals(row.processed_at, null);
  assertEquals(row.attempts, 1);
  assertEquals(row.last_error, "UNAVAILABLE");

  const notDue = await (await run()).json();
  assertEquals(notDue.claimed, 0, "backoff: the row is not due yet");

  // Skip the backoff, let FCM recover: the second attempt succeeds.
  await patch(`notification_outbox?id=eq.${flaky.id}`, { next_attempt_at: "2000-01-01T00:00:00Z" });
  await fetch(`${STUB_URL}/__fcm_heal`).then((r) => r.body?.cancel());
  const second = await (await run()).json();
  assertEquals(second.claimed, 1);
  assertEquals(second.retried, 0);
  const [done] = await select<{ processed_at: string | null; attempts: number }>(
    `notification_outbox?id=eq.${flaky.id}&select=processed_at,attempts`,
  );
  assert(done.processed_at !== null);
  assertEquals(done.attempts, 2);

  // Max attempts: a new event that already used 4 attempts and keeps failing.
  await fetch(`${STUB_URL}/__reset`).then((r) => r.body?.cancel());
  const doomed = event();
  await insert("notification_outbox", [{ ...doomed, attempts: 4 }]);
  const last = await (await run()).json();
  assertEquals(last.retried, 0);
  assertEquals(last.dropped, 1);
  const [fail] = await select<{ failed_at: string | null; processed_at: string | null }>(
    `notification_outbox?id=eq.${doomed.id}&select=failed_at,processed_at`,
  );
  assert(fail.failed_at !== null && fail.processed_at !== null, "marked failed, never retried");
  await patch(`device_tokens?token=eq.${T("ben-flaky")}`, { locale: "de" });
});

Deno.test("only mine: members not involved are skipped", async () => {
  await patch(`notification_prefs?user_id=eq.${cara}&group_id=eq.${G}`, { level: "mine" });
  await fetch(`${STUB_URL}/__reset`).then((r) => r.body?.cancel());
  await insert("notification_outbox", [event({}, { involved_member_ids: [M_ANNA, M_BEN] })]);
  await (await run()).body?.cancel();
  assertEquals((await sentTo(T("cara-ok"))).length, 0);
  assertEquals((await sentTo(T("ben-ok"))).length, 1);
});
