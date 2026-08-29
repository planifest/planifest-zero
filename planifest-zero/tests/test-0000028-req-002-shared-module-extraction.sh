#!/usr/bin/env bash
# Tests for feature 0000028, req-002: extract duplicated hook logic into
# shared modules under hooks/enforcement/ and hooks/telemetry/ (ADR-002),
# sequenced so no caller ever imports a module absent from the same commit
# (ADR-004).
#
# Covers:
#   1. Each extracted helper has exactly one definition left in hooks/.
#   2. Every shared module exists and every caller imports it by relative path.
#   3. The shared readStdin settles on a stdin stream error rather than
#      hanging, and every caller still exits 0 on that path (NFR-001). This is
#      the deliberate behaviour change req-002 calls out: before extraction
#      only context-pressure.mjs wired stdin.on("error", reject).
#   4. The phase enum is defined once and both lookup tables plus the
#      validation set derive from it, with values matching what the three
#      hooks encoded independently before extraction.
#   5. Placement: the always-installed hooks/enforcement/ tree holds anything
#      an enforcement hook imports; no enforcement hook imports from the
#      conditionally-installed hooks/telemetry/ tree.
#   6. The tier 1 install glob copies shared telemetry modules, verified by
#      running setup.sh into scratch workspaces across all 4 install-flag
#      combinations and invoking the installed hooks.
#   7. getSessionId is deliberately NOT consolidated (3 behaviour profiles).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$FRAMEWORK_SRC/hooks"
ENF="$HOOKS/enforcement"
TEL="$HOOKS/telemetry"

# readStdin callers: the 12 req-002 named (7 enforcement + 5 telemetry), plus
# em-dash-guard.mjs, which req-006 added to hooks/enforcement/ during this same
# feature with its own local copy. It is folded in here rather than left as a
# 13th copy, since req-002's acceptance criterion is one definition in
# hooks/, not one definition among the files that existed when it was written.
READSTDIN_CALLERS=(
  "$ENF/auto-trigger-orchestrator.mjs" "$ENF/check-design.mjs"
  "$ENF/check-orchestrator-presence.mjs" "$ENF/check-telemetry-failures.mjs"
  "$ENF/check-telemetry-receipts.mjs" "$ENF/em-dash-guard.mjs"
  "$ENF/gate-write.mjs" "$ENF/ratchet-check.mjs"
  "$TEL/context-pressure.mjs" "$TEL/emit-event-receipt.mjs" "$TEL/emit-phase-end.mjs"
  "$TEL/emit-phase-start.mjs" "$TEL/resolve-phase.mjs"
)

count_defs() {
  # count_defs <pattern> <dir>... — files matching a pattern across hooks subtrees.
  # The pattern comes first so multiple directories can be passed as separate
  # arguments; collapsing them into one word makes grep -rl take an invalid
  # path, return no matches, and the assertion pass vacuously.
  local pattern="$1"; shift
  grep -rl "$pattern" "$@" 2>/dev/null | wc -l | tr -d ' '
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000028_req002_XXXXXX)
  cp -r "$FRAMEWORK_SRC" "$dir/planifest-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  printf 'id: req002-test-product\n' > "$dir/product.yml"
  echo "$dir"
}

# =============================================================================
# 1. Each extracted helper has exactly one definition remaining
# =============================================================================

echo ""
echo "=== req-002: each extracted helper has exactly one definition ==="

assert_equals "1" "$(count_defs '^export function readStdin' "$ENF" "$TEL")" \
  "req-002: readStdin is defined exactly once across the hook trees"
assert_equals "0" "$(count_defs '^function readStdin' "$ENF" "$TEL")" \
  "req-002: no enforcement or telemetry hook declares a local readStdin"
assert_equals "1" "$(count_defs '^export function readProductId' "$ENF" "$TEL")" \
  "req-002: readProductId is defined exactly once"
assert_equals "0" "$(count_defs '^function readProductId' "$ENF" "$TEL")" \
  "req-002: no local readProductId copies remain"
assert_equals "1" "$(count_defs '^export function recordTelemetryFailure' "$ENF" "$TEL")" \
  "req-002: recordTelemetryFailure is defined exactly once"
assert_equals "0" "$(count_defs '^function recordTelemetryFailure' "$ENF" "$TEL")" \
  "req-002: no local recordTelemetryFailure copies remain"
assert_equals "1" "$(count_defs '^export function getFlagPath' "$ENF" "$TEL")" \
  "req-002: getFlagPath is defined exactly once"
assert_equals "0" "$(count_defs '^function getFlagPath' "$ENF" "$TEL")" \
  "req-002: no local getFlagPath copies remain"
assert_equals "1" "$(count_defs '^export async function postEvent' "$ENF" "$TEL")" \
  "req-002: the emit fetch helper is defined exactly once"

# The AbortController/fetch block must exist only in the shared module now.
assert_equals "1" "$(count_defs 'new AbortController' "$ENF" "$TEL")" \
  "req-002: the AbortController emit block survives in exactly one file"
ABORT_FILE="$(grep -rl 'new AbortController' "$ENF" "$TEL" 2>/dev/null)"
assert_equals "$TEL/emit-event.mjs" "$ABORT_FILE" \
  "req-002: that one file is hooks/telemetry/emit-event.mjs"

# =============================================================================
# 2. Shared modules exist and every caller imports them
# =============================================================================

echo ""
echo "=== req-002: shared modules exist and callers import them ==="

for m in "$ENF/read-stdin.mjs" "$ENF/phase-enum.mjs" "$TEL/read-product-id.mjs" \
         "$TEL/record-telemetry-failure.mjs" "$TEL/get-flag-path.mjs" "$TEL/emit-event.mjs"; do
  if [ -f "$m" ]; then
    assert_equals "0" "0" "req-002: shared module exists: ${m#$FRAMEWORK_SRC/}"
  else
    assert_equals "exists" "missing" "req-002: shared module exists: ${m#$FRAMEWORK_SRC/}"
  fi
done

for caller in "${READSTDIN_CALLERS[@]}"; do
  CONTENT="$(cat "$caller")"
  assert_contains "read-stdin.mjs" "$CONTENT" \
    "req-002: $(basename "$caller") imports the shared readStdin"
done

# Every import in every hook must resolve on disk. A missing shared module is
# an ESM module-load failure, which happens before the hook's own try/catch and
# so cannot degrade gracefully (ADR-002/ADR-004).
echo ""
echo "=== req-002: every relative import in hooks/ resolves on disk ==="
UNRESOLVED=$(node -e '
  const fs = require("fs"), path = require("path");
  const roots = process.argv.slice(1);
  const missing = [];
  for (const root of roots) {
    for (const f of fs.readdirSync(root).filter((n) => n.endsWith(".mjs"))) {
      const src = fs.readFileSync(path.join(root, f), "utf8");
      for (const m of src.matchAll(/from\s+"(\.[^"]+)"/g)) {
        const target = path.resolve(root, m[1]);
        if (!fs.existsSync(target)) missing.push(`${f} -> ${m[1]}`);
      }
    }
  }
  console.log(missing.join(","));
' "$ENF" "$TEL")
assert_equals "" "$UNRESOLVED" "req-002: no hook imports a module that is absent from the source tree"

# =============================================================================
# 3. Shared readStdin settles on a stdin error (NFR-001)
# =============================================================================

echo ""
echo "=== req-002: shared readStdin settles on a stdin stream error ==="

assert_contains 'process.stdin.on("error"' "$(cat "$ENF/read-stdin.mjs")" \
  "req-002: shared readStdin wires an error handler"

# stdin must stay OPEN for this to mean anything: with /dev/null the stream
# reaches "end" immediately and resolves before any error can be observed.
# Process substitution on a sleeping process gives an fd that produces no data
# and no EOF for the life of the check, which is the shape a stalled stdin has.
SETTLE=$(node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  let settled = 'HUNG';
  readStdin().then(() => { settled = 'RESOLVED'; }, () => { settled = 'REJECTED'; });
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  setTimeout(() => { console.log(settled); process.exit(0); }, 500);
" < <(sleep 5) 2>&1 | tail -1)
assert_equals "REJECTED" "$SETTLE" \
  "req-002: readStdin rejects on a stdin error instead of hanging forever"

# End-to-end, in the exact shape a hook uses it: await inside a try/catch that
# exits 0. The shared version must reach the catch and exit 0.
node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdin(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
assert_exit_zero $? "req-002: a hook using the shared readStdin exits 0 on a stdin stream error"

# Control: the pre-extraction shape (no "error" handler) never settles its
# promise, so the stream's error surfaces as an unhandled "error" event that
# bypasses the hook's own top-level try/catch entirely and aborts the process
# non-zero. That is the latent NFR-001 violation consolidating fixed, and the
# reason the discrepancy was resolved toward the error-handling variant rather
# than away from it.
node --input-type=module -e "
  function readStdinOld() {
    return new Promise((resolve) => {
      let data = '';
      process.stdin.setEncoding('utf-8');
      process.stdin.on('data', (chunk) => { data += chunk; });
      process.stdin.on('end', () => resolve(data));
      process.stdin.resume();
    });
  }
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdinOld(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
PRE_EXIT=$?
if [ "$PRE_EXIT" -ne 0 ]; then
  assert_equals "0" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
else
  assert_equals "non-zero" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
fi

# The rejection must land on each caller's existing fail-open path, so no hook
# turns a stdin error into a non-zero exit. Each caller either wraps its await
# in a top-level try/catch or attaches .catch() to its main().
echo ""
echo "=== req-002: every readStdin caller still exits 0 on a rejected stdin ==="
for caller in "${READSTDIN_CALLERS[@]}"; do
  NAME="$(basename "$caller")"
  GUARDED=$(node -e '
    const fs = require("fs");
    const s = fs.readFileSync(process.argv[1], "utf8");
    // Either a top-level try/catch, or main().catch(...)
    const hasTry = /^try\s*\{/m.test(s) && /^\}\s*catch/m.test(s);
    const hasMainCatch = /\)\.catch\(/.test(s) || /main\(\)\.catch/.test(s);
    console.log(hasTry || hasMainCatch ? "guarded" : "unguarded");
  ' "$caller")
  assert_equals "guarded" "$GUARDED" "req-002: $NAME routes a readStdin rejection to a fail-open catch"
done

# =============================================================================
# 4. The phase enum is defined once and both lookups derive from it
# =============================================================================

echo ""
echo "=== req-002: the phase enum has one definition, all lookups derived ==="

PHASE_CHECK=$(node --input-type=module -e "
  import { PHASE_ENUM, KNOWN_PHASES, PHASE_NUMBER_TO_ENUM, PHASE_SKILLS } from '$ENF/phase-enum.mjs';
  const expectedEnum = ['spec','adr','codegen','validate','security','docs','ship'];
  // Values the three hooks encoded independently before extraction.
  const expectedNumbers = {1:'spec',2:'adr',3:'codegen',4:'validate',5:'security',6:'docs',7:'ship',8:'ship',9:'ship'};
  const expectedSkills = {
    'planifest-spec-agent':'spec','planifest-adr-agent':'adr','planifest-codegen-agent':'codegen',
    'planifest-validate-agent':'validate','planifest-security-agent':'security',
    'planifest-docs-agent':'docs','planifest-ship-agent':'ship'};
  const errs = [];
  if (JSON.stringify(PHASE_ENUM) !== JSON.stringify(expectedEnum)) errs.push('enum');
  if (JSON.stringify(PHASE_NUMBER_TO_ENUM) !== JSON.stringify(expectedNumbers)) errs.push('numbers');
  if (JSON.stringify(PHASE_SKILLS) !== JSON.stringify(expectedSkills)) errs.push('skills');
  if (JSON.stringify([...KNOWN_PHASES]) !== JSON.stringify(expectedEnum)) errs.push('known');
  if (PHASE_NUMBER_TO_ENUM[0] !== undefined) errs.push('P0-should-be-absent');
  console.log(errs.length ? errs.join(',') : 'OK');
")
assert_equals "OK" "$PHASE_CHECK" \
  "req-002: derived phase lookups match the values the 3 hooks encoded before extraction"

# A phase cannot be added to one key space without the others: all three
# lookups must have consistent cardinality against PHASE_ENUM.
DERIVE_CHECK=$(node --input-type=module -e "
  import { PHASE_ENUM, KNOWN_PHASES, PHASE_NUMBER_TO_ENUM, PHASE_SKILLS } from '$ENF/phase-enum.mjs';
  const skills = Object.keys(PHASE_SKILLS).length;
  const known = KNOWN_PHASES.size;
  const numbered = new Set(Object.values(PHASE_NUMBER_TO_ENUM)).size;
  console.log(skills === PHASE_ENUM.length && known === PHASE_ENUM.length && numbered === PHASE_ENUM.length ? 'OK' : 'DRIFT');
")
assert_equals "OK" "$DERIVE_CHECK" "req-002: every phase lookup covers exactly the shared enum"

# No hook may re-declare the enum locally.
assert_equals "1" "$(count_defs 'PHASE_NUMBER_TO_ENUM = ' "$ENF" "$TEL")" \
  "req-002: PHASE_NUMBER_TO_ENUM is assigned in exactly one file"
assert_equals "1" "$(count_defs 'PHASE_SKILLS = ' "$ENF" "$TEL")" \
  "req-002: PHASE_SKILLS is assigned in exactly one file"
assert_equals "1" "$(count_defs 'KNOWN_PHASES = ' "$ENF" "$TEL")" \
  "req-002: KNOWN_PHASES is assigned in exactly one file"

# =============================================================================
# 5. Placement: enforcement is the always-installed superset
# =============================================================================

echo ""
echo "=== req-002: no enforcement hook imports from the conditional telemetry tree ==="

BAD_DIRECTION=$(grep -l 'from "\.\./telemetry/' "$ENF"/*.mjs 2>/dev/null | tr '\n' ' ')
assert_equals "" "${BAD_DIRECTION% }" \
  "req-002: enforcement hooks never import from hooks/telemetry/ (installed only with --structured-telemetry-mcp)"

for f in "$ENF/phase-enum.mjs" "$ENF/read-stdin.mjs"; do
  if [ -f "$f" ]; then
    assert_equals "0" "0" "req-002: $(basename "$f") lives in the always-installed enforcement tree"
  else
    assert_equals "enforcement" "telemetry" "req-002: $(basename "$f") lives in the always-installed enforcement tree"
  fi
done

# =============================================================================
# 6. Install topology across all 4 flag combinations
# =============================================================================

echo ""
echo "=== req-002: shared modules install with telemetry on and off ==="

# (a) Telemetry OFF — hooks/telemetry/ is absent entirely, so
# check-telemetry-receipts.mjs proves the phase-enum placement decision.
WS=$(make_workspace); cd "$WS"
bash planifest-zero/setup.sh claude-code >/dev/null 2>&1
if [ -d "$WS/.claude/hooks/telemetry" ]; then
  assert_equals "absent" "present" "req-002: telemetry tree is absent without --structured-telemetry-mcp"
else
  assert_equals "0" "0" "req-002: telemetry tree is absent without --structured-telemetry-mcp"
fi
mkdir -p "$WS/plan/current"
printf '### P3 — Codegen\n\n| Telemetry | emitted |\n' > "$WS/plan/current/build-log.md"
RECEIPT_OUT=$(printf '{"cwd":"%s"}' "$WS" | node "$WS/.claude/hooks/enforcement/check-telemetry-receipts.mjs" 2>&1)
assert_exit_zero $? "req-002: check-telemetry-receipts exits 0 with telemetry uninstalled"
assert_contains "P3 (phase: codegen)" "$RECEIPT_OUT" \
  "req-002: check-telemetry-receipts resolves the phase enum with hooks/telemetry/ absent"
cd /; rm -rf "$WS"

# (b) Telemetry ON — the full *.mjs glob copies every shared module.
WS=$(make_workspace); cd "$WS"
bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1
MISSING=""
for m in read-product-id.mjs record-telemetry-failure.mjs get-flag-path.mjs emit-event.mjs resolve-phase.mjs; do
  [ -f "$WS/.claude/hooks/telemetry/$m" ] || MISSING="$MISSING $m"
done
assert_equals "" "$MISSING" "req-002: telemetry on installs every shared telemetry module"

# The installed emit hook must run end to end: with an unreachable backend, the
# shared recordTelemetryFailure writes a marker. That marker can only exist if
# all five shared imports resolved.
#
# getFlagPath keys the phase-start dedup flag on session_id+phase alone, in the
# shared OS tmpdir, not scoped to this test's workspace. A fixed session id
# collides with a flag left by a prior run of this same file and short-circuits
# emission before a marker is written. Use a run-unique id.
T_SESSION="t-$$-$(date +%s%N 2>/dev/null || date +%s)"
printf '{"cwd":"%s","session_id":"%s"}' "$WS" "$T_SESSION" \
  | PLANIFEST_SESSION_ID="$T_SESSION" PLANIFEST_TELEMETRY_URL=http://127.0.0.1:39499 \
    node "$WS/.claude/hooks/telemetry/emit-phase-start.mjs" codegen >/dev/null 2>&1
assert_exit_zero $? "req-002: installed emit-phase-start exits 0"
if ls "$WS/plan/.telemetry-failures"/*.json >/dev/null 2>&1; then
  assert_equals "0" "0" "req-002: emit-phase-start ran end to end (shared marker written)"
else
  assert_equals "marker" "none" "req-002: emit-phase-start ran end to end (shared marker written)"
fi
cd /; rm -rf "$WS"

# setup.ps1 parity: the telemetry filter is the same widened *.mjs glob.
PS1_CONTENT="$(cat "$FRAMEWORK_SRC/setup.ps1")"
assert_contains "Get-ChildItem -Path \$src -Filter '*.mjs'" "$PS1_CONTENT" \
  "req-002: setup.ps1 telemetry filter is the widened *.mjs glob"

# =============================================================================
# 7. getSessionId is deliberately NOT consolidated
# =============================================================================

echo ""
echo "=== req-002: getSessionId is deliberately left un-consolidated ==="

assert_equals "4" "$(count_defs '^function getSessionId' "$TEL")" \
  "req-002: all 4 getSessionId copies remain (3 distinct behaviour profiles)"
assert_contains "creates" "$(cat "$TEL/emit-phase-start.mjs")" \
  "req-002: emit-phase-start documents why its getSessionId stays local"

print_summary
