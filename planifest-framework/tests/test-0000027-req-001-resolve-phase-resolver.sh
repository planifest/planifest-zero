#!/usr/bin/env bash
# Unit tests for hooks/telemetry/resolve-phase.mjs — the phase-argument
# wiring mechanism req-001 introduces (see its own header comment for the
# full design rationale). These exercise the resolver directly, decoupled
# from the real emit-phase-start.mjs/emit-phase-end.mjs (network calls,
# product.yml reads) via a lightweight stub target script that just records
# what argv/stdin it received.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOLVER="$FRAMEWORK/hooks/telemetry/resolve-phase.mjs"

make_stub() {
  # make_stub <marker_path> -> prints a path to a stub .mjs script that
  # writes "<phase> <stdin-cwd>" to marker_path when invoked. The marker path
  # is read from the PLANIFEST_STUB_MARKER env var (not shell-interpolated
  # into the script) so the quoted heredoc below leaves `process.argv[2]`
  # untouched instead of bash expanding `$2` as a positional parameter.
  local marker="$1"
  local stub_dir
  stub_dir=$(mktemp -d -t planifest_stub_dir_XXXXXX)
  local stub="$stub_dir/stub.mjs"
  cat > "$stub" << 'STUBEOF'
import { writeFileSync } from "node:fs";
let data = "";
process.stdin.setEncoding("utf-8");
process.stdin.on("data", (c) => { data += c; });
process.stdin.on("end", () => {
  let cwd = "";
  try { cwd = JSON.parse(data).cwd ?? ""; } catch {}
  writeFileSync(process.env.PLANIFEST_STUB_MARKER, process.argv[2] + " " + cwd);
  process.exit(0);
});
process.stdin.resume();
STUBEOF
  echo "$stub"
}

# =============================================================================
# start mode: a phase-skill Skill call resolves the phase and invokes target
# =============================================================================

echo ""
echo "=== resolve-phase.mjs (start): known phase skill resolves phase, invokes target ==="

WS_A=$(mktemp -d -t planifest_resolve_a_XXXXXX)
MARKER_A="$WS_A/marker.txt"
STUB_A=$(make_stub "$MARKER_A")

INPUT_A="{\"cwd\":\"$WS_A\",\"tool_name\":\"Skill\",\"tool_input\":{\"skill\":\"planifest-codegen-agent\"}}"
export PLANIFEST_STUB_MARKER="$MARKER_A"
printf '%s' "$INPUT_A" | node "$RESOLVER" start "$STUB_A" >/dev/null 2>&1
EXIT_A=$?
assert_exit_zero "$EXIT_A" "resolve-phase start: exits 0 for a known phase skill"

assert_equals "yes" "$([ -f "$MARKER_A" ] && echo yes || echo no)" \
  "resolve-phase start: target script invoked for planifest-codegen-agent"
[ -f "$MARKER_A" ] && assert_contains "codegen" "$(cat "$MARKER_A")" \
  "resolve-phase start: target invoked with resolved phase 'codegen'"

assert_equals "codegen" "$(cat "$WS_A/.claude/.planifest-active-phase" 2>/dev/null || echo MISSING)" \
  "resolve-phase start: active-phase marker file records 'codegen'"

rm -rf "$WS_A" "$(dirname "$STUB_A")"

# =============================================================================
# start mode: a non-phase skill is not a transition — no-op
# =============================================================================

echo ""
echo "=== resolve-phase.mjs (start): non-phase skill is a no-op ==="

WS_B=$(mktemp -d -t planifest_resolve_b_XXXXXX)
MARKER_B="$WS_B/marker.txt"
STUB_B=$(make_stub "$MARKER_B")

INPUT_B="{\"cwd\":\"$WS_B\",\"tool_name\":\"Skill\",\"tool_input\":{\"skill\":\"planifest-implementer\"}}"
export PLANIFEST_STUB_MARKER="$MARKER_B"
printf '%s' "$INPUT_B" | node "$RESOLVER" start "$STUB_B" >/dev/null 2>&1
EXIT_B=$?
assert_exit_zero "$EXIT_B" "resolve-phase start: exits 0 for a non-phase skill"
assert_equals "no" "$([ -f "$MARKER_B" ] && echo yes || echo no)" \
  "resolve-phase start: target NOT invoked for a non-phase skill (e.g. planifest-implementer)"
assert_equals "no" "$([ -f "$WS_B/.claude/.planifest-active-phase" ] && echo yes || echo no)" \
  "resolve-phase start: no active-phase marker written for a non-phase skill"

rm -rf "$WS_B" "$(dirname "$STUB_B")"

# =============================================================================
# start mode: a non-Skill tool call is not a transition — no-op
# =============================================================================

echo ""
echo "=== resolve-phase.mjs (start): non-Skill tool call is a no-op ==="

WS_C=$(mktemp -d -t planifest_resolve_c_XXXXXX)
MARKER_C="$WS_C/marker.txt"
STUB_C=$(make_stub "$MARKER_C")

INPUT_C="{\"cwd\":\"$WS_C\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"ls\"}}"
export PLANIFEST_STUB_MARKER="$MARKER_C"
printf '%s' "$INPUT_C" | node "$RESOLVER" start "$STUB_C" >/dev/null 2>&1
EXIT_C=$?
assert_exit_zero "$EXIT_C" "resolve-phase start: exits 0 for a non-Skill tool call"
assert_equals "no" "$([ -f "$MARKER_C" ] && echo yes || echo no)" \
  "resolve-phase start: target NOT invoked for a non-Skill tool call"

rm -rf "$WS_C" "$(dirname "$STUB_C")"

# =============================================================================
# end mode: no active phase recorded -> no-op
# =============================================================================

echo ""
echo "=== resolve-phase.mjs (end): no active-phase marker -> no-op ==="

WS_D=$(mktemp -d -t planifest_resolve_d_XXXXXX)
MARKER_D="$WS_D/marker.txt"
STUB_D=$(make_stub "$MARKER_D")

INPUT_D="{\"cwd\":\"$WS_D\"}"
export PLANIFEST_STUB_MARKER="$MARKER_D"
printf '%s' "$INPUT_D" | node "$RESOLVER" end "$STUB_D" >/dev/null 2>&1
EXIT_D=$?
assert_exit_zero "$EXIT_D" "resolve-phase end: exits 0 with no active phase"
assert_equals "no" "$([ -f "$MARKER_D" ] && echo yes || echo no)" \
  "resolve-phase end: target NOT invoked with no active phase"

rm -rf "$WS_D" "$(dirname "$STUB_D")"

# =============================================================================
# end mode: active phase recorded -> invokes target once, then clears marker
# =============================================================================

echo ""
echo "=== resolve-phase.mjs (end): active phase -> invokes target once, clears marker ==="

WS_E=$(mktemp -d -t planifest_resolve_e_XXXXXX)
MARKER_E="$WS_E/marker.txt"
STUB_E=$(make_stub "$MARKER_E")
mkdir -p "$WS_E/.claude"
printf 'validate' > "$WS_E/.claude/.planifest-active-phase"

# Unique per-run session id — the dedup flag this exercises lives in the
# shared OS tmpdir (planifest-telemetry/phase-end-emitted-<session>-<phase>),
# so a fixed id would leak dedup state across repeated test runs.
SESSION_E="test-resolve-e-$$-$RANDOM"
INPUT_E="{\"cwd\":\"$WS_E\",\"session_id\":\"$SESSION_E\"}"
export PLANIFEST_STUB_MARKER="$MARKER_E"
printf '%s' "$INPUT_E" | node "$RESOLVER" end "$STUB_E" >/dev/null 2>&1
EXIT_E=$?
assert_exit_zero "$EXIT_E" "resolve-phase end: exits 0 with an active phase"
assert_equals "yes" "$([ -f "$MARKER_E" ] && echo yes || echo no)" \
  "resolve-phase end: target invoked when a phase is active"
[ -f "$MARKER_E" ] && assert_contains "validate" "$(cat "$MARKER_E")" \
  "resolve-phase end: target invoked with resolved phase 'validate'"
assert_equals "no" "$([ -f "$WS_E/.claude/.planifest-active-phase" ] && echo yes || echo no)" \
  "resolve-phase end: active-phase marker cleared after emitting"

# Dedup guard: if the active-phase marker gets re-written to the SAME phase
# for the SAME session (e.g. the orchestrator re-invokes the same phase
# skill), a second Stop call must not emit phase_end a second time — the
# tmpdir dedup flag from the first emission (keyed by session_id + phase,
# mirroring emit-phase-start.mjs's own dedup guard) must still be in place.
rm -f "$MARKER_E"
printf 'validate' > "$WS_E/.claude/.planifest-active-phase"
printf '%s' "$INPUT_E" | node "$RESOLVER" end "$STUB_E" >/dev/null 2>&1
assert_equals "no" "$([ -f "$MARKER_E" ] && echo yes || echo no)" \
  "resolve-phase end: repeat Stop call for the same (session, phase) does not re-invoke the target (dedup flag holds)"

rm -rf "$WS_E" "$(dirname "$STUB_E")"

print_summary
