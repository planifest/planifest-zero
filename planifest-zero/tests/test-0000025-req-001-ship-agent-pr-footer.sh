#!/usr/bin/env bash
# Tests for feature 0000025, req-001: PR bodies carry no AI attribution by
# default. The rule now lives in the ship phase skill (planifest-ship),
# which owns the PR step behind the always-stop final gate.
#
# planifest-ship/SKILL.md is a prose skill file, not executable code, so
# these are content-assertion tests against the SKILL.md text.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SHIP_SKILL="$FRAMEWORK/skills/planifest-ship/SKILL.md"

SHIP_CONTENT=$(cat "$SHIP_SKILL")

# Isolate the PR step (from its heading to the next "### " heading).
PR_STEP=$(printf '%s\n' "$SHIP_CONTENT" | sed -n '/^### Step 8: PR/,/^### Step 9/p')

echo ""
echo "=== req-001: the PR step exists and offers both delivery paths ==="

assert_equals "yes" "$([ -n "$PR_STEP" ] && echo yes || echo no)" \
  "req-001: planifest-ship documents a PR step"
assert_contains "gh pr create" "$PR_STEP" \
  "req-001: agent-pushes path uses gh pr create"
assert_contains "give me the PR title and description" "$PR_STEP" \
  "req-001: human-pushes path hands over title and description"

echo ""
echo "=== req-001: no AI attribution in PR bodies ==="

assert_contains "PR bodies carry no AI attribution" "$PR_STEP" \
  "req-001: the no-attribution rule is stated in the PR step"

if [[ "$SHIP_CONTENT" == *"Generated with"* ]]; then
  echo "  FAIL: req-001: an attribution footer template survives in planifest-ship"
  ((FAIL++)) || true
else
  echo "  PASS: req-001: no attribution footer template anywhere in planifest-ship"
  ((PASS++)) || true
fi

echo ""
echo "=== req-001: local-git-only override scan is still present ==="

assert_contains "planifest-overrides/instructions/" "$PR_STEP" \
  "req-001: the PR step checks planifest-overrides/instructions/ for a local-git-only override"
assert_contains "local-git-only" "$PR_STEP" \
  "req-001: the local-git-only override skips the push question"

print_summary
