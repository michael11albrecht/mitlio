import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.8";
import type { FcmClient, SendResult } from "./fcm.ts";
import type { MemberLink, Pref, Token } from "./notify.ts";
import { type ClaimedEvent, type NotifyStore, runNotify } from "./notify_run.ts";

const G = "g-1";
const NOW = new Date("2026-11-20T12:00:00Z");

function ev(id: string, over: Partial<ClaimedEvent> = {}): ClaimedEvent {
  return {
    id,
    group_id: G,
    actor_user_id: "u-anna",
    event: "expense_added",
    entity_id: `x-${id}`,
    created_at: `2026-11-20T11:59:0${id.slice(-1)}Z`,
    attempts: 1,
    payload: {
      actor_name: "Anna",
      group_name: "Trip",
      title: "Fuel",
      amount_cents: 4200,
      currency: "EUR",
      involved_member_ids: ["m-anna", "m-ben"],
    },
    ...over,
  };
}

const members: (MemberLink & { group_id: string })[] = [
  { group_id: G, user_id: "u-anna", member_id: "m-anna" },
  { group_id: G, user_id: "u-ben", member_id: "m-ben" },
  { group_id: G, user_id: "u-cara", member_id: "m-cara" },
];
const tokensAll: Token[] = [
  { user_id: "u-ben", token: "tok-ben", platform: "android", locale: "de" },
  { user_id: "u-cara", token: "tok-cara", platform: "ios", locale: "en" },
];

class FakeStore implements NotifyStore {
  members = members;
  prefs: Pref[] = [];
  tokens = tokensAll;
  deleted: string[] = [];
  retried: { ids: string[]; error: string }[] = [];
  claimLimit = 0;
  requeueAll = true;
  constructor(private claimed: ClaimedEvent[]) {}
  claim(limit: number) {
    this.claimLimit = limit;
    return Promise.resolve(this.claimed);
  }
  loadMembers(_groupIds: string[]) {
    return Promise.resolve(this.members);
  }
  loadPrefs(_groupIds: string[]) {
    return Promise.resolve(this.prefs);
  }
  loadTokens(userIds: string[]) {
    return Promise.resolve(this.tokens.filter((t) => userIds.includes(t.user_id)));
  }
  deleteToken(token: string) {
    this.deleted.push(token);
    return Promise.resolve();
  }
  retry(ids: string[], error: string) {
    this.retried.push({ ids, error });
    return Promise.resolve(this.requeueAll ? ids.length : 0);
  }
}

class FakeFcm implements FcmClient {
  sent: Record<string, unknown>[] = [];
  constructor(private results: Record<string, SendResult> = {}) {}
  send(message: Record<string, unknown>) {
    this.sent.push(message);
    return Promise.resolve(this.results[message.token as string] ?? { ok: true as const });
  }
}

const run = (store: NotifyStore, fcm: FcmClient, batchSize = 200) =>
  runNotify({ store, fcm, now: () => NOW, batchSize, concurrency: 2 });

Deno.test("no pending rows: nothing loaded, zero stats", async () => {
  const store = new FakeStore([]);
  const fcm = new FakeFcm();
  assertEquals(await run(store, fcm, 7), {
    claimed: 0,
    recipients: 0,
    messages: 0,
    sent: 0,
    invalid_tokens: 0,
    retried: 0,
    dropped: 0,
    failed: 0,
  });
  assertEquals(store.claimLimit, 7);
  assertEquals(fcm.sent.length, 0);
});

Deno.test("one event: every member except the actor gets one message", async () => {
  const store = new FakeStore([ev("e1")]);
  const fcm = new FakeFcm();
  const stats = await run(store, fcm);
  assertEquals(fcm.sent.map((m) => m.token).sort(), ["tok-ben", "tok-cara"]);
  assertEquals(stats, {
    claimed: 1,
    recipients: 2,
    messages: 2,
    sent: 2,
    invalid_tokens: 0,
    retried: 0,
    dropped: 0,
    failed: 0,
  });
  assertEquals(store.retried, []);
  assertEquals(store.deleted, []);
});

Deno.test("prefs filter recipients; coalescing merges a burst into one message", async () => {
  const store = new FakeStore([ev("e1"), ev("e2"), ev("e3")]);
  store.prefs = [
    { user_id: "u-cara", group_id: G, level: "none", quiet_hours: null, hide_amounts: false },
  ];
  const fcm = new FakeFcm();
  const stats = await run(store, fcm);
  assertEquals(fcm.sent.length, 1);
  assertEquals(fcm.sent[0].token, "tok-ben");
  assertEquals(stats.claimed, 3);
  assertEquals(stats.recipients, 1);
  assertEquals(stats.messages, 1);
});

Deno.test("invalid token is deleted, not retried", async () => {
  const store = new FakeStore([ev("e1")]);
  const fcm = new FakeFcm({
    "tok-ben": { ok: false, kind: "invalid_token", code: "UNREGISTERED" },
  });
  const stats = await run(store, fcm);
  assertEquals(store.deleted, ["tok-ben"]);
  assertEquals(store.retried, []);
  assertEquals(stats.sent, 1);
  assertEquals(stats.invalid_tokens, 1);
});

Deno.test("retryable failure re-queues the events with the error code", async () => {
  const store = new FakeStore([ev("e1"), ev("e2")]);
  const fcm = new FakeFcm({ "tok-cara": { ok: false, kind: "retryable", code: "HTTP_503" } });
  const stats = await run(store, fcm);
  assertEquals(store.retried.length, 1);
  assertEquals(store.retried[0].ids.sort(), ["e1", "e2"]);
  assertEquals(store.retried[0].error, "HTTP_503");
  assertEquals(stats.retried, 2);
  assertEquals(stats.dropped, 0);
  assertEquals(stats.sent, 1);
});

Deno.test("events that hit the max attempts are counted as dropped", async () => {
  const store = new FakeStore([ev("e1", { attempts: 5 })]);
  store.requeueAll = false;
  const fcm = new FakeFcm({ "tok-cara": { ok: false, kind: "retryable", code: "HTTP_500" } });
  const stats = await run(store, fcm);
  assertEquals(stats.retried, 0);
  assertEquals(stats.dropped, 1);
});

Deno.test("permanent failure is counted, never retried or deleted", async () => {
  const store = new FakeStore([ev("e1")]);
  const fcm = new FakeFcm({
    "tok-ben": { ok: false, kind: "permanent", code: "SENDER_ID_MISMATCH" },
  });
  const stats = await run(store, fcm);
  assertEquals(stats.failed, 1);
  assertEquals(stats.sent, 1);
  assertEquals(store.retried, []);
  assertEquals(store.deleted, []);
});

Deno.test("recipients without a token are consumed silently", async () => {
  const store = new FakeStore([ev("e1")]);
  store.tokens = [];
  const fcm = new FakeFcm();
  const stats = await run(store, fcm);
  assertEquals(fcm.sent.length, 0);
  assertEquals(stats.claimed, 1);
  assertEquals(stats.recipients, 2);
  assertEquals(stats.messages, 0);
});

Deno.test("an event of an unknown group is consumed", async () => {
  const store = new FakeStore([ev("e1", { group_id: "ghost" })]);
  const fcm = new FakeFcm();
  const stats = await run(store, fcm);
  assertEquals(stats.recipients, 0);
  assertEquals(fcm.sent.length, 0);
});

Deno.test("sends run with bounded concurrency", async () => {
  const store = new FakeStore([ev("e1")]);
  store.tokens = Array.from({ length: 7 }, (_, i): Token => ({
    user_id: "u-ben",
    token: `t${i}`,
    platform: "android",
    locale: "en",
  }));
  let live = 0;
  let peak = 0;
  const fcm: FcmClient = {
    async send() {
      live++;
      peak = Math.max(peak, live);
      await new Promise((r) => setTimeout(r, 5));
      live--;
      return { ok: true };
    },
  };
  const stats = await run(store, fcm);
  assertEquals(stats.sent, 7);
  assertEquals(peak, 2);
});

Deno.test("a failure after the claim puts the rows back and rethrows", async () => {
  const store = new FakeStore([ev("e1"), ev("e2")]);
  store.loadPrefs = () => Promise.reject(new Error("db down"));
  await assertRejects(() => run(store, new FakeFcm()), Error, "db down");
  assertEquals(store.retried, [{ ids: ["e1", "e2"], error: "run_error" }]);
});
