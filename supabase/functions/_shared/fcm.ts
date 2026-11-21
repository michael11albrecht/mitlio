// FCM HTTP v1 client for the `notify` Edge Function (P6b-T05, ADR-13). Behind the `FcmClient`
// interface so tests use a fake or a stub server. The service account is an env secret
// (FCM_SERVICE_ACCOUNT, docs/BLOCKERS.md item 6); the endpoint comes from FCM_ENDPOINT so tests can
// point it at a stub. Uses only Web Crypto and fetch.

export type SendResult =
  | { ok: true }
  | { ok: false; kind: "invalid_token" | "retryable" | "permanent"; code: string };

export interface FcmClient {
  /** Sends one HTTP v1 `message` object. Never throws: failures are returned. */
  send(message: Record<string, unknown>): Promise<SendResult>;
}

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri: string;
}

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const JWT_LIFETIME_SEC = 3600;
const REFRESH_MARGIN_MS = 60_000;
const FALLBACK_TOKEN_LIFETIME_SEC = 300;
const REQUEST_TIMEOUT_MS = 8000;

export function parseServiceAccount(raw: string): ServiceAccount | null {
  let v: unknown;
  try {
    v = JSON.parse(raw);
  } catch (_) {
    // Not JSON: the caller reports the secret as misconfigured.
    return null;
  }
  if (typeof v !== "object" || v === null) return null;
  const o = v as Record<string, unknown>;
  if (
    typeof o.client_email !== "string" || typeof o.private_key !== "string" ||
    typeof o.token_uri !== "string"
  ) return null;
  return { client_email: o.client_email, private_key: o.private_key, token_uri: o.token_uri };
}

function base64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_")
    .replace(/=+$/, "");
}

const text = (s: string) => base64Url(new TextEncoder().encode(s));

/** RS256 JWT for the Google OAuth 2.0 service-account flow. `nowSec` is injected for tests. */
export async function signJwt(sa: ServiceAccount, nowSec: number): Promise<string> {
  const pem = sa.private_key.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const head = text(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = text(JSON.stringify({
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri,
    iat: nowSec,
    exp: nowSec + JWT_LIFETIME_SEC,
  }));
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${head}.${claims}`),
  );
  return `${head}.${claims}.${base64Url(new Uint8Array(sig))}`;
}

/**
 * Maps an FCM error response. UNREGISTERED and INVALID_ARGUMENT mean the token is dead (plan P6b
 * step 6). Auth problems, rate limits and 5xx are worth a retry; anything else is final.
 */
export function classifyFcmError(
  status: number,
  body: unknown,
): { kind: "invalid_token" | "retryable" | "permanent"; code: string } {
  let code = `HTTP_${status}`;
  const err = (body as { error?: unknown } | null)?.error;
  if (typeof err === "object" && err !== null) {
    const e = err as { status?: unknown; details?: unknown };
    if (typeof e.status === "string") code = e.status;
    if (Array.isArray(e.details)) {
      for (const d of e.details) {
        const c = (d as { errorCode?: unknown } | null)?.errorCode;
        if (typeof c === "string") code = c;
      }
    }
  }
  if (code === "UNREGISTERED" || code === "INVALID_ARGUMENT") {
    return { kind: "invalid_token", code };
  }
  if (status === 401 || status === 403 || status === 429 || status >= 500) {
    return { kind: "retryable", code };
  }
  return { kind: "permanent", code };
}

export interface FcmClientOptions {
  /** Full `.../v1/projects/<id>/messages:send` URL. */
  endpoint: string;
  serviceAccount: ServiceAccount;
  fetch: (url: string, init: RequestInit) => Promise<Response>;
  /** Epoch milliseconds. */
  now: () => number;
}

export function createFcmClient(opts: FcmClientOptions): FcmClient {
  let cached: { token: string; expiresAtMs: number } | null = null;

  // Concurrent sends share one exchange instead of each fetching a token.
  let inflight: Promise<string | null> | null = null;

  function accessToken(): Promise<string | null> {
    const nowMs = opts.now();
    if (cached && nowMs < cached.expiresAtMs - REFRESH_MARGIN_MS) {
      return Promise.resolve(cached.token);
    }
    inflight ??= fetchToken(nowMs).finally(() => {
      inflight = null;
    });
    return inflight;
  }

  async function fetchToken(nowMs: number): Promise<string | null> {
    try {
      const assertion = await signJwt(opts.serviceAccount, Math.floor(nowMs / 1000));
      const res = await opts.fetch(opts.serviceAccount.token_uri, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion,
        }).toString(),
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (!res.ok) {
        await res.body?.cancel();
        return null;
      }
      const body = await res.json();
      if (typeof body?.access_token !== "string") return null;
      const life = typeof body.expires_in === "number"
        ? body.expires_in
        : FALLBACK_TOKEN_LIFETIME_SEC;
      cached = { token: body.access_token, expiresAtMs: nowMs + life * 1000 };
      return cached.token;
    } catch (_) {
      // Reported to the caller as the retryable code auth_unavailable.
      return null;
    }
  }

  return {
    async send(message) {
      const token = await accessToken();
      if (token === null) return { ok: false, kind: "retryable", code: "auth_unavailable" };
      let res: Response;
      try {
        res = await opts.fetch(opts.endpoint, {
          method: "POST",
          headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
          body: JSON.stringify({ message }),
          signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
        });
      } catch (_) {
        // Reported to the caller as the retryable code network_error.
        return { ok: false, kind: "retryable", code: "network_error" };
      }
      if (res.ok) {
        await res.body?.cancel();
        return { ok: true };
      }
      let body: unknown = null;
      try {
        body = await res.json();
      } catch (_) {
        // Non-JSON error page (proxy): the status code alone classifies it.
      }
      return { ok: false, ...classifyFcmError(res.status, body) };
    },
  };
}
