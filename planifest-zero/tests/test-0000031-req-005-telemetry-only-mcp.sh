#!/usr/bin/env bash
# Feature 0000031 req-005: telemetry stays, the retired MCP is fully gone.
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

echo "=== (b) zero retired-MCP occurrences in live tree ==="
# plan/ and decisions-index.md are change records and exempt. The needle is
# concatenated so this suite never matches itself.
NEEDLE="context""-mode"
HITS=$(grep -rli "$NEEDLE" "$REPO" \
  --exclude-dir=.git --exclude-dir=.claude --exclude-dir=_temp 2>/dev/null \
  | grep -v "$REPO/plan/\|decisions-index.md" | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "live files mentioning the retired MCP"

print_summary
