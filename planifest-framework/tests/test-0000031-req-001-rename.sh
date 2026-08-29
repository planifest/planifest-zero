#!/usr/bin/env bash
# Feature 0000031 req-001: planifest-framework/ renamed to planifest-zero/,
# every live reference updated. Historical records exempt.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) folder is named planifest-zero ==="
assert_equals "planifest-zero" "$(basename "$FRAMEWORK")" "framework folder basename"
assert_equals "no" "$([ -d "$REPO/planifest-framework" ] && echo yes || echo no)" "old folder absent"

echo "=== (b) zero live references to the old name ==="
HITS=$(grep -rl "planifest-framework" "$REPO" \
  --exclude-dir=.git --exclude-dir=_archive --exclude-dir=changelog \
  --exclude-dir=.claude --exclude-dir=_temp --exclude-dir=node_modules 2>/dev/null \
  | grep -v "plan/_archive\|plan/changelog" | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "live files referencing planifest-framework"

echo "=== (c) product.yml id is planifest-zero ==="
assert_equals "planifest-zero" "$(grep -E '^id:' "$REPO/product.yml" | sed 's/id: *"\{0,1\}\([^"]*\)"\{0,1\}/\1/' | tr -d ' ')" "product id"

echo "=== (d) refresh script renamed and portable ==="
assert_equals "no" "$([ -f "$REPO/refresh-planifest-framework-dir.ps1" ] && echo yes || echo no)" "old refresh script absent"
if [ -f "$REPO/refresh-planifest-zero-dir.ps1" ]; then
  assert_equals "0" "$(grep -c 'C:\\\\d\\\\planifest' "$REPO/refresh-planifest-zero-dir.ps1" || true)" "no hardcoded machine path"
  assert_contains "$(cat "$REPO/refresh-planifest-zero-dir.ps1")" "PSScriptRoot" "derives path from script location"
else
  assert_equals "renamed-or-deleted" "missing" "refresh script neither renamed nor deleted"
fi

echo "=== (e) .gitattributes has no dead skill-sync line ==="
assert_equals "0" "$(grep -c "skill-sync" "$FRAMEWORK/.gitattributes" || true)" "skill-sync attribute gone"

print_summary
