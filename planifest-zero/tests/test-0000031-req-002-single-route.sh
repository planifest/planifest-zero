#!/usr/bin/env bash
# Feature 0000031 req-002: one route. Change Pipeline, Fast Path, Retrofit gone.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) exactly one workflow file ==="
COUNT=$(ls "$FRAMEWORK/workflows/"*.md 2>/dev/null | wc -l | tr -d ' ')
assert_equals "1" "$COUNT" "one file in workflows/"
assert_equals "yes" "$([ -f "$FRAMEWORK/workflows/feature-pipeline.md" ] && echo yes || echo no)" "feature-pipeline.md present"

echo "=== (b) change-agent skill gone ==="
assert_equals "no" "$([ -d "$FRAMEWORK/skills/planifest-change-agent" ] && echo yes || echo no)" "change-agent absent"

echo "=== (c) CI has no fast-path exemption ==="
assert_equals "0" "$(grep -c "fast-path" "$REPO/.github/workflows/planifest.yml" || true)" "no fast-path branch in repo CI"
assert_equals "0" "$(grep -c "fast-path" "$FRAMEWORK/hooks/planifest.yml" || true)" "no fast-path branch in shipped CI copy"

echo "=== (d) no live route references ==="
HITS=$(grep -rli "change-pipeline\|fast-path" "$FRAMEWORK/skills" "$FRAMEWORK/workflows" "$FRAMEWORK/standards" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "no change-pipeline/fast-path refs in skills, workflows, standards"

print_summary
