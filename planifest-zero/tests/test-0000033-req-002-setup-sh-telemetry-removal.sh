#!/usr/bin/env bash
# Tests for feature 0000033-remove-telemetry-mcp, req-002:
# setup.sh telemetry removal.
#
# Covers ADR-001 (telemetry is not a framework concern): setup.sh carries no
# telemetry flags, no telemetry functions, and writes no telemetry wiring. The
# six surviving enforcement hooks must still install. Per ADR-001 decision 6
# the setup-config record drops backendUrl and holds tool, flags, writtenAt.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
dir_exists() { [ -d "$1" ] && echo "yes" || echo "no"; }

# Reads a field from the tracked plan/state/{tool}.md file's fenced ```json block.
read_config_field() {
  local file="$1"
  local field="$2"
  awk '/^```json$/{flag=1; next} /^```$/{flag=0} flag' "$file" | node -e '
    let d = "";
    process.stdin.on("data", (c) => (d += c));
    process.stdin.on("end", () => {
      const j = JSON.parse(d);
      const v = j[process.argv[1]];
      console.log(v === undefined ? "absent" : v === null ? "null" : JSON.stringify(v));
    });
  ' "$field" 2>/dev/null
}

# Reports whether a settings.json command string is wired anywhere in hooks.
settings_has_command() {
  local file="$1"
  local needle="$2"
  node -e '
    const fs = require("fs");
    const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8").replace(/^﻿/, ""));
    const needle = process.argv[2];
    let found = false;
    for (const entries of Object.values(s.hooks || {})) {
      for (const entry of entries || []) {
        if ((entry.matcher || "").includes(needle)) found = true;
        for (const h of entry.hooks || []) {
          if ((h.command || "").includes(needle)) found = true;
        }
      }
    }
    console.log(found ? "yes" : "no");
  ' "$file" "$needle" 2>/dev/null
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000033_req002_test_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/planifest-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): the script text carries no telemetry ───────────────────────────────

echo ""
echo "=== req-002 (a): setup.sh and setup/claude-code.sh mention no telemetry ==="

# req-004 and 0000033 ADR-002 require the legacy-cleanup block to name the
# telemetry modules, matcher, and paths so it can find and remove them. So the
# check is not "no telemetry string anywhere": it is that every telemetry string
# sits inside that block, and that no flag, install, or sentinel write survives
# outside it. The block runs from its module-name constants to the end of
# remove_legacy_telemetry_wiring().
OUTSIDE_CLEANUP="$(awk '
  /^# Telemetry hook module names/ { in_block = 1 }
  in_block && /^}/ { in_block = 0; next }
  !in_block { print }
' "$FRAMEWORK/setup.sh" | grep -i "telemetry" | grep -vc "remove_legacy_telemetry_wiring" || true)"
assert_equals "0" "$OUTSIDE_CLEANUP" \
  "req-002 (a): setup.sh has no telemetry string outside the legacy-cleanup block except references to it"

# No telemetry flag is accepted: the argument parser has no case label for it.
assert_equals "0" "$(grep -cE '^\s*--structured-telemetry-mcp\)' "$FRAMEWORK/setup.sh" || true)" \
  "req-002 (a): setup.sh parses no --structured-telemetry-mcp argument"
assert_equals "0" "$(grep -cE '^\s*--backend-url\)' "$FRAMEWORK/setup.sh" || true)" \
  "req-002 (a): setup.sh parses no --backend-url argument"

# No telemetry install path survives.
for FORBIDDEN in "install_telemetry_hooks" "merge_telemetry_hook_settings" "verify_telemetry_hooks_installed" "STRUCTURED_TELEMETRY_MCP"; do
  assert_equals "0" "$(grep -c -- "$FORBIDDEN" "$FRAMEWORK/setup.sh" || true)" \
    "req-002 (a): setup.sh declares no $FORBIDDEN"
done

# The sentinel is only ever removed, never written.
assert_equals "0" "$(grep -c 'touch .*telemetry-enabled\|> .*telemetry-enabled' "$FRAMEWORK/setup.sh" || true)" \
  "req-002 (a): setup.sh never writes the telemetry-enabled sentinel"

TOOL_HITS="$(grep -c -i "telemetry" "$FRAMEWORK/setup/claude-code.sh")"
assert_equals "0" "$TOOL_HITS" \
  "req-002 (a): setup/claude-code.sh contains no telemetry string"

BACKEND_HITS="$(grep -c -i "backend.url\|backendUrl\|BACKEND_URL" "$FRAMEWORK/setup.sh")"
assert_equals "0" "$BACKEND_HITS" \
  "req-002 (a): setup.sh contains no backend-url string"

SYNTAX_OUTPUT="$(bash -n "$FRAMEWORK/setup.sh" 2>&1)"
assert_exit_zero $? "req-002 (a): setup.sh still parses as valid bash"

TOOL_SYNTAX="$(bash -n "$FRAMEWORK/setup/claude-code.sh" 2>&1)"
assert_exit_zero $? "req-002 (a): setup/claude-code.sh still parses as valid bash"

# ── (b): the removed flag is now an unknown argument ────────────────────────

echo ""
echo "=== req-002 (b): --structured-telemetry-mcp is rejected as an unknown argument ==="

WS=$(make_workspace); cd "$WS"

FLAG_OUTPUT="$(bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp 2>&1)"
FLAG_EXIT=$?

if [ "$FLAG_EXIT" -ne 0 ]; then
  FLAG_NONZERO="yes"
else
  FLAG_NONZERO="no"
fi
assert_equals "yes" "$FLAG_NONZERO" \
  "req-002 (b): setup.sh claude-code --structured-telemetry-mcp exits non-zero"

assert_contains "Unknown flag" "$FLAG_OUTPUT" \
  "req-002 (b): the run prints an unknown-argument error"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (c): a clean run installs all six enforcement hooks and no telemetry ────

echo ""
echo "=== req-002 (c): a clean setup run wires six enforcement hooks and no telemetry ==="

WS=$(make_workspace); cd "$WS"

bash planifest-zero/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero $? "req-002 (c): setup exits 0 with no flags"

SETTINGS=".claude/settings.json"
assert_equals "yes" "$(file_exists "$SETTINGS")" \
  "req-002 (c): .claude/settings.json is created"

for hook in gate-write check-design ratchet-check em-dash-guard \
            auto-trigger-orchestrator check-orchestrator-presence; do
  assert_equals "yes" "$(settings_has_command "$SETTINGS" "$hook")" \
    "req-002 (c): $hook is wired in settings.json"
done

for absent in telemetry check-telemetry-failures check-telemetry-receipts \
              context-pressure emit-phase-start emit-phase-end \
              emit-event-receipt mcp__structured-telemetry-mcp__emit_event; do
  assert_equals "no" "$(settings_has_command "$SETTINGS" "$absent")" \
    "req-002 (c): $absent is absent from settings.json"
done

assert_equals "no" "$(file_exists ".claude/telemetry-enabled")" \
  "req-002 (c): no telemetry opt-in sentinel is written"

assert_equals "no" "$(dir_exists ".claude/hooks/telemetry")" \
  "req-002 (c): no telemetry hooks directory is created"

# Re-run: the de-duplication filter must not double-wire the surviving hooks.
count_command() {
  node -e '
    const fs = require("fs");
    const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8").replace(/^﻿/, ""));
    const needle = process.argv[2];
    let n = 0;
    for (const entries of Object.values(s.hooks || {})) {
      for (const entry of entries || []) {
        for (const h of entry.hooks || []) {
          if ((h.command || "").includes(needle)) n++;
        }
      }
    }
    console.log(String(n));
  ' "$1" "$2" 2>/dev/null
}

FIRST_GATE="$(count_command "$SETTINGS" "gate-write")"
FIRST_DESIGN="$(count_command "$SETTINGS" "check-design")"

bash planifest-zero/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero $? "req-002 (c): a second setup run exits 0"

assert_equals "$FIRST_GATE" "$(count_command "$SETTINGS" "gate-write")" \
  "req-002 (c): gate-write is not double-wired on a re-run"
assert_equals "$FIRST_DESIGN" "$(count_command "$SETTINGS" "check-design")" \
  "req-002 (c): check-design is not double-wired on a re-run"

# ── (d): the setup-config record drops backendUrl (ADR-001 decision 6) ──────

echo ""
echo "=== req-002 (d): plan/state/claude-code.md holds tool, flags, writtenAt only ==="

CONFIG="plan/state/claude-code.md"
assert_equals "yes" "$(file_exists "$CONFIG")" \
  "req-002 (d): tracked setup-config record is still written"

assert_equals "absent" "$(read_config_field "$CONFIG" "backendUrl")" \
  "req-002 (d): the record has no backendUrl key"

assert_equals '"claude-code"' "$(read_config_field "$CONFIG" "tool")" \
  "req-002 (d): the record still names the tool"

assert_equals "[]" "$(read_config_field "$CONFIG" "flags")" \
  "req-002 (d): the record's flags array is empty for a no-flag run"

MARKER=".claude/.planifest-setup-flags"
MARKER_BACKEND="$(node -e '
  const fs = require("fs");
  const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  console.log("backendUrl" in j ? "present" : "absent");
' "$MARKER" 2>/dev/null)"
assert_equals "absent" "$MARKER_BACKEND" \
  "req-002 (d): the flags marker has no backendUrl key"

cd "$SCRIPT_DIR"
rm -rf "$WS"

print_summary
