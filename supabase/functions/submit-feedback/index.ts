// Edge Function `submit-feedback` (ADR-29, P7-T10). Contract: docs/feedback-api.md. Logic: _shared/feedback.ts.
// The GitHub token lives only in this function's secrets. Logs only status codes and error types, never user data.
import { handleFeedback } from "../_shared/feedback.ts";

const env = (name: string): string => Deno.env.get(name) ?? "";

async function takeToken(
  keyHash: string,
  capacity: number,
  refillPerSec: number,
): Promise<boolean> {
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  const res = await fetch(`${env("SUPABASE_URL")}/rest/v1/rpc/consume_rate_limit`, {
    method: "POST",
    headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ p_key: keyHash, p_capacity: capacity, p_refill_per_sec: refillPerSec }),
    signal: AbortSignal.timeout(5000),
  });
  if (!res.ok) throw new Error(`rate limit failed: ${res.status}`);
  return (await res.json()) === true;
}

Deno.serve((req) =>
  handleFeedback(req, {
    env,
    log: console.error,
    fetch: (u, i) => fetch(u, i),
    takeToken,
    newId: () => crypto.randomUUID(),
    now: () => Date.now(),
  })
);
