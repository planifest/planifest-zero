#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-004
# (refresh-setup-reads-record-first).
#
# planifest-refresh-setup is a Markdown skill followed by an agent, not
# executable code, so coverage is structural: grep-based assertions over
# SKILL.md, matching the established pattern in
# test-0000020-req-001-010-refresh-setup-skill.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL="$FRAMEWORK/skills/planifest-refresh-setup/SKILL.md"

assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" \
  "req-004: planifest-refresh-setup/SKILL.md exists"

STEP2=$(sed -n '/^## Step 2/,/^## Step 3/p' "$SKILL")
STEP3=$(sed -n '/^## Step 3/,/^## Step 4/p' "$SKILL")
STEP4=$(sed -n '/^## Step 4/,/^## Step 5/p' "$SKILL")

echo ""
echo "=== req-004: Step 3 reads the record first, at high confidence ==="

assert_contains 'plan/state/{tool}.md' "$STEP3" \
  "req-004: Step 3 names plan/state/{tool}.md as the first source checked"
assert_contains "high" "$STEP3" \
  "req-004: a valid record is reported at high confidence"
assert_contains "is not consulted" "$STEP3" \
  "req-004: the marker is not consulted when the record is valid"

echo ""
echo "=== req-004: record validation rules ==="

assert_contains '```json' "$STEP3" \
  "req-004: validation requires a fenced json block"
assert_contains "tool" "$STEP3" \
  "req-004: validation requires the tool field"
assert_contains "flags" "$STEP3" \
  "req-004: validation requires the flags field"
assert_contains "backendUrl" "$STEP3" \
  "req-004: validation requires the backendUrl field"
assert_contains "writtenAt" "$STEP3" \
  "req-004: validation requires the writtenAt field"
assert_contains "matches the target" "$STEP3" \
  "req-004: validation requires the tool field to match the target tool"

echo ""
echo "=== req-004: fallback order and no-stop behaviour ==="

assert_contains "marker" "$STEP3" \
  "req-004: fallback names the marker file"
assert_contains "hook" "$STEP3" \
  "req-004: fallback names hook inference"
assert_contains "does not stop the run" "$STEP3" \
  "req-004: a missing or malformed record does not stop the skill run"

echo ""
echo "=== req-004: Step 4 names the source per flag ==="

assert_contains "the record" "$STEP4" \
  "req-004: Step 4 names the record as a possible source"
assert_contains "marker" "$STEP4" \
  "req-004: Step 4 names the marker file as a possible source"
assert_contains "inferred" "$STEP4" \
  "req-004: Step 4 names hook inference as a possible source"

echo ""
echo "=== req-004: Step 2's interrupted-run detection is unchanged ==="

assert_contains 'attemptStatus: "pending"' "$STEP2" \
  "req-004: Step 2 still reads attemptStatus from the marker"

print_summary
