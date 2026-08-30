#!/usr/bin/env bash
# Tests for feature 0000027, req-001: wire phase_start/phase_end telemetry
# hooks (emit-phase-start.mjs, emit-phase-end.mjs) into setup.sh/setup.ps1
# alongside context-pressure.mjs.
#
# Grounding gap this closes: install_telemetry_hooks() copies all three
# hooks/telemetry/*.mjs scripts to disk, but merge_telemetry_hook_settings()
# only ever registered a PostToolUse entry for context-pressure.mjs —
# emit-phase-start.mjs/emit-phase-end.mjs were copied but never referenced by
# any hook entry in .claude/settings.json.
#
# Covers:
#   1. A fresh setup.sh claude-code --structured-telemetry-mcp run registers
#      all 3 telemetry hook entries, verified by parsing settings.json (not
#      grepping for the flag).
#   2. planifest-framework/scripts/verify-telemetry-hooks.mjs (the positive-
#      presence check) fails loudly (non-zero) against a settings.json missing
#      an entry, and passes once all 3 are present.
#   3. Idempotency: re-running setup.sh does not duplicate hook entries.
#   4. setup.ps1 parity: static source inspection confirms the equivalent
#      registrations exist (no live PowerShell run required — consistent with
#      test-0000023-req-003-copilot-setup-self-copy.sh parts (f)-(h)).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
VERIFY_SCRIPT="$FRAMEWORK_SRC/scripts/verify-telemetry-hooks.mjs"

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000027_req001_XXXXXX)
  cp -r "$FRAMEWORK_SRC" "$dir/planifest-framework"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

get_hook_json() {
  # get_hook_json <settings_file> <event>
  local settings_file="$1"
  local event="$2"
  node -e "
    const fs = require('fs');
    const raw = fs.readFileSync('$settings_file', 'utf8').replace(/^﻿/,'');
    const j = JSON.parse(raw);
    console.log(JSON.stringify(j?.hooks?.$event ?? []));
  "
}

count_matching_entries() {
  # count_matching_entries <settings_file> <event> <needle>
  local settings_file="$1"
  local event="$2"
  local needle="$3"
  node -e "
    const fs = require('fs');
    const raw = fs.readFileSync('$settings_file', 'utf8').replace(/^﻿/,'');
    const j = JSON.parse(raw);
    const entries = (j?.hooks?.$event ?? []).filter(e =>
      (e.hooks || []).some(h => (h.command || '').includes('$needle'))
    );
    console.log(entries.length);
  "
}

# =============================================================================
# 1. Fresh setup registers all 3 telemetry hooks
# =============================================================================

echo ""
echo "=== req-001: fresh setup registers all 3 telemetry hook entries ==="

WS=$(make_workspace); cd "$WS"
bash planifest-framework/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1
SETUP_EXIT=$?
assert_exit_zero "$SETUP_EXIT" "setup.sh exits 0 with all 3 telemetry hooks wired"

PRE=$(get_hook_json ".claude/settings.json" "PreToolUse")
STOP=$(get_hook_json ".claude/settings.json" "Stop")
POST=$(get_hook_json ".claude/settings.json" "PostToolUse")

assert_contains "context-pressure.mjs" "$POST" "req-001: PostToolUse references context-pressure.mjs"
assert_contains "emit-phase-start.mjs" "$PRE"  "req-001: PreToolUse references emit-phase-start.mjs"
assert_contains "Skill" "$PRE" "req-001: PreToolUse entry for emit-phase-start uses the Skill matcher"
assert_contains "emit-phase-end.mjs" "$STOP" "req-001: Stop references emit-phase-end.mjs"

cd /
rm -rf "$WS"

# =============================================================================
# 2. Positive-presence check (verify-telemetry-hooks.mjs)
# =============================================================================

echo ""
echo "=== req-001: positive-presence check fails loudly when a hook is missing ==="

SCRATCH=$(mktemp -d -t planifest_0000027_verify_XXXXXX)

cat > "$SCRATCH/only-context-pressure.json" << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "node hooks/telemetry/context-pressure.mjs" }] }
    ]
  }
}
EOF

node "$VERIFY_SCRIPT" "$SCRATCH/only-context-pressure.json" >/tmp/verify_out_a.txt 2>&1
EXIT_A=$?
[ "$EXIT_A" -ne 0 ] && assert_equals "0" "0" "req-001: verify script exits non-zero when emit-phase-start/end are missing" \
  || assert_equals "1" "0" "req-001: verify script exits non-zero when emit-phase-start/end are missing"

cat > "$SCRATCH/all-three.json" << 'EOF'
{
  "hooks": {
    "PostToolUse": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "node hooks/telemetry/context-pressure.mjs" }] }
    ],
    "PreToolUse": [
      { "matcher": "Skill", "hooks": [{ "type": "command", "command": "node hooks/telemetry/resolve-phase.mjs start hooks/telemetry/emit-phase-start.mjs" }] }
    ],
    "Stop": [
      { "matcher": ".*", "hooks": [{ "type": "command", "command": "node hooks/telemetry/resolve-phase.mjs end hooks/telemetry/emit-phase-end.mjs" }] }
    ]
  }
}
EOF

node "$VERIFY_SCRIPT" "$SCRATCH/all-three.json" >/tmp/verify_out_b.txt 2>&1
EXIT_B=$?
assert_exit_zero "$EXIT_B" "req-001: verify script exits 0 when all 3 hooks are present"

rm -rf "$SCRATCH" /tmp/verify_out_a.txt /tmp/verify_out_b.txt

# =============================================================================
# 3. Idempotency
# =============================================================================

echo ""
echo "=== req-001: idempotency — re-run produces exactly one entry per script ==="

WS=$(make_workspace); cd "$WS"
bash planifest-framework/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1
bash planifest-framework/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1

COUNT_PRESSURE=$(count_matching_entries ".claude/settings.json" "PostToolUse" "context-pressure")
COUNT_START=$(count_matching_entries ".claude/settings.json" "PreToolUse" "emit-phase-start")
COUNT_END=$(count_matching_entries ".claude/settings.json" "Stop" "emit-phase-end")

assert_equals "1" "$COUNT_PRESSURE" "req-001: exactly one context-pressure entry after two runs"
assert_equals "1" "$COUNT_START" "req-001: exactly one emit-phase-start entry after two runs"
assert_equals "1" "$COUNT_END" "req-001: exactly one emit-phase-end entry after two runs"

cd /
rm -rf "$WS"

# =============================================================================
# 4. setup.ps1 parity (static source inspection)
# =============================================================================

echo ""
echo "=== req-001: setup.ps1 declares equivalent telemetry hook registrations ==="

PS1="$FRAMEWORK_SRC/setup.ps1"
PS1_CONTENT="$(cat "$PS1")"

assert_contains "emit-phase-start.mjs" "$PS1_CONTENT" "req-001: setup.ps1 references emit-phase-start.mjs"
assert_contains "emit-phase-end.mjs" "$PS1_CONTENT" "req-001: setup.ps1 references emit-phase-end.mjs"
assert_contains "resolve-phase.mjs" "$PS1_CONTENT" "req-001: setup.ps1 references resolve-phase.mjs"
assert_contains "PreToolUse" "$PS1_CONTENT" "req-001: setup.ps1 wires a PreToolUse entry"
assert_contains "Stop" "$PS1_CONTENT" "req-001: setup.ps1 wires a Stop entry"

print_summary
