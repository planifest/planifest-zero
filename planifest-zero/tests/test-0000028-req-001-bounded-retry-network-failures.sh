#!/usr/bin/env bash
# Tests for feature 0000028, req-001: bounded retry on network-level
# telemetry emission failures (0000028-ADR-001).
#
# Retry lives once in the shared hooks/telemetry/emit-event.mjs postEvent()
# (extracted by req-002), so exercising it through emit-phase-start.mjs is
# representative of all three direct-emission callers (context-pressure.mjs,
# emit-phase-start.mjs, emit-phase-end.mjs), which import and call the same
# function with no fetch call of their own.
#
# Covers, against a controllable local HTTP backend spawned as a real child
# process (helpers/controllable-backend.mjs), not by inspection:
#   1. Backend never listens: hook exits 0, exactly one durable marker.
#   2. Backend starts listening partway through the retry window (simulated
#      daemon-restart gap): event delivered, hook exits 0, no marker.
#   3. Backend answers immediately with HTTP 500: hook exits 0, exactly one
#      durable marker, and only ONE attempt reaches the backend (not
#      retried), since an HTTP error status is never a listener-gap symptom.
#   4. Timing: the never-listens case takes at least 600ms (two 300ms retry
#      gaps) but stays well under a few seconds.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
TEL="$FRAMEWORK_SRC/hooks/telemetry"
BACKEND="$SCRIPT_DIR/helpers/controllable-backend.mjs"

# emit-phase-start.mjs's dedup flag lives under the OS tmpdir keyed only by
# session_id + phase (get-flag-path.mjs), not scoped to the test workspace.
# A fixed session id would collide with a leftover flag from a prior run of
# this same test and short-circuit the hook before postEvent is ever called.
# A per-invocation nonce keeps every run's session ids unique.
NONCE="$$-$RANDOM-$RANDOM"

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000028_req001_XXXXXX)
  printf 'id: req001-test-product\n' > "$dir/product.yml"
  echo "$dir"
}

free_port() {
  node -e 'const s=require("net").createServer();s.listen(0,()=>{console.log(s.address().port);s.close();});'
}

marker_count() {
  local ws="$1"
  ls "$ws/plan/.telemetry-failures"/*.json 2>/dev/null | wc -l | tr -d ' '
}

request_count() {
  local ws="$1"
  if [ -f "$ws/requests.log" ]; then
    wc -l < "$ws/requests.log" | tr -d ' '
  else
    echo 0
  fi
}

# run_hook <ws> <backend_url> <session_id>: spawns emit-phase-start.mjs as a
# real child process, the shape req-001's acceptance criteria specify. Prints
# "<exit_code> <elapsed_ms>" to stdout.
run_hook() {
  local ws="$1" url="$2" sid="$3"
  local start end code
  start=$(node -e 'console.log(Date.now())')
  printf '{"cwd":"%s","session_id":"%s"}' "$ws" "$sid" \
    | PLANIFEST_SESSION_ID="$sid" PLANIFEST_TELEMETRY_URL="$url" \
      node "$TEL/emit-phase-start.mjs" codegen >/dev/null 2>&1
  code=$?
  end=$(node -e 'console.log(Date.now())')
  echo "$code $((end - start))"
}

assert_ge() {
  local min="$1" actual="$2" message="$3"
  if [ "$actual" -ge "$min" ]; then
    assert_equals "0" "0" "$message"
  else
    assert_equals ">= $min" "$actual" "$message"
  fi
}

assert_le() {
  local max="$1" actual="$2" message="$3"
  if [ "$actual" -le "$max" ]; then
    assert_equals "0" "0" "$message"
  else
    assert_equals "<= $max" "$actual" "$message"
  fi
}

# =============================================================================
# 1 + 4. Backend never listens: exit 0, exactly one marker, timing bounds
# =============================================================================

echo ""
echo "=== req-001: backend never listens ==="

WS=$(make_workspace)
PORT=$(free_port)
REQUEST_LOG="$WS/requests.log" node "$BACKEND" "$PORT" never &
BACKEND_PID=$!
sleep 0.1

RESULT=$(run_hook "$WS" "http://127.0.0.1:$PORT" "req001-never-$NONCE")
kill "$BACKEND_PID" >/dev/null 2>&1
wait "$BACKEND_PID" 2>/dev/null

EXIT_CODE=$(echo "$RESULT" | awk '{print $1}')
ELAPSED=$(echo "$RESULT" | awk '{print $2}')

assert_equals "0" "$EXIT_CODE" "req-001: hook exits 0 when the backend never listens"
assert_equals "1" "$(marker_count "$WS")" \
  "req-001: exactly one durable marker written when the backend never listens"
assert_ge 600 "$ELAPSED" \
  "req-001: never-listens case takes at least 600ms (two 300ms retry gaps => 3 attempts)"
assert_le 2900 "$ELAPSED" \
  "req-001: never-listens case stays well under the 3s per-attempt abort budget"

rm -rf "$WS"

# =============================================================================
# 2. Backend starts listening mid-retry (daemon-restart window)
# =============================================================================

echo ""
echo "=== req-001: backend starts listening partway through the retry window ==="

WS=$(make_workspace)
PORT=$(free_port)
# Listener binds 100ms in: after attempt 1 (fired immediately, fails) but
# well before attempt 2 (fired after the first 300ms gap), so attempt 2
# reaches a live listener and succeeds.
REQUEST_LOG="$WS/requests.log" node "$BACKEND" "$PORT" delayed 100 &
BACKEND_PID=$!

RESULT=$(run_hook "$WS" "http://127.0.0.1:$PORT" "req001-delayed-$NONCE")
kill "$BACKEND_PID" >/dev/null 2>&1
wait "$BACKEND_PID" 2>/dev/null

EXIT_CODE=$(echo "$RESULT" | awk '{print $1}')
DELIVERED=$(request_count "$WS")

assert_equals "0" "$EXIT_CODE" "req-001: hook exits 0 when the listener appears mid-retry"
assert_ge 1 "$DELIVERED" "req-001: the event is delivered once the listener appears mid-retry"
assert_equals "0" "$(marker_count "$WS")" \
  "req-001: no marker is written once the listener appears mid-retry and delivery succeeds"

rm -rf "$WS"

# =============================================================================
# 3. HTTP 500 is never retried
# =============================================================================

echo ""
echo "=== req-001: an HTTP 500 response is never retried ==="

WS=$(make_workspace)
PORT=$(free_port)
REQUEST_LOG="$WS/requests.log" node "$BACKEND" "$PORT" status 500 &
BACKEND_PID=$!
sleep 0.1

RESULT=$(run_hook "$WS" "http://127.0.0.1:$PORT" "req001-http500-$NONCE")
kill "$BACKEND_PID" >/dev/null 2>&1
wait "$BACKEND_PID" 2>/dev/null

EXIT_CODE=$(echo "$RESULT" | awk '{print $1}')
ATTEMPTS=$(request_count "$WS")

assert_equals "0" "$EXIT_CODE" "req-001: hook exits 0 on an HTTP 500 response"
assert_equals "1" "$ATTEMPTS" \
  "req-001: an HTTP 500 response is never retried (exactly one attempt reaches the backend)"
assert_equals "1" "$(marker_count "$WS")" \
  "req-001: exactly one durable marker written on an HTTP 500 response"

MARKER_FILE=$(ls "$WS/plan/.telemetry-failures"/*.json 2>/dev/null | head -1)
if [ -n "$MARKER_FILE" ]; then
  assert_contains "http_500" "$(cat "$MARKER_FILE")" \
    "req-001: the marker records the http_500 error type, not a network-level type"
else
  assert_equals "marker file present" "none" \
    "req-001: the marker records the http_500 error type, not a network-level type"
fi

rm -rf "$WS"

print_summary
