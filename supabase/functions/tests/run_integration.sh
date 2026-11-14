#!/usr/bin/env bash
# Integration test for the fuel-prices Edge Function (P6c). Needs a running local stack
# (`supabase start`), `supabase` and `deno` on PATH. Run from anywhere; CI: .github/workflows/db.yml.
set -euo pipefail
cd "$(dirname "$0")/../../.."

eval "$(supabase status -o env)"
export API_URL ANON_KEY SERVICE_ROLE_KEY
export FUNCTION_URL="$API_URL/functions/v1/fuel-prices"
export STUB_URL="http://127.0.0.1:8787"
tmp="$(mktemp -d)"
serve_pid=""
stub_pid=""

cleanup() {
  [ -n "$serve_pid" ] && kill "$serve_pid" 2>/dev/null || true
  [ -n "$stub_pid" ] && kill "$stub_pid" 2>/dev/null || true
  echo "--- serve log ---"; cat "$tmp/serve.log" 2>/dev/null || true
}
trap cleanup EXIT

deno run --allow-net=0.0.0.0:8787 --allow-read=supabase/functions/_shared/testdata \
  supabase/functions/tests/stub_provider.ts > "$tmp/stub.log" 2>&1 &
stub_pid=$!

base_env() {
  cat <<EOF
TANKERKOENIG_BASE_URL=http://host.docker.internal:8787/json
OIL_BULLETIN_URL=http://host.docker.internal:8787/oil.xlsx
FUEL_ALLOWED_ORIGINS=https://mitlio.app,https://www.mitlio.app
FUEL_RATE_LIMIT_CAPACITY=6
FUEL_RATE_LIMIT_PER_MIN=1
FUEL_RATE_LIMIT_SALT=integration-test-salt
FUEL_WARM_TOKEN=warm-secret
EOF
}

run_phase() {
  local phase="$1"
  base_env > "$tmp/$phase.env"
  [ "$phase" = key ] && echo "TANKERKOENIG_API_KEY=test-key" >> "$tmp/$phase.env"
  echo "=== phase: $phase ==="
  supabase functions serve --env-file "$tmp/$phase.env" >> "$tmp/serve.log" 2>&1 &
  serve_pid=$!
  local ready=""
  for _ in $(seq 1 90); do
    # The gateway answers OPTIONS before the function is loaded, so probe with an invalid GET:
    # only the function itself answers 400 invalid_params (own client address, own bucket).
    code="$(curl -s -o /dev/null -w '%{http_code}' "$FUNCTION_URL?type=probe" \
      -H "apikey: $ANON_KEY" -H "Authorization: Bearer $ANON_KEY" -H 'cf-connecting-ip: 192.0.2.250' || true)"
    if [ "$code" = 400 ] || [ "$code" = 429 ]; then ready=1; break; fi
    sleep 2
  done
  [ -n "$ready" ] || { echo "function did not become ready"; exit 1; }
  PHASE="$phase" deno test --allow-net --allow-env --allow-read=supabase/functions/_shared/testdata \
    supabase/functions/tests/integration_test.ts
  kill "$serve_pid" 2>/dev/null || true
  wait "$serve_pid" 2>/dev/null || true
  serve_pid=""
}

run_phase key
run_phase nokey
