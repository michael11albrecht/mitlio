import { assertEquals } from "jsr:@std/assert@1.0.8";
import {
  assess,
  checkInUrl,
  createMonitor,
  type Health,
  type MonitorThresholds,
  parseSentryDsn,
} from "./notify_monitor.ts";
import type { RunStats } from "./notify_run.ts";

const T: MonitorThresholds = { failureRate: 0.5, backlogSeconds: 600 };
const OK: RunStats = {
  claimed: 4,
  recipients: 2,
  messages: 4,
  sent: 3,
  invalid_tokens: 1,
  retried: 0,
  dropped: 0,
  failed: 0,
};
const HEALTHY: Health = { oldest_due_age_seconds: 5, failed_last_hour: 0 };

Deno.test("parseSentryDsn: EU DSN -> host, project, key", () => {
  assertEquals(parseSentryDsn("https://abc123@o42.ingest.de.sentry.io/4507"), {
    origin: "https://o42.ingest.de.sentry.io",
    projectId: "4507",
    publicKey: "abc123",
  });
});

Deno.test("parseSentryDsn: keeps a path prefix and a port, drops a secret part", () => {
  assertEquals(parseSentryDsn("http://k:secret@localhost:8787/sentry/9"), {
    origin: "http://localhost:8787/sentry",
    projectId: "9",
    publicKey: "k",
  });
});

Deno.test("parseSentryDsn: empty, malformed or incomplete DSNs are rejected", () => {
  for (const bad of ["", "nope", "ftp://k@h/1", "https://h/1", "https://k@h/", "https://k@h"]) {
    assertEquals(parseSentryDsn(bad), null, bad);
  }
});

Deno.test("checkInUrl: monitor slug, key and status in the Sentry HTTP check-in format", () => {
  const dsn = parseSentryDsn("https://abc@o1.ingest.de.sentry.io/7")!;
  assertEquals(
    checkInUrl(dsn, "notify", "error", 1234),
    "https://o1.ingest.de.sentry.io/api/7/cron/notify/abc/?status=error&duration=1234",
  );
  assertEquals(
    checkInUrl(dsn, "a b", "ok"),
    "https://o1.ingest.de.sentry.io/api/7/cron/a%20b/abc/?status=ok",
  );
});

Deno.test("assess: a healthy run is ok", () => {
  assertEquals(assess(OK, HEALTHY, T), { status: "ok", reasons: [] });
});

Deno.test("assess: a run without messages is ok (nothing to fail)", () => {
  const idle = { ...OK, claimed: 0, messages: 0, sent: 0, invalid_tokens: 0 };
  assertEquals(assess(idle, HEALTHY, T), { status: "ok", reasons: [] });
});

Deno.test("assess: failure rate at the threshold is an error, below it is ok", () => {
  // 4 messages, 2 sent, 0 dead tokens -> 50 % unsuccessful.
  const half = { ...OK, sent: 2, invalid_tokens: 0, retried: 1, failed: 1 };
  assertEquals(assess(half, HEALTHY, T), { status: "error", reasons: ["failure_rate"] });
  const one = { ...OK, sent: 3, invalid_tokens: 0, failed: 1 };
  assertEquals(assess(one, HEALTHY, T).status, "ok");
});

Deno.test("assess: dead tokens are expected cleanup, not failures", () => {
  assertEquals(assess({ ...OK, sent: 0, invalid_tokens: 4 }, HEALTHY, T).status, "ok");
});

Deno.test("assess: stale backlog and dropped rows are errors", () => {
  assertEquals(assess(OK, { oldest_due_age_seconds: 601, failed_last_hour: 0 }, T), {
    status: "error",
    reasons: ["backlog"],
  });
  assertEquals(assess(OK, { oldest_due_age_seconds: 600, failed_last_hour: 0 }, T).status, "ok");
  assertEquals(assess(OK, { oldest_due_age_seconds: 0, failed_last_hour: 2 }, T), {
    status: "error",
    reasons: ["dead_letters"],
  });
});

Deno.test("assess: unknown health is not an error by itself", () => {
  assertEquals(assess(OK, null, T), { status: "ok", reasons: [] });
});

Deno.test("assess: all reasons are reported together", () => {
  const bad = { ...OK, sent: 0, invalid_tokens: 0, failed: 4 };
  assertEquals(assess(bad, { oldest_due_age_seconds: 9999, failed_last_hour: 1 }, T).reasons, [
    "failure_rate",
    "backlog",
    "dead_letters",
  ]);
});

Deno.test("monitor: without DSN nothing is sent", async () => {
  let calls = 0;
  const m = createMonitor({
    dsn: "",
    slug: "notify",
    fetch: () => {
      calls++;
      return Promise.resolve(new Response());
    },
  });
  assertEquals(m.enabled, false);
  assertEquals(await m.checkIn("error", 1), "disabled");
  assertEquals(calls, 0);
});

Deno.test("monitor: sends the check-in and reports success", async () => {
  const urls: string[] = [];
  const m = createMonitor({
    dsn: "https://k@o1.ingest.de.sentry.io/3",
    slug: "notify",
    fetch: (url) => {
      urls.push(String(url));
      return Promise.resolve(new Response("{}", { status: 202 }));
    },
  });
  assertEquals(await m.checkIn("ok", 250), "sent");
  assertEquals(urls, [
    "https://o1.ingest.de.sentry.io/api/3/cron/notify/k/?status=ok&duration=250",
  ]);
});

Deno.test("monitor: HTTP errors and network errors are returned, never thrown", async () => {
  const dsn = "https://k@o1.ingest.de.sentry.io/3";
  const http = createMonitor({
    dsn,
    slug: "notify",
    fetch: () => Promise.resolve(new Response("", { status: 429 })),
  });
  assertEquals(await http.checkIn("ok"), "failed:429");
  const net = createMonitor({
    dsn,
    slug: "notify",
    fetch: () => Promise.reject(new Error("down")),
  });
  assertEquals(await net.checkIn("ok"), "failed:network");
});
