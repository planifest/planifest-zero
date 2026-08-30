#!/usr/bin/env bash
# Tests for feature 0000027, req-004: telemetry compliance backstop (ADR-001).
#
# Covers:
#   hooks/telemetry/emit-event-receipt.mjs (PostToolUse, matched on the
#   emit_event MCP tool call):
#     1. A successful emit_event call writes a receipt under
#        plan/.telemetry-receipts/{phase}-{event_type}-{ts}.marker.
#     2. A failed emit_event call (tool_response.is_error) writes no receipt.
#     3. A malformed tool_input (no envelope/event/phase) writes no receipt
#        and instead writes a plan/.telemetry-failures/ marker (ADR-001's own
#        risk-mitigation note: this hook's own failures route through the
#        existing marker mechanism).
#
#   hooks/enforcement/check-telemetry-receipts.mjs (UserPromptSubmit sibling
#   of check-telemetry-failures.mjs):
#     4. build-log.md with "Telemetry | emitted" for a phase with zero
#        matching receipts -> additionalContext flags the gap (the exact
#        failure mode from feature 0000025's P0-P2 run: Telemetry marked
#        "emitted" with no corresponding emit_event call).
#     5. Same phase WITH a matching receipt -> no flag, no additionalContext.
#     6. "Telemetry | confirmed-disabled" / "failed-with-recorded-choice" ->
#        never flagged regardless of receipts (only "emitted" claims a call
#        happened).
#
#   setup.sh wiring:
#     7. A fresh --structured-telemetry-mcp setup registers emit-event-receipt.mjs
#        as a PostToolUse entry matched on the emit_event tool.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
RECEIPT_HOOK="$FRAMEWORK/hooks/telemetry/emit-event-receipt.mjs"
RECEIPTS_CHECK_HOOK="$FRAMEWORK/hooks/enforcement/check-telemetry-receipts.mjs"

get_additional_context() {
  local output="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$output" | jq -r '.additionalContext // ""' 2>/dev/null
  else
    printf '%s' "$output" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);console.log(j?.additionalContext??'');}catch{console.log('');}});"
  fi
}

# =============================================================================
# 1. Successful emit_event call writes a receipt
# =============================================================================

echo ""
echo "=== req-004: successful emit_event call writes a receipt ==="

WS_A=$(mktemp -d -t planifest_0000027_req004_a_XXXXXX)
INPUT_A=$(cat << EOF
{
  "cwd": "$WS_A",
  "tool_name": "mcp__structured-telemetry-mcp__emit_event",
  "tool_input": { "envelope": { "schema_version": "1.0", "event": "adr_decision", "phase": "plan", "product_id": "demo" } },
  "tool_response": { "ok": true }
}
EOF
)
printf '%s' "$INPUT_A" | node "$RECEIPT_HOOK" >/tmp/receipt_out_a.txt 2>&1
EXIT_A=$?
assert_exit_zero "$EXIT_A" "req-004: emit-event-receipt.mjs exits 0 on a successful call"

RECEIPT_A=$(find "$WS_A/plan/.telemetry-receipts" -name "plan-adr_decision-*.marker" 2>/dev/null | head -1)
assert_equals "yes" "$([ -n "$RECEIPT_A" ] && echo yes || echo no)" \
  "req-004: receipt file written for phase=plan, event_type=adr_decision"

if [ -n "$RECEIPT_A" ]; then
  assert_contains "adr_decision" "$(cat "$RECEIPT_A")" "req-004: receipt content records event_type"
  assert_contains "\"plan\"" "$(cat "$RECEIPT_A")" "req-004: receipt content records phase"
fi

rm -rf "$WS_A" /tmp/receipt_out_a.txt

# =============================================================================
# 2. Failed emit_event call writes no receipt
# =============================================================================

echo ""
echo "=== req-004: failed emit_event call writes no receipt ==="

WS_B=$(mktemp -d -t planifest_0000027_req004_b_XXXXXX)
INPUT_B=$(cat << EOF
{
  "cwd": "$WS_B",
  "tool_name": "mcp__structured-telemetry-mcp__emit_event",
  "tool_input": { "envelope": { "schema_version": "1.0", "event": "security_finding", "phase": "security" } },
  "tool_response": { "is_error": true }
}
EOF
)
printf '%s' "$INPUT_B" | node "$RECEIPT_HOOK" >/tmp/receipt_out_b.txt 2>&1
EXIT_B=$?
assert_exit_zero "$EXIT_B" "req-004: emit-event-receipt.mjs exits 0 on a failed call"

RECEIPT_B_COUNT=$(find "$WS_B/plan/.telemetry-receipts" -name "*.marker" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$RECEIPT_B_COUNT" "req-004: no receipt written when the emit_event call itself failed"

rm -rf "$WS_B" /tmp/receipt_out_b.txt

# =============================================================================
# 3. Malformed tool_input writes a failure marker, not a receipt
# =============================================================================

echo ""
echo "=== req-004: malformed tool_input routes through plan/.telemetry-failures/ ==="

WS_C=$(mktemp -d -t planifest_0000027_req004_c_XXXXXX)
INPUT_C=$(cat << EOF
{
  "cwd": "$WS_C",
  "tool_name": "mcp__structured-telemetry-mcp__emit_event",
  "tool_input": { "envelope": { "schema_version": "1.0" } },
  "tool_response": { "ok": true }
}
EOF
)
printf '%s' "$INPUT_C" | node "$RECEIPT_HOOK" >/tmp/receipt_out_c.txt 2>&1
EXIT_C=$?
assert_exit_zero "$EXIT_C" "req-004: emit-event-receipt.mjs exits 0 on malformed tool_input"

RECEIPT_C_COUNT=$(find "$WS_C/plan/.telemetry-receipts" -name "*.marker" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$RECEIPT_C_COUNT" "req-004: no receipt written for malformed tool_input"

FAILURE_C=$(find "$WS_C/plan/.telemetry-failures" -name "emit-event-receipt*.json" 2>/dev/null | head -1)
assert_equals "yes" "$([ -n "$FAILURE_C" ] && echo yes || echo no)" \
  "req-004: malformed tool_input routes through plan/.telemetry-failures/ (ADR-001 risk mitigation)"

rm -rf "$WS_C" /tmp/receipt_out_c.txt

# =============================================================================
# 3b. Path-traversal via envelope.phase/event is rejected, not written (CWE-22,
#     found and fixed during this feature's own P5 security review)
# =============================================================================

echo ""
echo "=== req-004: envelope.phase/event outside the known enum is rejected (path-traversal guard) ==="

WS_D=$(mktemp -d -t planifest_0000027_req004_d_XXXXXX)
INPUT_D=$(cat << 'EOF'
{
  "cwd": "__WS_D__",
  "tool_name": "mcp__structured-telemetry-mcp__emit_event",
  "tool_input": { "envelope": { "schema_version": "1.0", "event": "../../../../tmp/evil", "phase": "../../etc" } },
  "tool_response": { "ok": true }
}
EOF
)
INPUT_D="${INPUT_D//__WS_D__/$WS_D}"
printf '%s' "$INPUT_D" | node "$RECEIPT_HOOK" >/tmp/receipt_out_d.txt 2>&1
EXIT_D=$?
assert_exit_zero "$EXIT_D" "req-004: emit-event-receipt.mjs exits 0 on an out-of-enum phase/event (fail-open, ADR-005)"

RECEIPT_D_COUNT=$(find "$WS_D" -name "*.marker" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$RECEIPT_D_COUNT" "req-004: no receipt written anywhere under the workspace for an out-of-enum phase/event"

OUTSIDE_TMP_FILE=$(find /tmp -maxdepth 1 -newer "$WS_D" -name "evil*" 2>/dev/null | head -1)
assert_equals "yes" "$([ -z "$OUTSIDE_TMP_FILE" ] && echo yes || echo no)" \
  "req-004: no file written outside the workspace via a crafted event/phase value"

FAILURE_D=$(find "$WS_D/plan/.telemetry-failures" -name "emit-event-receipt*.json" 2>/dev/null | head -1)
assert_equals "yes" "$([ -n "$FAILURE_D" ] && echo yes || echo no)" \
  "req-004: rejected phase/event routes through plan/.telemetry-failures/ like any other malformed input"

rm -rf "$WS_D" /tmp/receipt_out_d.txt

# =============================================================================
# 4. check-telemetry-receipts.mjs: emitted claim with zero receipts is flagged
# =============================================================================

echo ""
echo "=== req-004: build-log 'Telemetry | emitted' with no receipts is flagged ==="

WS_D=$(mktemp -d -t planifest_0000027_req004_d_XXXXXX)
mkdir -p "$WS_D/plan/current"
cat > "$WS_D/plan/current/build-log.md" << 'EOF'
# Build Log

### P2: Plan

| Field | Value |
|-------|-------|
| Telemetry | emitted |
EOF

INPUT_D="{\"cwd\":\"$WS_D\"}"
OUTPUT_D=$(printf '%s' "$INPUT_D" | node "$RECEIPTS_CHECK_HOOK" 2>&1)
EXIT_D=$?
assert_exit_zero "$EXIT_D" "req-004: check-telemetry-receipts.mjs exits 0 (advisory, never blocks)"

CTX_D="$(get_additional_context "$OUTPUT_D")"
assert_equals "yes" "$([ -n "$CTX_D" ] && echo yes || echo no)" \
  "req-004: additionalContext non-empty when a phase claims 'emitted' with no receipts"
assert_contains "plan" "$CTX_D" "req-004: flagged phase (plan) named in the reminder"

rm -rf "$WS_D"

# =============================================================================
# 5. check-telemetry-receipts.mjs: emitted claim WITH a matching receipt -> silent
# =============================================================================

echo ""
echo "=== req-004: build-log 'Telemetry | emitted' WITH a matching receipt is silent ==="

WS_E=$(mktemp -d -t planifest_0000027_req004_e_XXXXXX)
mkdir -p "$WS_E/plan/current" "$WS_E/plan/.telemetry-receipts"
cat > "$WS_E/plan/current/build-log.md" << 'EOF'
# Build Log

### P2: Plan

| Field | Value |
|-------|-------|
| Telemetry | emitted |
EOF
cat > "$WS_E/plan/.telemetry-receipts/plan-adr_decision-2026-08-08T00-00-00.000Z.marker" << 'EOF'
{ "phase": "plan", "event_type": "adr_decision" }
EOF

INPUT_E="{\"cwd\":\"$WS_E\"}"
OUTPUT_E=$(printf '%s' "$INPUT_E" | node "$RECEIPTS_CHECK_HOOK" 2>&1)
EXIT_E=$?
assert_exit_zero "$EXIT_E" "req-004: check-telemetry-receipts.mjs exits 0 when receipts back the claim"

CTX_E="$(get_additional_context "$OUTPUT_E")"
assert_equals "" "$CTX_E" "req-004: no additionalContext when a matching receipt exists for the phase"

rm -rf "$WS_E"

# =============================================================================
# 6. Non-"emitted" Telemetry states are never flagged, regardless of receipts
# =============================================================================

echo ""
echo "=== req-004: 'confirmed-disabled'/'failed-with-recorded-choice' never flagged ==="

WS_F=$(mktemp -d -t planifest_0000027_req004_f_XXXXXX)
mkdir -p "$WS_F/plan/current"
cat > "$WS_F/plan/current/build-log.md" << 'EOF'
# Build Log

### P4: Validate and Accept

| Field | Value |
|-------|-------|
| Telemetry | confirmed-disabled |

### P3: Implement

| Field | Value |
|-------|-------|
| Telemetry | failed-with-recorded-choice |
EOF

INPUT_F="{\"cwd\":\"$WS_F\"}"
OUTPUT_F=$(printf '%s' "$INPUT_F" | node "$RECEIPTS_CHECK_HOOK" 2>&1)
EXIT_F=$?
assert_exit_zero "$EXIT_F" "req-004: check-telemetry-receipts.mjs exits 0 for non-emitted states"
CTX_F="$(get_additional_context "$OUTPUT_F")"
assert_equals "" "$CTX_F" "req-004: no additionalContext for confirmed-disabled/failed-with-recorded-choice phases"

rm -rf "$WS_F"

# =============================================================================
# 7. setup.sh wiring: emit-event-receipt.mjs registered as PostToolUse
# =============================================================================

echo ""
echo "=== req-004: setup.sh registers emit-event-receipt.mjs (PostToolUse, emit_event matcher) ==="

WS_G=$(mktemp -d -t planifest_0000027_req004_g_XXXXXX)
cp -r "$FRAMEWORK" "$WS_G/planifest-zero"
git init "$WS_G" >/dev/null 2>&1
git config --global --add safe.directory "$WS_G" >/dev/null 2>&1 || true
(cd "$WS_G" && bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1)

POST_G=$(node -e "
  const fs = require('fs');
  const raw = fs.readFileSync('$WS_G/.claude/settings.json', 'utf8').replace(/^﻿/,'');
  const j = JSON.parse(raw);
  console.log(JSON.stringify(j?.hooks?.PostToolUse ?? []));
")
assert_contains "emit-event-receipt.mjs" "$POST_G" "req-004: PostToolUse references emit-event-receipt.mjs"
assert_contains "mcp__structured-telemetry-mcp__emit_event" "$POST_G" "req-004: matcher targets the emit_event MCP tool call"

rm -rf "$WS_G"

# =============================================================================
# 8. setup.ps1 parity (static source inspection)
# =============================================================================

echo ""
echo "=== req-004: setup.ps1 declares equivalent receipt/check-receipts registrations ==="

PS1_CONTENT="$(cat "$FRAMEWORK/setup.ps1")"
assert_contains "emit-event-receipt.mjs" "$PS1_CONTENT" "req-004: setup.ps1 references emit-event-receipt.mjs"
assert_contains "check-telemetry-receipts.mjs" "$PS1_CONTENT" "req-004: setup.ps1 references check-telemetry-receipts.mjs"
assert_contains "mcp__structured-telemetry-mcp__emit_event" "$PS1_CONTENT" "req-004: setup.ps1 matcher targets the emit_event MCP tool call"

# =============================================================================
# 9. --backend-url is validated before it can reach shell interpolation in
#    merge_telemetry_hook_settings() (backlog 0000055, found/fixed during
#    this feature's own P5 security review)
# =============================================================================

echo ""
echo "=== req-004: --backend-url rejects shell metacharacters, accepts a plain URL ==="

WS_H=$(mktemp -d -t planifest_0000027_req004_h_XXXXXX)
cp -r "$FRAMEWORK" "$WS_H/planifest-zero"

(cd "$WS_H" && bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp --backend-url 'http://evil.example;touch /tmp/planifest_0000055_pwned' >/tmp/backend_url_bad.log 2>&1)
BAD_EXIT=$?
assert_equals "1" "$BAD_EXIT" "req-004: setup.sh exits 1 on a backend-url containing shell metacharacters"
assert_equals "no" "$([ -f /tmp/planifest_0000055_pwned ] && echo yes || echo no)" \
  "req-004: the injected command in a rejected backend-url never actually runs"
rm -f /tmp/planifest_0000055_pwned

(cd "$WS_H" && bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp --backend-url 'http://localhost:9999' >/tmp/backend_url_good.log 2>&1)
GOOD_EXIT=$?
assert_equals "0" "$GOOD_EXIT" "req-004: setup.sh still accepts a plain http(s) URL for --backend-url"

rm -rf "$WS_H" /tmp/backend_url_bad.log /tmp/backend_url_good.log

PS1_BACKEND_URL_SECTION="$(cat "$FRAMEWORK/setup.ps1")"
assert_contains "notmatch '^https?://" "$PS1_BACKEND_URL_SECTION" "req-004: setup.ps1 validates --backend-url with the equivalent regex"

print_summary
