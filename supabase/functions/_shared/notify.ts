// Pure logic of the push `notify` Edge Function (P6b-T04, ADR-13). No I/O, no Deno globals, so it
// is unit-testable: the Edge Function (P6b-T05) claims outbox rows, loads members, prefs and
// tokens, calls these functions and sends the result through an FCM client.
//
// Pipeline: resolveRecipients (per event) -> coalesce (per recipient and group) -> buildMessages
// (FCM HTTP v1 bodies with loc-keys, rendered by the OS in the device language).
//
// Payload rule (plan P6b): only ids and display strings. Never IBAN or notes.

export type EventKind =
  | "expense_added"
  | "expense_changed"
  | "expense_deleted"
  | "settlement_added"
  | "member_joined";

export type Level = "all" | "mine" | "none";

/** Display data the outbox trigger (0016) writes into `notification_outbox.payload`. */
export interface EventPayload {
  actor_name?: string;
  group_name?: string;
  title?: string;
  amount_cents?: number;
  currency?: string;
  /** Expenses: members with a payer or share row. Settlements: from and to. */
  involved_member_ids?: string[];
  /** member_joined: the person who joined. */
  member_name?: string;
}

export interface OutboxEvent {
  id: string;
  group_id: string;
  actor_user_id: string | null;
  event: EventKind;
  entity_id: string;
  payload: EventPayload;
  created_at: string;
}

/** A group member that is linked to an account (`members.user_id`). */
export interface MemberLink {
  user_id: string;
  member_id: string;
}

export interface QuietHours {
  /** `HH:MM`, local time of the device that set it. */
  start: string;
  end: string;
  /** Local offset to UTC in minutes at the time it was set. */
  utc_offset_minutes: number;
}

export interface Pref {
  user_id: string;
  group_id: string;
  level: Level;
  quiet_hours: QuietHours | null;
  hide_amounts: boolean;
}

export interface Token {
  user_id: string;
  token: string;
  platform: "android" | "ios";
  /** BCP-47 tag, used to format amounts. */
  locale: string;
}

export interface Delivery {
  user_id: string;
  event: OutboxEvent;
}

export interface Batch {
  user_id: string;
  group_id: string;
  events: OutboxEvent[];
}

export interface Outgoing {
  user_id: string;
  token: string;
  /** Outbox rows this message reports on. */
  event_ids: string[];
  /** Body of the FCM HTTP v1 request: `{message: <this>}`. */
  message: Record<string, unknown>;
}

/** Loc-keys the apps must define in every locale (P6b-T09). */
export const LOC_KEYS = [
  "push_expense_added",
  "push_expense_changed",
  "push_expense_deleted",
  "push_settlement_added",
  "push_member_joined",
  "push_expenses_added",
  "push_group_updates",
  "push_generic",
] as const;

const DEFAULT_LEVEL: Level = "all";
const FALLBACK_LOCALE = "en";
const FALLBACK_TEXT = "?";
const MINUTES_PER_DAY = 1440;

// ---------------------------------------------------------------------------
// resolveRecipients

function parseClock(value: string): number | null {
  const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(value);
  return m ? Number(m[1]) * 60 + Number(m[2]) : null;
}

/** True when `now` falls in the quiet window. Malformed windows never silence anyone. */
export function inQuietHours(quiet: QuietHours | null, now: Date): boolean {
  if (!quiet || !Number.isFinite(quiet.utc_offset_minutes)) return false;
  const start = parseClock(quiet.start);
  const end = parseClock(quiet.end);
  if (start === null || end === null || start === end) return false;
  const utc = now.getUTCHours() * 60 + now.getUTCMinutes();
  const local = (((utc + quiet.utc_offset_minutes) % MINUTES_PER_DAY) + MINUTES_PER_DAY) %
    MINUTES_PER_DAY;
  return start < end ? local >= start && local < end : local >= start || local < end;
}

function isMine(event: OutboxEvent, memberId: string): boolean {
  if (event.event === "member_joined") return false;
  return (event.payload.involved_member_ids ?? []).includes(memberId);
}

/**
 * User ids that get a push for `event`: linked group members, minus the actor, minus users whose
 * pref is `none`, in quiet hours, or `mine` without being involved. Default pref is `all`.
 */
export function resolveRecipients(
  event: OutboxEvent,
  members: MemberLink[],
  prefs: Pref[],
  now: Date,
): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const m of members) {
    if (seen.has(m.user_id)) continue;
    seen.add(m.user_id);
    if (m.user_id === event.actor_user_id) continue;
    const pref = prefs.find((p) => p.user_id === m.user_id && p.group_id === event.group_id);
    const level = pref?.level ?? DEFAULT_LEVEL;
    if (level === "none") continue;
    if (level === "mine" && !isMine(event, m.member_id)) continue;
    if (inQuietHours(pref?.quiet_hours ?? null, now)) continue;
    out.push(m.user_id);
  }
  return out;
}

// ---------------------------------------------------------------------------
// coalesce

/** Net effect of the ordered events of one entity, or null when they cancel out. */
function netKind(events: OutboxEvent[]): EventKind | null {
  const first = events[0].event;
  const last = events[events.length - 1].event;
  if (last === "expense_deleted") return first === "expense_added" ? null : "expense_deleted";
  if (first === "expense_added") return "expense_added";
  return events.length === 1 ? first : "expense_changed";
}

function byTimeThenId(a: OutboxEvent, b: OutboxEvent): number {
  if (a.created_at !== b.created_at) return a.created_at < b.created_at ? -1 : 1;
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
}

/**
 * One batch per (recipient, group). Events are ordered by time, duplicates by id dropped, and all
 * events of one entity collapse into one (added + deleted in the same window vanishes).
 */
export function coalesce(deliveries: Delivery[]): Batch[] {
  const groups = new Map<string, { user_id: string; group_id: string; events: OutboxEvent[] }>();
  const seen = new Set<string>();
  for (const d of [...deliveries].sort((a, b) => byTimeThenId(a.event, b.event))) {
    const key = `${d.user_id}|${d.event.id}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const gkey = `${d.user_id}|${d.event.group_id}`;
    let g = groups.get(gkey);
    if (!g) {
      g = { user_id: d.user_id, group_id: d.event.group_id, events: [] };
      groups.set(gkey, g);
    }
    g.events.push(d.event);
  }

  const batches: Batch[] = [];
  for (const g of groups.values()) {
    const byEntity = new Map<string, OutboxEvent[]>();
    for (const e of g.events) {
      const list = byEntity.get(e.entity_id) ?? [];
      list.push(e);
      byEntity.set(e.entity_id, list);
    }
    const events: OutboxEvent[] = [];
    for (const list of byEntity.values()) {
      const kind = netKind(list);
      if (kind !== null) events.push({ ...list[list.length - 1], event: kind });
    }
    if (events.length > 0) batches.push({ user_id: g.user_id, group_id: g.group_id, events });
  }
  return batches;
}

// ---------------------------------------------------------------------------
// buildMessages

/** Amount for display. `cents` is an integer, always shown with two decimals. */
export function formatAmount(cents: number, currency: string, locale: string): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(cents / 100);
  } catch (_) {
    // Unknown locale or currency code: a readable fallback beats losing the notification.
    return `${(cents / 100).toFixed(2)} ${currency}`;
  }
}

interface Body {
  key: string;
  args: string[];
}

function bodyFor(batch: Batch, group: string, hideAmounts: boolean, locale: string): Body {
  const events = batch.events;
  if (hideAmounts) return { key: "push_generic", args: [group] };
  if (events.length === 1) {
    const e = events[0];
    const actor = e.payload.actor_name ?? FALLBACK_TEXT;
    const title = e.payload.title ?? FALLBACK_TEXT;
    const amount = e.payload.amount_cents !== undefined && e.payload.currency
      ? formatAmount(e.payload.amount_cents, e.payload.currency, locale)
      : "";
    switch (e.event) {
      case "expense_added":
        return { key: "push_expense_added", args: [actor, title, amount] };
      case "expense_changed":
        return { key: "push_expense_changed", args: [actor, title, amount] };
      case "expense_deleted":
        return { key: "push_expense_deleted", args: [actor, title] };
      case "settlement_added":
        return { key: "push_settlement_added", args: [actor, amount] };
      case "member_joined":
        return { key: "push_member_joined", args: [e.payload.member_name ?? actor, group] };
    }
  }
  const sameActor = events.every((e) => e.actor_user_id === events[0].actor_user_id);
  if (sameActor && events.every((e) => e.event === "expense_added")) {
    const actor = events[0].payload.actor_name ?? FALLBACK_TEXT;
    return { key: "push_expenses_added", args: [actor, String(events.length), group] };
  }
  return { key: "push_group_updates", args: [String(events.length), group] };
}

function dataFor(batch: Batch, hideAmounts: boolean): Record<string, string> {
  const data: Record<string, string> = { group_id: batch.group_id };
  let link = `mitlio://group/${batch.group_id}`;
  if (batch.events.length === 1) {
    const e = batch.events[0];
    data.event = e.event;
    if (e.event === "expense_added" || e.event === "expense_changed") {
      data.expense_id = e.entity_id;
      link += `/expense/${e.entity_id}`;
    }
  } else {
    data.event = "group_updates";
  }
  data.link = link;
  data.hide_amounts = String(hideAmounts);
  return data;
}

/**
 * FCM HTTP v1 messages, one per (recipient token, group batch). Alert text is a loc-key plus
 * args, rendered by the OS in the device language. `hide_amounts` switches to a generic body.
 */
export function buildMessages(batches: Batch[], tokens: Token[], prefs: Pref[]): Outgoing[] {
  const out: Outgoing[] = [];
  for (const batch of batches) {
    const pref = prefs.find((p) => p.user_id === batch.user_id && p.group_id === batch.group_id);
    const hide = pref?.hide_amounts ?? false;
    const group = batch.events[batch.events.length - 1].payload.group_name ?? FALLBACK_TEXT;
    const event_ids = batch.events.map((e) => e.id);
    for (const t of tokens) {
      if (t.user_id !== batch.user_id) continue;
      const body = bodyFor(batch, group, hide, t.locale || FALLBACK_LOCALE);
      const platform = t.platform === "ios"
        ? {
          apns: {
            headers: { "apns-collapse-id": batch.group_id },
            payload: {
              aps: {
                alert: { title: group, "loc-key": body.key, "loc-args": body.args },
                sound: "default",
              },
            },
          },
        }
        : {
          android: {
            collapse_key: batch.group_id,
            priority: "high",
            notification: {
              title: group,
              body_loc_key: body.key,
              body_loc_args: body.args,
              tag: batch.group_id,
            },
          },
        };
      out.push({
        user_id: batch.user_id,
        token: t.token,
        event_ids,
        message: { token: t.token, data: dataFor(batch, hide), ...platform },
      });
    }
  }
  return out;
}
