#!/usr/bin/env bash
# Tests for feature 0000028, req-003: stderr fallback when the marker write
# inside recordTelemetryFailure() itself fails.
#
# Covers planifest-framework/hooks/telemetry/record-telemetry-failure.mjs
# (the req-002 shared module used by all 4 telemetry hooks: context-pressure,
# emit-phase-start, emit-phase-end, emit-event-receipt):
#   1. All 4 callers still import recordTelemetryFailure from the shared
#      module (the fix lives in one place and reaches all 4 automatically).
#   2. When the marker write fails, exactly one line reaches stderr, it
#      names the hook and the marker path, and the process still exits 0.
#   3. When the marker write succeeds (the normal path), stderr is empty.
#   4. The stderr line does not echo credential-shaped values from
#      user-configured context.
#   5. A broken stderr stream cannot make recordTelemetryFailure throw.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
TEL="$FRAMEWORK_SRC/hooks/telemetry"
MODULE="$TEL/record-telemetry-failure.mjs"

# =============================================================================
# 1. All 4 callers route through the shared module
# =============================================================================

echo ""
echo "=== req-003: all 4 telemetry hooks import the shared recordTelemetryFailure ==="

for caller in context-pressure.mjs emit-phase-start.mjs emit-phase-end.mjs emit-event-receipt.mjs; do
  CONTENT="$(cat "$TEL/$caller")"
  assert_contains 'from "./record-telemetry-failure.mjs"' "$CONTENT" \
    "req-003: $caller imports recordTelemetryFailure from the shared module"
  assert_contains "recordTelemetryFailure(" "$CONTENT" \
    "req-003: $caller calls recordTelemetryFailure(...)"
done

# =============================================================================
# 2. Marker write failure -> exactly one stderr line, exit 0
# =============================================================================

echo ""
echo "=== req-003: marker write failure produces exactly one stderr line, exit 0 ==="

SCRATCH_A=$(mktemp -d -t planifest_0000028_req003_a_XXXXXX)
mkdir -p "$SCRATCH_A/plan"
# plan/.telemetry-failures exists as a *file*, so mkdirSync(dir, {recursive:true})
# inside the module fails with EEXIST — a reliable, portable way to force the
# write path to fail without relying on chmod/root-bypass semantics.
touch "$SCRATCH_A/plan/.telemetry-failures"

node --input-type=module -e "
  import { recordTelemetryFailure } from '$MODULE';
  recordTelemetryFailure('context-pressure', new Error('backend unreachable'), { cwd: '$SCRATCH_A' });
  process.exit(0);
" >/tmp/req003_stdout_a.txt 2>/tmp/req003_stderr_a.txt
EXIT_A=$?

assert_exit_zero "$EXIT_A" "req-003: recordTelemetryFailure still exits 0 when the marker write fails"

STDERR_A="$(cat /tmp/req003_stderr_a.txt)"
LINES_A=$(wc -l < /tmp/req003_stderr_a.txt | tr -d ' ')
assert_equals "1" "$LINES_A" "req-003: marker write failure emits exactly one stderr line"
assert_contains "context-pressure" "$STDERR_A" "req-003: stderr line names the hook"
assert_contains "$SCRATCH_A/plan/.telemetry-failures" "$STDERR_A" "req-003: stderr line names the marker path"

rm -rf "$SCRATCH_A" /tmp/req003_stdout_a.txt /tmp/req003_stderr_a.txt

# =============================================================================
# 3. Normal successful-write path emits nothing extra to stderr
# =============================================================================

echo ""
echo "=== req-003: successful marker write emits no stderr output ==="

SCRATCH_B=$(mktemp -d -t planifest_0000028_req003_b_XXXXXX)

node --input-type=module -e "
  import { recordTelemetryFailure } from '$MODULE';
  recordTelemetryFailure('emit-phase-start', new Error('some emission error'), { cwd: '$SCRATCH_B', phase: 'codegen' });
  process.exit(0);
" >/tmp/req003_stdout_b.txt 2>/tmp/req003_stderr_b.txt
EXIT_B=$?

assert_exit_zero "$EXIT_B" "req-003: recordTelemetryFailure exits 0 on the normal successful-write path"
STDERR_B="$(cat /tmp/req003_stderr_b.txt)"
assert_equals "" "$STDERR_B" "req-003: successful marker write produces no stderr output"

if ls "$SCRATCH_B/plan/.telemetry-failures"/*.json >/dev/null 2>&1; then
  assert_equals "0" "0" "req-003: the marker file was actually written on the success path"
else
  assert_equals "written" "missing" "req-003: the marker file was actually written on the success path"
fi

rm -rf "$SCRATCH_B" /tmp/req003_stdout_b.txt /tmp/req003_stderr_b.txt

# =============================================================================
# 4. No credential-shaped values are constructed into the stderr line
# =============================================================================

echo ""
echo "=== req-003: stderr line does not construct credential values ==="

SCRATCH_C=$(mktemp -d -t planifest_0000028_req003_c_XXXXXX)
mkdir -p "$SCRATCH_C/plan"
touch "$SCRATCH_C/plan/.telemetry-failures"

node --input-type=module -e "
  import { recordTelemetryFailure } from '$MODULE';
  recordTelemetryFailure('emit-event-receipt', new Error('some emission error'), { cwd: '$SCRATCH_C' });
  process.exit(0);
" >/tmp/req003_stdout_c.txt 2>/tmp/req003_stderr_c.txt

STDERR_C="$(cat /tmp/req003_stderr_c.txt)"
for needle in "api_key" "apikey" "token" "secret" "password" "Bearer "; do
  if [[ "$STDERR_C" == *"$needle"* ]]; then
    assert_equals "absent" "present:$needle" "req-003: stderr line does not contain credential-shaped field '$needle'"
  else
    assert_equals "0" "0" "req-003: stderr line does not contain credential-shaped field '$needle'"
  fi
done

rm -rf "$SCRATCH_C" /tmp/req003_stdout_c.txt /tmp/req003_stderr_c.txt

# =============================================================================
# 5. A broken stderr stream cannot make recordTelemetryFailure throw
# =============================================================================

echo ""
echo "=== req-003: recordTelemetryFailure never throws, even if stderr.write itself fails ==="

SCRATCH_D=$(mktemp -d -t planifest_0000028_req003_d_XXXXXX)
mkdir -p "$SCRATCH_D/plan"
touch "$SCRATCH_D/plan/.telemetry-failures"

node --input-type=module -e "
  import { recordTelemetryFailure } from '$MODULE';
  // Simulate a broken stderr stream: stderr.write throws synchronously.
  process.stderr.write = () => { throw new Error('EPIPE: broken pipe'); };
  recordTelemetryFailure('emit-phase-end', new Error('backend unreachable'), { cwd: '$SCRATCH_D' });
  console.log('SURVIVED');
" >/tmp/req003_stdout_d.txt 2>/tmp/req003_stderr_d.txt
EXIT_D=$?

assert_exit_zero "$EXIT_D" "req-003: recordTelemetryFailure exits 0 even when stderr.write itself throws"
assert_contains "SURVIVED" "$(cat /tmp/req003_stdout_d.txt)" \
  "req-003: control returns to the caller after a broken stderr stream"

rm -rf "$SCRATCH_D" /tmp/req003_stdout_d.txt /tmp/req003_stderr_d.txt

print_summary
