#!/usr/bin/env bash
# Feature 0000031 req-003: five phases, 12 skills, five-value enum.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) exactly 12 skill folders ==="
COUNT=$(ls -d "$FRAMEWORK/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "12" "$COUNT" "12 skill folders"
for s in planifest-orchestrator planifest-plan planifest-implement planifest-validate-and-accept planifest-ship planifest-test-writer planifest-implementer planifest-refactor planifest-loop-runner planifest-optimise-agent planifest-migrator planifest-refresh-setup; do
  assert_equals "yes" "$([ -f "$FRAMEWORK/skills/$s/SKILL.md" ] && echo yes || echo no)" "skill $s present"
done

echo "=== (b) phase enum is exactly five values ==="
ENUM=$(node -e "import('$FRAMEWORK/hooks/enforcement/phase-enum.mjs').then(m=>console.log(m.PHASE_ENUM.join(',')))")
assert_equals "discovery,plan,implement,validate-and-accept,ship" "$ENUM" "PHASE_ENUM values"

echo "=== (c) consumers derive from the enum ==="
for f in enforcement/check-telemetry-receipts.mjs telemetry/resolve-phase.mjs telemetry/emit-event-receipt.mjs; do
  assert_contains "$(cat "$FRAMEWORK/hooks/$f")" "phase-enum.mjs" "hooks/$f imports phase-enum"
done

echo "=== (d) telemetry-standards lists the five ==="
STD="$FRAMEWORK/standards/telemetry-standards.md"
for p in discovery plan implement validate-and-accept ship; do
  assert_contains "$(cat "$STD")" "$p" "telemetry-standards mentions $p"
done
for old in '"spec"' '"adr"' '"codegen"' '"security"' '"docs"'; do
  assert_equals "0" "$(grep -c "$old" "$STD" || true)" "old enum value $old gone from standards"
done

echo "=== (e) CI posts all five phase names ==="
CI="$REPO/.github/workflows/planifest.yml"
for p in discovery plan implement validate-and-accept ship; do
  assert_contains "$(cat "$CI")" "$p" "CI references phase $p"
done

echo "=== (f) NFR: skills text at or below 1447 lines ==="
TOTAL=$(find "$FRAMEWORK/skills" -name "SKILL.md" -exec cat {} + | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$TOTAL" -le 1447 ] && echo yes || echo no)" "skill text $TOTAL <= 1447"

print_summary
