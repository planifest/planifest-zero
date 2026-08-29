#!/usr/bin/env bash
# Feature 0000031 req-005: telemetry stays, context-mode is fully gone.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) telemetry family intact ==="
for f in emit-event.mjs emit-phase-start.mjs emit-phase-end.mjs resolve-phase.mjs emit-event-receipt.mjs record-telemetry-failure.mjs read-product-id.mjs get-flag-path.mjs; do
  assert_equals "yes" "$([ -f "$FRAMEWORK/hooks/telemetry/$f" ] && echo yes || echo no)" "telemetry hook $f present"
done
assert_contains "structured-telemetry-mcp" "$(cat "$FRAMEWORK/setup.sh")" "setup.sh keeps the flag"

echo "=== (b) zero context-mode occurrences in live tree ==="
HITS=$(grep -rli "context-mode" "$REPO" \
  --exclude-dir=.git --exclude-dir=.claude --exclude-dir=_temp 2>/dev/null \
  | grep -v "plan/_archive\|plan/changelog" | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "live files mentioning context-mode"

print_summary
