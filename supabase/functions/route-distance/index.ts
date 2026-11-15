// Edge Function `route-distance` (P9-T08). Contract: docs/route-distance-api.md.
// Everything testable lives in _shared/route.ts; this file only wires the runtime.
import { type Bucket, handleRoute } from "../_shared/route.ts";

const env = (name: string): string => Deno.env.get(name) ?? "";

async function takeToken(bucket: Bucket): Promise<boolean> {
  const key = env("SUPABASE_SERVICE_ROLE_KEY");
  const res = await fetch(`${env("SUPABASE_URL")}/rest/v1/rpc/consume_rate_limit`, {
    method: "POST",
    headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      p_key: bucket.key,
      p_capacity: bucket.capacity,
      p_refill_per_sec: bucket.refillPerSec,
    }),
    signal: AbortSignal.timeout(5000),
  });
  if (!res.ok) throw new Error(`rate limit failed: ${res.status}`);
  return (await res.json()) === true;
}

Deno.serve((req) =>
  handleRoute(req, {
    env,
    fetch: (input, init) => fetch(input, init),
    takeToken,
    now: () => Date.now(),
    log: (message) => console.error(message),
  })
);
