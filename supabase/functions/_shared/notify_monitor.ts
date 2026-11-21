// Observability of the `notify` Edge Function (P6b-T10, ADR-14): decides whether a run is healthy
// and reports it to a Sentry cron monitor over the plain HTTP check-in API (no SDK, no new
// dependency). Sentry alerts on an `error` check-in and on a missed check-in (cron or function
// stopped), so a forced failure raises an alert. Only counts and fixed reason codes leave the
// function: no names, titles, tokens or ids.

import type { RunStats } from "./notify_run.ts";

export interface SentryDsn {
  origin: string;
  projectId: string;
  publicKey: string;
}

export type CheckInStatus = "ok" | "error";

export interface Health {
  oldest_due_age_seconds: number;
  failed_last_hour: number;
}

export interface MonitorThresholds {
  /** Share (0..1) of unsuccessful messages in one run that counts as an error. */
  failureRate: number;
  /** Age of the oldest due pending outbox row that counts as an error. */
  backlogSeconds: number;
}

export interface Assessment {
  status: CheckInStatus;
  reasons: ("failure_rate" | "backlog" | "dead_letters")[];
}

/** `https://<key>@<host>[/<prefix>]/<projectId>`; null for anything else (alerting stays off). */
export function parseSentryDsn(raw: string): SentryDsn | null {
  let url: URL;
  try {
    url = new URL(raw);
  } catch (_) {
    // Not a URL: the caller treats the monitor as not configured.
    return null;
  }
  if ((url.protocol !== "https:" && url.protocol !== "http:") || url.username === "") return null;
  const parts = url.pathname.split("/").filter((p) => p !== "");
  const projectId = parts.pop();
  if (projectId === undefined) return null;
  const prefix = parts.length > 0 ? `/${parts.join("/")}` : "";
  return { origin: `${url.protocol}//${url.host}${prefix}`, projectId, publicKey: url.username };
}

export function checkInUrl(
  dsn: SentryDsn,
  slug: string,
  status: CheckInStatus,
  durationMs?: number,
): string {
  const query = `status=${status}` + (durationMs === undefined ? "" : `&duration=${durationMs}`);
  return `${dsn.origin}/api/${dsn.projectId}/cron/${encodeURIComponent(slug)}/${dsn.publicKey}/` +
    `?${query}`;
}

/**
 * Unsuccessful messages are those neither sent nor answered with a dead token (a dead token is
 * expected cleanup). Health is null when it could not be read: that is not an error by itself.
 */
export function assess(
  stats: RunStats,
  health: Health | null,
  limits: MonitorThresholds,
): Assessment {
  const reasons: Assessment["reasons"] = [];
  if (stats.messages > 0) {
    const unsuccessful = stats.messages - stats.sent - stats.invalid_tokens;
    if (unsuccessful / stats.messages >= limits.failureRate) reasons.push("failure_rate");
  }
  if (health !== null) {
    if (health.oldest_due_age_seconds > limits.backlogSeconds) reasons.push("backlog");
    if (health.failed_last_hour > 0) reasons.push("dead_letters");
  }
  return { status: reasons.length > 0 ? "error" : "ok", reasons };
}

export type CheckInResult = "disabled" | "sent" | `failed:${string}`;

export interface Monitor {
  enabled: boolean;
  /** Never throws: the result is returned so the caller can log a failed check-in. */
  checkIn(status: CheckInStatus, durationMs?: number): Promise<CheckInResult>;
}

export function createMonitor(
  opts: { dsn: string; slug: string; fetch: (url: string, init: RequestInit) => Promise<Response> },
): Monitor {
  const dsn = parseSentryDsn(opts.dsn);
  return {
    enabled: dsn !== null,
    async checkIn(status, durationMs) {
      if (dsn === null) return "disabled";
      try {
        const res = await opts.fetch(checkInUrl(dsn, opts.slug, status, durationMs), {
          method: "GET",
          signal: AbortSignal.timeout(5000),
        });
        await res.body?.cancel();
        return res.ok ? "sent" : `failed:${res.status}`;
      } catch (_) {
        // Reported to the caller, which logs it; a monitor outage must not fail the run.
        return "failed:network";
      }
    },
  };
}
