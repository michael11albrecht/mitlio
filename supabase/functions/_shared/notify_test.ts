import { assertEquals } from "jsr:@std/assert@1.0.8";
import {
  type Batch,
  buildMessages,
  coalesce,
  type Delivery,
  type EventKind,
  formatAmount,
  inQuietHours,
  LOC_KEYS,
  type MemberLink,
  type OutboxEvent,
  type Pref,
  type QuietHours,
  resolveRecipients,
  type Token,
} from "./notify.ts";

const G = "00000000-0000-0000-0001-000000000001";
const G2 = "00000000-0000-0000-0001-000000000002";
const ANNA = "u-anna";
const BEN = "u-ben";
const CARA = "u-cara";
const M_ANNA = "m-anna";
const M_BEN = "m-ben";
const M_CARA = "m-cara";
const NOW = new Date("2026-11-20T12:00:00Z");

const members: MemberLink[] = [
  { user_id: ANNA, member_id: M_ANNA },
  { user_id: BEN, member_id: M_BEN },
  { user_id: CARA, member_id: M_CARA },
];

let seq = 0;
function ev(over: Partial<OutboxEvent> = {}, kind: EventKind = "expense_added"): OutboxEvent {
  seq++;
  return {
    id: `ev-${String(seq).padStart(3, "0")}`,
    group_id: G,
    actor_user_id: ANNA,
    event: kind,
    entity_id: `x-${seq}`,
    created_at: `2026-11-20T11:59:${String(seq % 60).padStart(2, "0")}Z`,
    payload: {
      actor_name: "Anna",
      group_name: "Italy trip",
      title: "Fuel",
      amount_cents: 4200,
      currency: "EUR",
      involved_member_ids: [M_ANNA, M_BEN],
    },
    ...over,
  };
}

const pref = (user_id: string, over: Partial<Pref> = {}): Pref => ({
  user_id,
  group_id: G,
  level: "all",
  quiet_hours: null,
  hide_amounts: false,
  ...over,
});

// --- inQuietHours ------------------------------------------------------------------------------

const night: QuietHours = { start: "22:00", end: "07:00", utc_offset_minutes: 60 };

Deno.test("inQuietHours: null, malformed and empty windows never silence", () => {
  assertEquals(inQuietHours(null, NOW), false);
  assertEquals(inQuietHours({ ...night, start: "25:00" }, NOW), false);
  assertEquals(inQuietHours({ ...night, end: "7:00" }, NOW), false);
  assertEquals(inQuietHours({ ...night, start: "ab:cd" }, NOW), false);
  assertEquals(inQuietHours({ ...night, utc_offset_minutes: NaN }, NOW), false);
  assertEquals(inQuietHours({ start: "10:00", end: "10:00", utc_offset_minutes: 0 }, NOW), false);
});

Deno.test("inQuietHours: same-day window, boundaries start-inclusive end-exclusive", () => {
  const w: QuietHours = { start: "09:00", end: "17:00", utc_offset_minutes: 0 };
  assertEquals(inQuietHours(w, new Date("2026-11-20T08:59:00Z")), false);
  assertEquals(inQuietHours(w, new Date("2026-11-20T09:00:00Z")), true);
  assertEquals(inQuietHours(w, new Date("2026-11-20T16:59:00Z")), true);
  assertEquals(inQuietHours(w, new Date("2026-11-20T17:00:00Z")), false);
});

Deno.test("inQuietHours: window across midnight with a UTC offset", () => {
  // 21:30Z is 22:30 local (+60): inside. 06:30Z is 07:30 local: outside. 05:59Z is 06:59: inside.
  assertEquals(inQuietHours(night, new Date("2026-11-20T21:30:00Z")), true);
  assertEquals(inQuietHours(night, new Date("2026-11-20T06:30:00Z")), false);
  assertEquals(inQuietHours(night, new Date("2026-11-20T05:59:00Z")), true);
  assertEquals(inQuietHours(night, new Date("2026-11-20T12:00:00Z")), false);
  assertEquals(inQuietHours(night, new Date("2026-11-20T20:59:00Z")), false);
  assertEquals(inQuietHours(night, new Date("2026-11-20T21:00:00Z")), true);
});

Deno.test("inQuietHours: negative offsets wrap around the day", () => {
  const w: QuietHours = { start: "22:00", end: "07:00", utc_offset_minutes: -300 };
  // 03:30Z is 22:30 the previous day local.
  assertEquals(inQuietHours(w, new Date("2026-11-20T03:30:00Z")), true);
  assertEquals(inQuietHours(w, new Date("2026-11-20T12:30:00Z")), false);
});

// --- resolveRecipients -------------------------------------------------------------------------

Deno.test("resolveRecipients: all linked members except the actor, default pref is all", () => {
  assertEquals(resolveRecipients(ev(), members, [], NOW), [BEN, CARA]);
});

Deno.test("resolveRecipients: actor null (service write) notifies everyone", () => {
  assertEquals(resolveRecipients(ev({ actor_user_id: null }), members, [], NOW), [
    ANNA,
    BEN,
    CARA,
  ]);
});

Deno.test("resolveRecipients: duplicate links count once", () => {
  assertEquals(
    resolveRecipients(ev(), [...members, { user_id: BEN, member_id: "m-ben-2" }], [], NOW),
    [BEN, CARA],
  );
});

Deno.test("resolveRecipients: level none drops the user", () => {
  assertEquals(resolveRecipients(ev(), members, [pref(BEN, { level: "none" })], NOW), [CARA]);
});

Deno.test("resolveRecipients: level mine keeps involved members only", () => {
  const prefs = [pref(BEN, { level: "mine" }), pref(CARA, { level: "mine" })];
  assertEquals(resolveRecipients(ev(), members, prefs, NOW), [BEN]);
});

Deno.test("resolveRecipients: mine without involved list drops", () => {
  const e = ev();
  delete e.payload.involved_member_ids;
  assertEquals(resolveRecipients(e, members, [pref(BEN, { level: "mine" })], NOW), [CARA]);
});

Deno.test("resolveRecipients: mine and settlements use from/to; member_joined never matches", () => {
  const s = ev({ payload: { involved_member_ids: [M_CARA, M_ANNA] } }, "settlement_added");
  assertEquals(resolveRecipients(s, members, [pref(BEN, { level: "mine" })], NOW), [CARA]);
  assertEquals(resolveRecipients(s, members, [pref(CARA, { level: "mine" })], NOW), [BEN, CARA]);
  const j = ev({ payload: { involved_member_ids: [M_BEN] } }, "member_joined");
  assertEquals(resolveRecipients(j, members, [pref(BEN, { level: "mine" })], NOW), [CARA]);
});

Deno.test("resolveRecipients: quiet hours drop, outside quiet hours deliver", () => {
  const quiet = pref(BEN, { quiet_hours: { start: "11:00", end: "13:00", utc_offset_minutes: 0 } });
  assertEquals(resolveRecipients(ev(), members, [quiet], NOW), [CARA]);
  const later = new Date("2026-11-20T14:00:00Z");
  assertEquals(resolveRecipients(ev(), members, [quiet], later), [BEN, CARA]);
});

Deno.test("resolveRecipients: prefs of another group do not apply", () => {
  const other = pref(BEN, { level: "none", group_id: G2 });
  assertEquals(resolveRecipients(ev(), members, [other], NOW), [BEN, CARA]);
});

Deno.test("resolveRecipients: prefs of another user do not apply", () => {
  assertEquals(resolveRecipients(ev(), members, [pref(ANNA, { level: "none" })], NOW), [
    BEN,
    CARA,
  ]);
});

Deno.test("resolveRecipients: no members, no recipients", () => {
  assertEquals(resolveRecipients(ev(), [], [], NOW), []);
});

// --- coalesce ----------------------------------------------------------------------------------

const d = (user_id: string, event: OutboxEvent): Delivery => ({ user_id, event });

Deno.test("coalesce: empty in, empty out", () => {
  assertEquals(coalesce([]), []);
});

Deno.test("coalesce: one batch per recipient and group, in time order", () => {
  const a = ev({ created_at: "2026-11-20T11:00:02Z" });
  const b = ev({ created_at: "2026-11-20T11:00:01Z" });
  const c = ev({ group_id: G2, created_at: "2026-11-20T11:00:03Z" });
  const out = coalesce([d(BEN, a), d(BEN, b), d(CARA, a), d(BEN, c)]);
  assertEquals(out.map((x) => [x.user_id, x.group_id, x.events.map((e) => e.id)]), [
    [BEN, G, [b.id, a.id]],
    [CARA, G, [a.id]],
    [BEN, G2, [c.id]],
  ]);
});

Deno.test("coalesce: equal timestamps order by id, duplicates by id dropped", () => {
  const t = "2026-11-20T11:00:00Z";
  const a = ev({ id: "b", created_at: t });
  const b = ev({ id: "a", created_at: t });
  const c = ev({ id: "c", created_at: t });
  const out = coalesce([d(BEN, a), d(BEN, c), d(BEN, b), d(BEN, a), d(BEN, c)]);
  assertEquals(out[0].events.map((e) => e.id), ["a", "b", "c"]);
});

Deno.test("coalesce: same id for two recipients is kept for both", () => {
  const a = ev();
  assertEquals(coalesce([d(BEN, a), d(CARA, a)]).length, 2);
});

Deno.test("coalesce: events of one expense collapse to the net change", () => {
  const e = "x-same";
  const t = (n: number) => `2026-11-20T11:00:0${n}Z`;
  const added = ev({ entity_id: e, created_at: t(1) }, "expense_added");
  const changed = ev({ entity_id: e, created_at: t(2) }, "expense_changed");
  const changed2 = ev({ entity_id: e, created_at: t(3) }, "expense_changed");
  const deleted = ev({ entity_id: e, created_at: t(4) }, "expense_deleted");

  const kinds = (events: OutboxEvent[]) =>
    coalesce(events.map((x) => d(BEN, x))).flatMap((b) => b.events.map((x) => x.event));

  assertEquals(kinds([added, changed]), ["expense_added"]);
  assertEquals(kinds([added, changed, deleted]), []);
  assertEquals(kinds([added, deleted]), []);
  assertEquals(kinds([changed, deleted]), ["expense_deleted"]);
  assertEquals(kinds([deleted]), ["expense_deleted"]);
  assertEquals(kinds([changed, changed2]), ["expense_changed"]);
  assertEquals(kinds([changed]), ["expense_changed"]);
  assertEquals(kinds([added]), ["expense_added"]);
});

Deno.test("coalesce: the collapsed event carries the latest payload", () => {
  const e = "x-p";
  const added = ev({ entity_id: e, created_at: "2026-11-20T11:00:01Z" }, "expense_added");
  const changed = ev({
    entity_id: e,
    created_at: "2026-11-20T11:00:02Z",
    payload: { ...added.payload, amount_cents: 9900 },
  }, "expense_changed");
  const [b] = coalesce([d(BEN, added), d(BEN, changed)]);
  assertEquals(b.events.length, 1);
  assertEquals(b.events[0].id, changed.id);
  assertEquals(b.events[0].payload.amount_cents, 9900);
});

Deno.test("coalesce: a batch that nets to nothing is dropped, others stay, order is by first event", () => {
  const e = "x-gone";
  const a1 = ev({ entity_id: e, created_at: "2026-11-20T11:00:01Z" }, "expense_added");
  const other = ev({ created_at: "2026-11-20T11:00:02Z" });
  const a2 = ev({ entity_id: e, created_at: "2026-11-20T11:00:03Z" }, "expense_deleted");
  const out = coalesce([d(BEN, a1), d(BEN, other), d(BEN, a2), d(CARA, a1), d(CARA, a2)]);
  assertEquals(out.length, 1);
  assertEquals(out[0].user_id, BEN);
  assertEquals(out[0].events.map((x) => x.id), [other.id]);
});

Deno.test("coalesce: events of different entities stay separate and keep order", () => {
  const a = ev({ created_at: "2026-11-20T11:00:01Z" });
  const b = ev({ created_at: "2026-11-20T11:00:02Z" });
  const c = ev({ created_at: "2026-11-20T11:00:03Z" }, "settlement_added");
  const [batch] = coalesce([d(BEN, c), d(BEN, a), d(BEN, b)]);
  assertEquals(batch.events.map((x) => x.id), [a.id, b.id, c.id]);
});

// --- formatAmount ------------------------------------------------------------------------------

Deno.test("formatAmount: locale decimals, always two digits", () => {
  assertEquals(formatAmount(4200, "EUR", "de-DE").replace(/\s/g, " "), "42,00 €");
  assertEquals(formatAmount(4200, "EUR", "en-US"), "€42.00");
  assertEquals(formatAmount(5, "EUR", "en-US"), "€0.05");
  assertEquals(formatAmount(123456, "USD", "en-US"), "$1,234.56");
  assertEquals(formatAmount(500, "JPY", "en-US"), "¥5.00");
});

Deno.test("formatAmount: bad locale or currency falls back to a plain string", () => {
  assertEquals(formatAmount(4200, "EUR", "not a locale!!"), "42.00 EUR");
  assertEquals(formatAmount(4200, "eu", "en-US"), "42.00 eu");
});

// --- buildMessages -----------------------------------------------------------------------------

const batchOf = (user_id: string, events: OutboxEvent[], group_id = G): Batch => ({
  user_id,
  group_id,
  events,
});
const android = (user_id: string, locale = "en"): Token => ({
  user_id,
  token: `tok-android-${user_id}`,
  platform: "android",
  locale,
});
const ios = (user_id: string, locale = "de"): Token => ({
  user_id,
  token: `tok-ios-${user_id}`,
  platform: "ios",
  locale,
});

// deno-lint-ignore no-explicit-any
type Json = any;
const androidBody = (m: Json) => m.message.android.notification;
const iosAlert = (m: Json) => m.message.apns.payload.aps.alert;

Deno.test("buildMessages: single added expense on android", () => {
  const e = ev({ entity_id: "exp-1" });
  const [m] = buildMessages([batchOf(BEN, [e])], [android(BEN, "en-US")], []);
  assertEquals(m.user_id, BEN);
  assertEquals(m.token, `tok-android-${BEN}`);
  assertEquals(m.event_ids, [e.id]);
  assertEquals(m.message.token, m.token);
  assertEquals(androidBody(m), {
    title: "Italy trip",
    body_loc_key: "push_expense_added",
    body_loc_args: ["Anna", "Fuel", "€42.00"],
    tag: G,
  });
  assertEquals((m.message as Json).android.collapse_key, G);
  assertEquals((m.message as Json).android.priority, "high");
  assertEquals((m.message as Json).apns, undefined);
  assertEquals(m.message.data, {
    group_id: G,
    event: "expense_added",
    expense_id: "exp-1",
    link: `mitlio://group/${G}/expense/exp-1`,
    hide_amounts: "false",
  });
});

Deno.test("buildMessages: single added expense on iOS uses apns alert loc-keys, German amount", () => {
  const e = ev({ entity_id: "exp-1" });
  const [m] = buildMessages([batchOf(BEN, [e])], [ios(BEN, "de-DE")], []);
  assertEquals(iosAlert(m)["loc-key"], "push_expense_added");
  assertEquals(iosAlert(m)["loc-args"][2].replace(/\s/g, " "), "42,00 €");
  assertEquals(iosAlert(m).title, "Italy trip");
  assertEquals((m.message as Json).apns.headers, { "apns-collapse-id": G });
  assertEquals((m.message as Json).apns.payload.aps.sound, "default");
  assertEquals((m.message as Json).android, undefined);
});

Deno.test("buildMessages: one message per token of the recipient, none for other users", () => {
  const out = buildMessages(
    [batchOf(BEN, [ev()])],
    [android(BEN), ios(BEN), android(CARA)],
    [],
  );
  assertEquals(out.map((m) => m.token), [`tok-android-${BEN}`, `tok-ios-${BEN}`]);
});

Deno.test("buildMessages: no tokens, no messages", () => {
  assertEquals(buildMessages([batchOf(BEN, [ev()])], [], []), []);
  assertEquals(buildMessages([], [android(BEN)], []), []);
});

Deno.test("buildMessages: empty locale falls back to en", () => {
  const [m] = buildMessages([batchOf(BEN, [ev()])], [android(BEN, "")], []);
  assertEquals(androidBody(m).body_loc_args[2], "€42.00");
});

Deno.test("buildMessages: each single-event kind uses its own key and args", () => {
  const cases: [EventKind, string, string[]][] = [
    ["expense_added", "push_expense_added", ["Anna", "Fuel", "€42.00"]],
    ["expense_changed", "push_expense_changed", ["Anna", "Fuel", "€42.00"]],
    ["expense_deleted", "push_expense_deleted", ["Anna", "Fuel"]],
    ["settlement_added", "push_settlement_added", ["Anna", "€42.00"]],
  ];
  for (const [kind, key, args] of cases) {
    const [m] = buildMessages([batchOf(BEN, [ev({}, kind)])], [android(BEN, "en-US")], []);
    assertEquals(androidBody(m).body_loc_key, key);
    assertEquals(androidBody(m).body_loc_args, args);
  }
});

Deno.test("buildMessages: member_joined names the member and the group", () => {
  const j = ev(
    { payload: { actor_name: "Anna", group_name: "Italy trip", member_name: "Ben" } },
    "member_joined",
  );
  const [m] = buildMessages([batchOf(CARA, [j])], [android(CARA)], []);
  assertEquals(androidBody(m).body_loc_key, "push_member_joined");
  assertEquals(androidBody(m).body_loc_args, ["Ben", "Italy trip"]);
  assertEquals(m.message.data, {
    group_id: G,
    event: "member_joined",
    link: `mitlio://group/${G}`,
    hide_amounts: "false",
  });
  const j2 = ev({ payload: { actor_name: "Anna", group_name: "Italy trip" } }, "member_joined");
  const [m2] = buildMessages([batchOf(CARA, [j2])], [android(CARA)], []);
  assertEquals(androidBody(m2).body_loc_args, ["Anna", "Italy trip"]);
});

Deno.test("buildMessages: missing display fields fall back to ?, amount to empty", () => {
  const e = ev({ payload: {} });
  const [m] = buildMessages([batchOf(BEN, [e])], [android(BEN)], []);
  assertEquals(androidBody(m).title, "?");
  assertEquals(androidBody(m).body_loc_args, ["?", "?", ""]);
  const noCurrency = ev({ payload: { amount_cents: 100 } });
  const [m2] = buildMessages([batchOf(BEN, [noCurrency])], [android(BEN)], []);
  assertEquals(androidBody(m2).body_loc_args[2], "");
  const noAmount = ev({ payload: { currency: "EUR" } });
  const [m3] = buildMessages([batchOf(BEN, [noAmount])], [android(BEN)], []);
  assertEquals(androidBody(m3).body_loc_args[2], "");
});

Deno.test("buildMessages: deleted expense has no expense link; settlement links to the group", () => {
  const del = ev({ entity_id: "exp-9" }, "expense_deleted");
  const [m] = buildMessages([batchOf(BEN, [del])], [android(BEN)], []);
  assertEquals(m.message.data, {
    group_id: G,
    event: "expense_deleted",
    link: `mitlio://group/${G}`,
    hide_amounts: "false",
  });
  const chg = ev({ entity_id: "exp-8" }, "expense_changed");
  const [m2] = buildMessages([batchOf(BEN, [chg])], [android(BEN)], []);
  assertEquals((m2.message.data as Json).link, `mitlio://group/${G}/expense/exp-8`);
  const set = ev({ entity_id: "s-1" }, "settlement_added");
  const [m3] = buildMessages([batchOf(BEN, [set])], [android(BEN)], []);
  assertEquals((m3.message.data as Json).expense_id, undefined);
  assertEquals((m3.message.data as Json).link, `mitlio://group/${G}`);
});

Deno.test("buildMessages: several expenses added by one actor", () => {
  const events = [ev(), ev(), ev()];
  const [m] = buildMessages([batchOf(BEN, events)], [android(BEN)], []);
  assertEquals(androidBody(m).body_loc_key, "push_expenses_added");
  assertEquals(androidBody(m).body_loc_args, ["Anna", "3", "Italy trip"]);
  assertEquals(m.event_ids, events.map((e) => e.id));
  assertEquals(m.message.data, {
    group_id: G,
    event: "group_updates",
    link: `mitlio://group/${G}`,
    hide_amounts: "false",
  });
});

Deno.test("buildMessages: mixed or multi-actor batches say how many updates", () => {
  const mixed = [ev(), ev({}, "expense_changed")];
  const [a] = buildMessages([batchOf(BEN, mixed)], [android(BEN)], []);
  assertEquals(androidBody(a).body_loc_key, "push_group_updates");
  assertEquals(androidBody(a).body_loc_args, ["2", "Italy trip"]);
  const twoActors = [ev(), ev({ actor_user_id: CARA })];
  const [b] = buildMessages([batchOf(BEN, twoActors)], [android(BEN)], []);
  assertEquals(androidBody(b).body_loc_key, "push_group_updates");
});

Deno.test("buildMessages: hide_amounts gives a generic body without title or amount", () => {
  const prefs = [pref(BEN, { hide_amounts: true })];
  const [one] = buildMessages([batchOf(BEN, [ev()])], [android(BEN)], prefs);
  assertEquals(androidBody(one).body_loc_key, "push_generic");
  assertEquals(androidBody(one).body_loc_args, ["Italy trip"]);
  assertEquals((one.message.data as Json).hide_amounts, "true");
  const [many] = buildMessages([batchOf(BEN, [ev(), ev()])], [ios(BEN)], prefs);
  assertEquals(iosAlert(many)["loc-key"], "push_generic");
  assertEquals(JSON.stringify(many).includes("Fuel"), false);
  assertEquals(JSON.stringify(many).includes("42"), false);
});

Deno.test("buildMessages: hide_amounts of another user or group does not apply", () => {
  const prefs = [
    pref(CARA, { hide_amounts: true }),
    pref(BEN, { hide_amounts: true, group_id: G2 }),
  ];
  const [m] = buildMessages([batchOf(BEN, [ev()])], [android(BEN)], prefs);
  assertEquals(androidBody(m).body_loc_key, "push_expense_added");
});

Deno.test("buildMessages: group name comes from the newest event", () => {
  const old = ev({ payload: { actor_name: "Anna", group_name: "Old name" } });
  const fresh = ev({ payload: { actor_name: "Anna", group_name: "New name" } });
  const [m] = buildMessages([batchOf(BEN, [old, fresh])], [android(BEN)], []);
  assertEquals(androidBody(m).title, "New name");
});

Deno.test("buildMessages: payload carries ids and display strings only", () => {
  const e = ev({ payload: { ...ev().payload, note: "secret note", iban: "DE89" } as Json });
  const [m] = buildMessages([batchOf(BEN, [e])], [android(BEN)], []);
  const text = JSON.stringify(m.message);
  assertEquals(text.includes("secret note"), false);
  assertEquals(text.includes("DE89"), false);
});

Deno.test("LOC_KEYS covers every key buildMessages can emit", () => {
  const emitted = new Set<string>();
  const kinds: EventKind[] = [
    "expense_added",
    "expense_changed",
    "expense_deleted",
    "settlement_added",
    "member_joined",
  ];
  for (const k of kinds) {
    const [m] = buildMessages([batchOf(BEN, [ev({}, k)])], [android(BEN)], []);
    emitted.add(androidBody(m).body_loc_key);
  }
  for (const events of [[ev(), ev()], [ev(), ev({}, "expense_changed")]]) {
    const [m] = buildMessages([batchOf(BEN, events)], [android(BEN)], []);
    emitted.add(androidBody(m).body_loc_key);
  }
  const [h] = buildMessages([batchOf(BEN, [ev()])], [android(BEN)], [
    pref(BEN, { hide_amounts: true }),
  ]);
  emitted.add(androidBody(h).body_loc_key);
  assertEquals([...emitted].sort(), [...LOC_KEYS].sort());
});
