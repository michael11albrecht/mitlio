// Edge Function `notify` (P6b-T05, ADR-13). Called every minute by pg_cron (public.invoke_notify,
// migration 0017). Claims pending outbox rows and sends the pushes through FCM HTTP v1.
// Logic: _shared/notify_run.ts and _shared/notify.ts. Secrets (never in the repo):
//   FCM_SERVICE_ACCOUNT  service-account JSON of the Firebase project (docs/BLOCKERS.md item 6)
//   FCM_ENDPOINT         https://fcm.googleapis.com/v1/projects/<project-id>/messages:send
//   NOTIFY_TOKEN         shared with the cron job (Vault: notify_token), sent as x-notify-token
// Logs one JSON line per run with counts only (P6b-T10), never names, titles, tokens or ids.
// Optional monitoring (P6b-T10, ADR-14): SENTRY_DSN (EU project) turns on a Sentry cron monitor
// check-in per run, `error` on a failed run, a high failure rate, a stale backlog or dropped rows;
// NOTIFY_SENTRY_MONITOR (slug, default "notify"), NOTIFY_ALERT_FAILURE_RATE (0.5),
// NOTIFY_ALERT_BACKLOG_SECONDS (600). Logic: _shared/notify_monitor.ts.
import { constantTimeEquals } from "../_shared/fuel.ts";
import { createFcmClient, parseServiceAccount } from "../_shared/fcm.ts";
import { assess, createMonitor, type Health } from "../_shared/notify_monitor.ts";
import { type ClaimedEvent, type NotifyStore, runNotify } from "../_shared/notify_run.ts";

const env = (name: string): string => Deno.env.get(name) ?? "";
const envInt = (name: string, fallback: number): number => {
  const n = Number(env(name));
  return Number.isInteger(n) && n > 0 ? n : fallback;
};

async function rest(path: string, init: RequestInit = {}): Promise<Response> {
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  return await fetch(`${env("SUPABASE_URL")}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
    signal: AbortSignal.timeout(10000),
  });
}

async function get<T>(path: string): Promise<T[]> {
  const res = await rest(path);
  if (!res.ok) throw new Error(`read failed: ${path.split("?")[0]} ${res.status}`);
  return await res.json();
}

const envNumber = (name: string, fallback: number): number => {
  const n = Number(env(name));
  return env(name) !== "" && Number.isFinite(n) && n >= 0 ? n : fallback;
};

async function readHealth(): Promise<Health | null> {
  try {
    const res = await rest("rpc/notification_outbox_health", { method: "POST", body: "{}" });
    if (!res.ok) throw new Error(`status ${res.status}`);
    const rows = (await res.json()) as Health[];
    return rows[0] ?? null;
  } catch (e) {
    console.error(JSON.stringify({
      event: "notify_health",
      error: "health_unavailable",
      message: (e as Error).message,
    }));
    return null;
  }
}

const inList = (values: string[]) => `in.(${values.map((v) => `"${v}"`).join(",")})`;

function createStore(maxAttempts: number): NotifyStore {
  return {
    async claim(limit) {
      const res = await rest("rpc/claim_notification_outbox", {
        method: "POST",
        body: JSON.stringify({ p_limit: limit }),
      });
      if (!res.ok) throw new Error(`claim failed: ${res.status}`);
      return (await res.json()) as ClaimedEvent[];
    },
    loadMembers: (groupIds) =>
      get(
        `group_memberships?group_id=${encodeURIComponent(inList(groupIds))}` +
          `&member_id=not.is.null&select=group_id,user_id,member_id`,
      ),
    loadPrefs: (groupIds) =>
      get(
        `notification_prefs?group_id=${encodeURIComponent(inList(groupIds))}` +
          `&select=user_id,group_id,level,quiet_hours,hide_amounts`,
      ),
    loadTokens: (userIds) =>
      get(
        `device_tokens?user_id=${encodeURIComponent(inList(userIds))}` +
          `&select=user_id,token,platform,locale`,
      ),
    async deleteToken(token) {
      const res = await rest(`device_tokens?token=eq.${encodeURIComponent(token)}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error(`token cleanup failed: ${res.status}`);
    },
    async retry(ids, error) {
      const res = await rest("rpc/retry_notification_outbox", {
        method: "POST",
        body: JSON.stringify({ p_ids: ids, p_error: error, p_max_attempts: maxAttempts }),
      });
      if (!res.ok) throw new Error(`retry failed: ${res.status}`);
      return Number(await res.json());
    },
  };
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

const monitor = createMonitor({
  dsn: env("SENTRY_DSN"),
  slug: env("NOTIFY_SENTRY_MONITOR") || "notify",
  fetch: (url, init) => fetch(url, init),
});

async function checkIn(status: "ok" | "error", ms: number, reasons: string[]): Promise<void> {
  const result = await monitor.checkIn(status, ms);
  if (result === "disabled") return;
  const line = { event: "notify_monitor", status, reasons, check_in: result };
  if (result === "sent") console.log(JSON.stringify(line));
  else console.error(JSON.stringify(line));
}

async function handle(req: Request): Promise<Response> {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const token = env("NOTIFY_TOKEN");
  if (token === "" || !constantTimeEquals(req.headers.get("x-notify-token") ?? "", token)) {
    return json({ error: "unauthorized" }, 401);
  }

  // Checked before claiming, so an unconfigured function leaves the outbox untouched.
  const serviceAccount = parseServiceAccount(env("FCM_SERVICE_ACCOUNT"));
  const endpoint = env("FCM_ENDPOINT");
  if (serviceAccount === null || endpoint === "") {
    console.error(JSON.stringify({ event: "notify_run", error: "fcm_not_configured" }));
    await checkIn("error", 0, ["fcm_not_configured"]);
    return json({ error: "fcm_not_configured" }, 503);
  }

  const started = Date.now();
  try {
    const stats = await runNotify({
      store: createStore(envInt("NOTIFY_MAX_ATTEMPTS", 5)),
      fcm: createFcmClient({
        endpoint,
        serviceAccount,
        fetch: (url, init) => fetch(url, init),
        now: () => Date.now(),
      }),
      now: () => new Date(),
      batchSize: envInt("NOTIFY_BATCH_SIZE", 200),
      concurrency: envInt("NOTIFY_CONCURRENCY", 10),
    });
    const ms = Date.now() - started;
    console.log(JSON.stringify({ event: "notify_run", ...stats, ms }));
    const verdict = assess(stats, await readHealth(), {
      failureRate: envNumber("NOTIFY_ALERT_FAILURE_RATE", 0.5),
      backlogSeconds: envNumber("NOTIFY_ALERT_BACKLOG_SECONDS", 600),
    });
    await checkIn(verdict.status, ms, verdict.reasons);
    return json(stats, 200);
  } catch (e) {
    console.error(JSON.stringify({
      event: "notify_run",
      error: "run_failed",
      message: (e as Error).message,
      ms: Date.now() - started,
    }));
    await checkIn("error", Date.now() - started, ["run_failed"]);
    return json({ error: "run_failed" }, 500);
  }
}

Deno.serve(handle);
