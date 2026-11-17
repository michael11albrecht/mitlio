// Edge Function `contact`. Contract: docs/contact-api.md. Logic: _shared/contact.ts.
// Stores nothing. Logs only a status code and error type on failures (never message, email, name or IP).
import { handleContact } from "../_shared/contact.ts";

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
  handleContact(req, { env, log: console.error, fetch: (u, i) => fetch(u, i), takeToken })
);
