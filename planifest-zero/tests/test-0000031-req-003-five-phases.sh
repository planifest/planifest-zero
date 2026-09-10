#!/usr/bin/env bash
# Feature 0000031 req-003: five phases, 12 skills, five phase names in pipeline-reference.
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

echo "=== (b) pipeline-reference names exactly the five phases ==="
REF="$FRAMEWORK/pipeline-reference.md"
REF_TEXT="$(cat "$REF")"
for p in discovery plan implement validate-and-accept ship; do
  assert_contains "\`$p\`" "$REF_TEXT" "pipeline-reference names phase $p"
done
for old in spec adr codegen security docs; do
  assert_equals "0" "$(grep -c "\`$old\`" "$REF" || true)" "old phase name $old gone from pipeline-reference"
done

echo "=== (e) CI posts all five phase names ==="
CI="$REPO/.github/workflows/planifest.yml"
for p in discovery plan implement validate-and-accept ship; do
  assert_contains "$p" "$(cat "$CI")" "CI references phase $p"
done

echo "=== (f) NFR: skills text at or below 1447 lines ==="
TOTAL=$(find "$FRAMEWORK/skills" -name "SKILL.md" -exec cat {} + | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$TOTAL" -le 1447 ] && echo yes || echo no)" "skill text $TOTAL <= 1447"

print_summary
