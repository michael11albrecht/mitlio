// One run of the `notify` Edge Function (P6b-T05, ADR-13): claim -> resolve -> coalesce -> build
// -> send -> clean up / retry. All I/O sits behind NotifyStore and FcmClient so the flow is
// unit-testable; notify/index.ts wires PostgREST and the HTTP FCM client.
//
// Delivery semantics: a claimed outbox row is "processed". If any send for it failed in a way
// worth retrying, the row is re-queued (up to the max attempts, see 0017). A retry re-evaluates
// the whole event, so a recipient that already got the push may get it again; the collapse key
// (Android) and apns-collapse-id (iOS) per group make the device show one notification.

import type { FcmClient } from "./fcm.ts";
import {
  buildMessages,
  coalesce,
  type Delivery,
  type MemberLink,
  type OutboxEvent,
  type Pref,
  resolveRecipients,
  type Token,
} from "./notify.ts";

export interface ClaimedEvent extends OutboxEvent {
  /** Including this claim: 1 on the first run. */
  attempts: number;
}

export interface NotifyStore {
  /** Atomically claims up to `limit` due rows (FOR UPDATE SKIP LOCKED, see 0017). */
  claim(limit: number): Promise<ClaimedEvent[]>;
  loadMembers(groupIds: string[]): Promise<(MemberLink & { group_id: string })[]>;
  loadPrefs(groupIds: string[]): Promise<Pref[]>;
  loadTokens(userIds: string[]): Promise<Token[]>;
  deleteToken(token: string): Promise<void>;
  /** Re-queues rows after a failed send; returns how many were re-queued (the rest hit max). */
  retry(ids: string[], error: string): Promise<number>;
}

export interface RunStats {
  claimed: number;
  recipients: number;
  messages: number;
  sent: number;
  invalid_tokens: number;
  retried: number;
  dropped: number;
  failed: number;
}

export interface RunDeps {
  store: NotifyStore;
  fcm: FcmClient;
  now: () => Date;
  batchSize: number;
  concurrency: number;
}

export async function runNotify(deps: RunDeps): Promise<RunStats> {
  const stats: RunStats = {
    claimed: 0,
    recipients: 0,
    messages: 0,
    sent: 0,
    invalid_tokens: 0,
    retried: 0,
    dropped: 0,
    failed: 0,
  };
  const events = await deps.store.claim(deps.batchSize);
  stats.claimed = events.length;
  if (events.length === 0) return stats;
  try {
    await deliver(deps, events, stats);
  } catch (e) {
    // Claimed rows must not be lost because a read failed: put them back, then report.
    await deps.store.retry(events.map((x) => x.id), "run_error");
    throw e;
  }
  return stats;
}

async function deliver(deps: RunDeps, events: ClaimedEvent[], stats: RunStats): Promise<void> {
  const groupIds = [...new Set(events.map((e) => e.group_id))];
  const [members, prefs] = await Promise.all([
    deps.store.loadMembers(groupIds),
    deps.store.loadPrefs(groupIds),
  ]);
  const now = deps.now();

  const deliveries: Delivery[] = [];
  for (const event of events) {
    const inGroup = members.filter((m) => m.group_id === event.group_id);
    for (const user_id of resolveRecipients(event, inGroup, prefs, now)) {
      deliveries.push({ user_id, event });
    }
  }
  const batches = coalesce(deliveries);
  stats.recipients = new Set(batches.map((b) => b.user_id)).size;
  if (batches.length === 0) return;

  const tokens = await deps.store.loadTokens([...new Set(batches.map((b) => b.user_id))]);
  const outgoing = buildMessages(batches, tokens, prefs);
  stats.messages = outgoing.length;

  const retryIds = new Set<string>();
  let retryError = "";
  const dead = new Set<string>();
  let next = 0;
  const worker = async () => {
    while (next < outgoing.length) {
      const out = outgoing[next++];
      const res = await deps.fcm.send(out.message);
      if (res.ok) {
        stats.sent++;
      } else if (res.kind === "invalid_token") {
        dead.add(out.token);
      } else if (res.kind === "retryable") {
        for (const id of out.event_ids) retryIds.add(id);
        retryError = res.code;
      } else {
        stats.failed++;
      }
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, deps.concurrency) }, worker));

  for (const token of dead) {
    await deps.store.deleteToken(token);
    stats.invalid_tokens++;
  }
  if (retryIds.size > 0) {
    stats.retried = await deps.store.retry([...retryIds], retryError);
    stats.dropped = retryIds.size - stats.retried;
  }
}
