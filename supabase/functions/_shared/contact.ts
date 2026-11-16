// Contact form (Impressum contact channel). Contract: docs/contact-api.md.
// Pure request logic; the Edge Function (contact/index.ts) only wires env, fetch and the rate limiter.
// Privacy: nothing is stored and nothing of the message, email, name or IP is logged.
import { allowedOrigin, clientIp, hashClient } from "./fuel.ts";

export const RESEND_URL = "https://api.resend.com/emails";
export const MESSAGE_MIN = 10;
export const MESSAGE_MAX = 5000;
export const NAME_MAX = 100;
export const EMAIL_MAX = 254;
export const SUBJECT_PREFIX = "mitlio Kontakt: ";
export const SUBJECT_EXCERPT = 60;
export const DEFAULT_PER_HOUR = 5;
export const DEFAULT_GLOBAL_PER_DAY = 50;
/** Fixed bucket key for the all-clients daily cap; holds no client data. */
export const GLOBAL_KEY = "contact:global";
const SEND_TIMEOUT_MS = 8000;

export type Locale = "de" | "en";

export interface ContactInput {
  name: string;
  email: string;
  message: string;
  locale: Locale;
}

export type ErrorCode =
  | "invalid_json"
  | "invalid_email"
  | "message_too_short"
  | "message_too_long"
  | "name_too_long"
  | "invalid_locale"
  | "method_not_allowed"
  | "rate_limited"
  | "busy"
  | "rate_limit_unavailable"
  | "not_configured"
  | "send_failed";

export const STATUS: Record<ErrorCode, number> = {
  invalid_json: 400,
  invalid_email: 400,
  message_too_short: 400,
  message_too_long: 400,
  name_too_long: 400,
  invalid_locale: 400,
  method_not_allowed: 405,
  rate_limited: 429,
  busy: 429,
  rate_limit_unavailable: 503,
  not_configured: 503,
  send_failed: 502,
};

export interface ContactConfig {
  apiKey: string;
  to: string;
  from: string;
}

export type Validation = { ok: true; value: ContactInput } | { ok: false; error: ErrorCode };

const EMAIL_RE = /^[^\s@<>(),;:"[\]\\]+@[^\s@<>(),;:"[\]\\]+\.[^\s@<>(),;:"[\]\\]{2,}$/;
// deno-lint-ignore no-control-regex
const CONTROL_RE = /[\u0000-\u001f\u007f]/g;

/** A non-empty `website` field is the honeypot: only bots fill it. */
export function isHoneypot(body: unknown): boolean {
  if (typeof body !== "object" || body === null) return false;
  const w = (body as Record<string, unknown>)["website"];
  return typeof w === "string" && w.trim() !== "";
}

export function validateContact(body: unknown): Validation {
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    return { ok: false, error: "invalid_json" };
  }
  const b = body as Record<string, unknown>;
  const str = (v: unknown): string => (typeof v === "string" ? v : "");
  const email = str(b["email"]).trim();
  if (email.length > EMAIL_MAX || !EMAIL_RE.test(email)) {
    return { ok: false, error: "invalid_email" };
  }
  const message = str(b["message"]).trim();
  if (message.length < MESSAGE_MIN) return { ok: false, error: "message_too_short" };
  if (message.length > MESSAGE_MAX) return { ok: false, error: "message_too_long" };
  const name = str(b["name"]).trim();
  if (name.length > NAME_MAX) return { ok: false, error: "name_too_long" };
  const locale = b["locale"];
  if (locale !== "de" && locale !== "en") return { ok: false, error: "invalid_locale" };
  return { ok: true, value: { name, email, message, locale } };
}

/** Config from the environment; null when a required secret is missing (-> 503 not_configured). */
export function readConfig(env: (name: string) => string): ContactConfig | null {
  const apiKey = env("RESEND_API_KEY").trim();
  const to = env("CONTACT_TO").trim();
  const from = env("CONTACT_FROM").trim();
  return apiKey && to && from ? { apiKey, to, from } : null;
}

/** One line, no control characters (no header injection), first 60 characters of the message. */
export function buildSubject(message: string): string {
  const oneLine = message.replace(CONTROL_RE, " ").replace(/\s+/g, " ").trim();
  return SUBJECT_PREFIX + Array.from(oneLine).slice(0, SUBJECT_EXCERPT).join("");
}

export function buildResendPayload(input: ContactInput, config: ContactConfig) {
  const name = input.name.replace(CONTROL_RE, " ").trim();
  return {
    from: config.from,
    to: [config.to],
    reply_to: input.email,
    subject: buildSubject(input.message),
    text: [
      `Name: ${name || "-"}`,
      `E-Mail: ${input.email}`,
      `Sprache: ${input.locale}`,
      "",
      input.message,
    ].join("\n"),
  };
}

/** Seconds until one token is back for a bucket of `perPeriod` tokens per `periodSeconds`. */
export function retryAfterSeconds(perPeriod: number, periodSeconds = 3600): number {
  return Math.ceil(periodSeconds / perPeriod);
}

export type Decision = { status: 200 } | { status: 429; retryAfter: number };

export function rateLimitDecision(
  allowed: boolean,
  perPeriod: number,
  periodSeconds = 3600,
): Decision {
  return allowed
    ? { status: 200 }
    : { status: 429, retryAfter: retryAfterSeconds(perPeriod, periodSeconds) };
}

/** Error type from a Resend error body (`name`, e.g. "validation_error"); anything odd is "unknown". */
export function providerErrorType(body: unknown): string {
  const name = typeof body === "object" && body !== null
    ? (body as Record<string, unknown>)["name"]
    : undefined;
  return typeof name === "string" && /^[a-z_]{1,50}$/.test(name) ? name : "unknown";
}

/** The operator log line for a failed send: status code and error type only, never user data. */
export function sendFailureLine(status: number, type: string): string {
  return `contact send failed: status=${status} type=${type}`;
}

/** Any provider answer that is not 2xx (including its own 429) is a failed send. */
export function mapProviderStatus(status: number): "ok" | "send_failed" {
  return status >= 200 && status < 300 ? "ok" : "send_failed";
}

export function corsHeaders(origin: string | null, allowlist: string): Record<string, string> {
  const allowed = allowedOrigin(origin, allowlist);
  if (!allowed) return {};
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Expose-Headers": "Retry-After",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

export type Fetch = (input: string, init: RequestInit) => Promise<Response>;

export interface Deps {
  env: (name: string) => string;
  fetch: Fetch;
  /** One line to the function logs (Supabase). Never pass user data. */
  log: (line: string) => void;
  /** Token bucket (public.consume_rate_limit); true when a token was taken. */
  takeToken: (keyHash: string, capacity: number, refillPerSec: number) => Promise<boolean>;
}

function json(body: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8", ...headers },
  });
}

const fail = (code: ErrorCode, headers: Record<string, string>) =>
  json({ error: code }, STATUS[code], headers);

export async function handleContact(req: Request, deps: Deps): Promise<Response> {
  const { env } = deps;
  const cors = corsHeaders(
    req.headers.get("origin"),
    env("CONTACT_ALLOWED_ORIGINS") || env("FUEL_ALLOWED_ORIGINS"),
  );
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return fail("method_not_allowed", cors);

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return fail("invalid_json", cors);
  }
  // Bots get the same answer as people and nothing is sent or counted.
  if (isHoneypot(body)) return json({ ok: true }, 200, cors);

  const config = readConfig(env);
  if (!config) return fail("not_configured", cors);

  const checked = validateContact(body);
  if (!checked.ok) return fail(checked.error, cors);

  const configured = Number(env("CONTACT_RATE_LIMIT_PER_HOUR"));
  const perHour = configured > 0 ? configured : DEFAULT_PER_HOUR;
  const globalConfigured = Number(env("CONTACT_GLOBAL_PER_DAY"));
  const perDay = globalConfigured > 0 ? globalConfigured : DEFAULT_GLOBAL_PER_DAY;
  let allowed: boolean;
  let globalAllowed = true;
  try {
    const salt = env("CONTACT_RATE_LIMIT_SALT") || env("FUEL_RATE_LIMIT_SALT") ||
      env("SUPABASE_SERVICE_ROLE_KEY");
    // A separate prefix keeps this bucket apart from the fuel-prices bucket of the same client.
    const key = await hashClient(`contact|${clientIp(req.headers)}`, salt);
    allowed = await deps.takeToken(key, perHour, perHour / 3600);
    // Daily cap over all clients, so rotating IPs cannot burn the provider quota or flood the inbox.
    // Only checked once the client's own limit passed: a refused client does not use up the global cap.
    if (allowed) globalAllowed = await deps.takeToken(GLOBAL_KEY, perDay, perDay / 86400);
  } catch {
    // Without a working limiter a mail endpoint must stay closed. No detail: errors may carry request data.
    deps.log("contact rate limiter failed");
    return fail("rate_limit_unavailable", cors);
  }
  const decision = rateLimitDecision(allowed, perHour);
  if (decision.status === 429) {
    // Also in the body: browsers only expose Retry-After cross-origin through the CORS header above.
    return json({ error: "rate_limited", retryAfter: decision.retryAfter }, STATUS.rate_limited, {
      ...cors,
      "Retry-After": String(decision.retryAfter),
    });
  }
  if (!globalAllowed) {
    const retryAfter = retryAfterSeconds(perDay, 86400);
    return json({ error: "busy", retryAfter }, STATUS.busy, {
      ...cors,
      "Retry-After": String(retryAfter),
    });
  }

  try {
    const res = await deps.fetch(RESEND_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${config.apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify(buildResendPayload(checked.value, config)),
      signal: AbortSignal.timeout(SEND_TIMEOUT_MS),
    });
    if (mapProviderStatus(res.status) !== "ok") {
      const body: unknown = await res.json().catch(() => null);
      deps.log(sendFailureLine(res.status, providerErrorType(body)));
      return fail("send_failed", cors);
    }
    await res.body?.cancel();
  } catch (e) {
    // Only the error class name (e.g. TimeoutError): the message could echo request data.
    deps.log(sendFailureLine(0, e instanceof Error ? e.name : "unknown"));
    return fail("send_failed", cors);
  }
  return json({ ok: true }, 200, cors);
}
