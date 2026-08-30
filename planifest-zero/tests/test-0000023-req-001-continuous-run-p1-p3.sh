#!/usr/bin/env bash
# Tests for feature 0000023-framework-pipeline-fixes, req-001:
# continuous run must be honoured at ordinary phase gates.
#
# Covers: the orchestrator's Phase Invocation table. In the five-phase
# pipeline the plan (P2) and implement (P3) gates carry a continuous-run
# exception, while the acceptance gate (P4) and the final ship gate (P5)
# always stop regardless of run mode.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SKILL="$SCRIPT_DIR/../skills/planifest-orchestrator/SKILL.md"

if [ ! -f "$SKILL" ]; then
  echo "  FAIL: $SKILL not found"
  ((FAIL++)) || true
  print_summary
fi

CONTENT=$(cat "$SKILL")

echo ""
echo "=== req-001: P2/P3 gates honour continuous run ==="

TABLE_SECTION=$(printf '%s\n' "$CONTENT" | sed -n '/## Phase Invocation/,/^## Mid-Pipeline/p')

P2_ROW=$(printf '%s\n' "$TABLE_SECTION" | grep '| P2 Plan |')
assert_contains "STOP for confirmation. Exception: continuous run." "$P2_ROW" \
  "req-001: P2 Plan row has the continuous-run exception"

P3_ROW=$(printf '%s\n' "$TABLE_SECTION" | grep '| P3 Implement |')
assert_contains "STOP for confirmation. Exception: continuous run." "$P3_ROW" \
  "req-001: P3 Implement row has the continuous-run exception"

echo ""
echo "=== req-001: acceptance and ship gates always stop ==="

P4_ROW=$(printf '%s\n' "$TABLE_SECTION" | grep '| P4 Validate and Accept |')
assert_contains "Acceptance ALWAYS stops. A continuous run does not bypass it." "$P4_ROW" \
  "req-001: P4 acceptance gate always stops, continuous run does not bypass it"

P5_ROW=$(printf '%s\n' "$TABLE_SECTION" | grep '| P5 Ship |')
assert_contains "Final gate. Always stops." "$P5_ROW" \
  "req-001: P5 ship gate always stops"

echo ""
echo "=== req-001: no stray 'No exception' left in the Phase Invocation table ==="

if [[ "$TABLE_SECTION" == *"No exception"* ]]; then
  echo "  FAIL: req-001: 'No exception' still present in the Phase Invocation table"
  ((FAIL++)) || true
else
  echo "  PASS: req-001: 'No exception' fully removed from the Phase Invocation table"
  ((PASS++)) || true
fi

echo ""
echo "=== req-001: run mode is captured and restored ==="

assert_contains "Continuous run: proceed without phase confirmations" "$CONTENT" \
  "req-001: the run-mode question offers a continuous run"
assert_contains 'plan/.run-mode' "$CONTENT" \
  "req-001: the answer is persisted to plan/.run-mode"

print_summary
