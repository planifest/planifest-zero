#!/usr/bin/env bash
# Tests for feature 0000033-remove-telemetry-mcp, req-004:
# upgrade cleanup of telemetry wiring.
#
# Covers ADR-002 (setup cleans up telemetry wiring on every run): every setup
# run strips telemetry hook entries from the project's .claude/settings.json,
# deletes .claude/telemetry-enabled, and deletes plan/.telemetry-failures/ and
# plan/.telemetry-receipts/. Non-telemetry entries survive untouched, one line
# is printed per removal, a failed removal warns without failing the run, and
# a run with nothing to remove is silent.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
dir_exists() { [ -d "$1" ] && echo "yes" || echo "no"; }

# The telemetry hook module names ADR-002 names for removal.
TELEMETRY_MODULES=(
  emit-phase-start
  emit-phase-end
  emit-event-receipt
  emit-event
  context-pressure
  resolve-phase
  record-telemetry-failure
  check-telemetry-failures
  check-telemetry-receipts
)

# Reports whether a settings.json matcher or command string is wired anywhere.
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

# Counts hook entries whose command contains a needle.
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

# Reports the matcher of the first entry whose command contains a needle.
matcher_of_command() {
  node -e '
    const fs = require("fs");
    const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8").replace(/^﻿/, ""));
    const needle = process.argv[2];
    let found = null;
    for (const entries of Object.values(s.hooks || {})) {
      for (const entry of entries || []) {
        for (const h of entry.hooks || []) {
          if (found === null && (h.command || "").includes(needle)) found = entry.matcher || "";
        }
      }
    }
    console.log(found === null ? "absent" : found);
  ' "$1" "$2" 2>/dev/null
}

# Counts output lines mentioning telemetry (removal lines and warnings).
count_telemetry_lines() {
  printf '%s\n' "$1" | grep -c -i "telemetry" || true
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000033_req004_test_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/planifest-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# Seeds a project that previously ran setup.sh --structured-telemetry-mcp:
# telemetry hook entries alongside the six enforcement entries and one
# user-added hook, the opt-in sentinel, and both marker directories.
seed_legacy_wiring() {
  local root="$1"
  mkdir -p "$root/.claude" "$root/plan/.telemetry-failures" "$root/plan/.telemetry-receipts"

  cat > "$root/.claude/settings.json" << 'JSON'
{
  "allowedTools": ["Agent"],
  "hooks": {
    "PreToolUse": [
      {"matcher": "Write", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/gate-write.mjs\""}]},
      {"matcher": "Edit", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/gate-write.mjs\""}]},
      {"matcher": "Write", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/ratchet-check.mjs\""}]},
      {"matcher": "Edit", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/em-dash-guard.mjs\""}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "node .claude/hooks/mine/audit-shell.mjs"}]}
    ],
    "UserPromptSubmit": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/auto-trigger-orchestrator.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/check-orchestrator-presence.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/enforcement/check-design.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/emit-phase-start.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/context-pressure.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/check-telemetry-failures.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/check-telemetry-receipts.mjs\""}]}
    ],
    "PostToolUse": [
      {"matcher": "mcp__structured-telemetry-mcp__emit_event", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/emit-event-receipt.mjs\""}]},
      {"matcher": "Write", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/resolve-phase.mjs\""}]}
    ],
    "Stop": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/emit-event.mjs\""}]},
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/emit-phase-end.mjs\""}]}
    ],
    "SubagentStop": [
      {"matcher": ".*", "hooks": [{"type": "command", "command": "node \".claude/hooks/telemetry/record-telemetry-failure.mjs\""}]}
    ]
  }
}
JSON

  echo "enabled" > "$root/.claude/telemetry-enabled"
  echo "failure record" > "$root/plan/.telemetry-failures/2026-01-01.json"
  echo "receipt record" > "$root/plan/.telemetry-receipts/2026-01-01.json"
}

# ── (a): an upgraded project loses its telemetry wiring ─────────────────────

echo ""
echo "=== req-004 (a): setup strips telemetry wiring from an upgraded project ==="

WS=$(make_workspace)
seed_legacy_wiring "$WS"
cd "$WS"

RUN_OUTPUT="$(bash planifest-zero/setup.sh claude-code 2>&1)"
RUN_EXIT=$?

assert_exit_zero "$RUN_EXIT" \
  "req-004 (a): setup exits 0 on a project with telemetry wiring"

SETTINGS=".claude/settings.json"

for module in "${TELEMETRY_MODULES[@]}"; do
  assert_equals "no" "$(settings_has_command "$SETTINGS" "$module")" \
    "req-004 (a): $module is gone from settings.json"
done

assert_equals "no" "$(settings_has_command "$SETTINGS" "mcp__structured-telemetry-mcp__emit_event")" \
  "req-004 (a): the telemetry matcher is gone from settings.json"

assert_equals "no" "$(settings_has_command "$SETTINGS" "hooks/telemetry")" \
  "req-004 (a): no command still points at .claude/hooks/telemetry/"

for hook in gate-write check-design ratchet-check em-dash-guard \
            auto-trigger-orchestrator check-orchestrator-presence; do
  assert_equals "yes" "$(settings_has_command "$SETTINGS" "$hook")" \
    "req-004 (a): enforcement hook $hook survives the cleanup"
done

assert_equals "no" "$(file_exists ".claude/telemetry-enabled")" \
  "req-004 (a): the .claude/telemetry-enabled sentinel is deleted"

assert_equals "no" "$(dir_exists "plan/.telemetry-failures")" \
  "req-004 (a): plan/.telemetry-failures/ is deleted with its contents"

assert_equals "no" "$(dir_exists "plan/.telemetry-receipts")" \
  "req-004 (a): plan/.telemetry-receipts/ is deleted with its contents"

assert_contains "$SETTINGS" "$RUN_OUTPUT" \
  "req-004 (a): a removal line names the settings file"

assert_contains ".claude/telemetry-enabled" "$RUN_OUTPUT" \
  "req-004 (a): a removal line names the sentinel"

assert_contains "plan/.telemetry-failures" "$RUN_OUTPUT" \
  "req-004 (a): a removal line names the failures directory"

assert_contains "plan/.telemetry-receipts" "$RUN_OUTPUT" \
  "req-004 (a): a removal line names the receipts directory"

assert_equals "4" "$(count_telemetry_lines "$RUN_OUTPUT")" \
  "req-004 (a): exactly one line is printed per removed item"

assert_equals "0" "$(printf '%s\n' "$RUN_OUTPUT" | grep -c "Warning" || true)" \
  "req-004 (a): the successful cleanup prints no warning"

# ── (b): a user-added hook entry survives untouched ─────────────────────────

echo ""
echo "=== req-004 (b): a user-added hook entry is left untouched ==="

assert_equals "1" "$(count_command "$SETTINGS" "audit-shell")" \
  "req-004 (b): the user-added hook is still wired exactly once"

assert_equals "Bash" "$(matcher_of_command "$SETTINGS" "audit-shell")" \
  "req-004 (b): the user-added hook keeps its own matcher"

# ── (c): a second run is silent ─────────────────────────────────────────────

echo ""
echo "=== req-004 (c): a second run prints no removal line ==="

SECOND_OUTPUT="$(bash planifest-zero/setup.sh claude-code 2>&1)"
SECOND_EXIT=$?

assert_exit_zero "$SECOND_EXIT" \
  "req-004 (c): a second setup run exits 0"

assert_equals "0" "$(count_telemetry_lines "$SECOND_OUTPUT")" \
  "req-004 (c): the second run prints no telemetry removal line"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (d): a clean project is silent ──────────────────────────────────────────

echo ""
echo "=== req-004 (d): a project with no telemetry wiring prints nothing ==="

WS=$(make_workspace); cd "$WS"

CLEAN_OUTPUT="$(bash planifest-zero/setup.sh claude-code 2>&1)"
CLEAN_EXIT=$?

assert_exit_zero "$CLEAN_EXIT" \
  "req-004 (d): setup exits 0 on a clean project"

assert_equals "0" "$(count_telemetry_lines "$CLEAN_OUTPUT")" \
  "req-004 (d): a clean project prints no telemetry removal line"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (e): a removal that cannot succeed warns once and continues ─────────────

echo ""
echo "=== req-004 (e): an unwritable item warns once and setup still exits 0 ==="

WS=$(make_workspace); cd "$WS"

mkdir -p "$WS/plan/.telemetry-failures"
echo "failure record" > "$WS/plan/.telemetry-failures/2026-01-01.json"
chmod 555 "$WS/plan/.telemetry-failures"

LOCKED_OUTPUT="$(bash planifest-zero/setup.sh claude-code 2>&1)"
LOCKED_EXIT=$?

assert_exit_zero "$LOCKED_EXIT" \
  "req-004 (e): setup still exits 0 when a removal fails"

assert_equals "1" "$(printf '%s\n' "$LOCKED_OUTPUT" | grep -c -i "telemetry" || true)" \
  "req-004 (e): exactly one line is printed for the failed removal"

assert_contains "Warning" "$LOCKED_OUTPUT" \
  "req-004 (e): the printed line is a warning"

assert_contains "plan/.telemetry-failures" "$LOCKED_OUTPUT" \
  "req-004 (e): the warning names the item it could not remove"

assert_equals "yes" "$(file_exists "plan/.telemetry-failures/2026-01-01.json")" \
  "req-004 (e): the unremovable item is left alone"

chmod 755 "$WS/plan/.telemetry-failures"
cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (f): setup.ps1 mirrors the bash cleanup (static) ────────────────────────

echo ""
echo "=== req-004 (f): setup.ps1 defines and calls the mirror cleanup function ==="

PS1="$FRAMEWORK/setup.ps1"

assert_equals "1" "$(grep -c "^function Remove-LegacyTelemetryWiring" "$PS1" || true)" \
  "req-004 (f): setup.ps1 defines Remove-LegacyTelemetryWiring once"

for module in "${TELEMETRY_MODULES[@]}"; do
  PS1_HITS="$(grep -c -- "$module" "$PS1" || true)"
  if [ "$PS1_HITS" -gt 0 ]; then PS1_HAS="yes"; else PS1_HAS="no"; fi
  assert_equals "yes" "$PS1_HAS" \
    "req-004 (f): setup.ps1 names the $module module"
done

PS1_MATCHER="$(grep -c -- "mcp__structured-telemetry-mcp__emit_event" "$PS1" || true)"
if [ "$PS1_MATCHER" -gt 0 ]; then PS1_MATCHER_HAS="yes"; else PS1_MATCHER_HAS="no"; fi
assert_equals "yes" "$PS1_MATCHER_HAS" \
  "req-004 (f): setup.ps1 names the telemetry matcher string"

PS1_CALL_LINE="$(grep -n "Remove-LegacyTelemetryWiring " "$PS1" | grep -v "^.*function " | head -1 | cut -d: -f1)"
PS1_INSTALL_LINE="$(grep -n "Install-EnforcementHooks \`" "$PS1" | head -1 | cut -d: -f1)"

if [ -n "$PS1_CALL_LINE" ] && [ -n "$PS1_INSTALL_LINE" ] && [ "$PS1_CALL_LINE" -lt "$PS1_INSTALL_LINE" ]; then
  PS1_ORDER="before"
else
  PS1_ORDER="not-before"
fi
assert_equals "before" "$PS1_ORDER" \
  "req-004 (f): setup.ps1 calls the cleanup before the enforcement hook install"

# The bash side must use the same order, so the enforcement install is the last
# writer of settings.json on every run.
SH_CALL_LINE="$(grep -n "remove_legacy_telemetry_wiring \"" "$FRAMEWORK/setup.sh" | head -1 | cut -d: -f1)"
SH_INSTALL_LINE="$(grep -n "install_enforcement_hooks \"hooks/enforcement\"" "$FRAMEWORK/setup.sh" | head -1 | cut -d: -f1)"

if [ -n "$SH_CALL_LINE" ] && [ -n "$SH_INSTALL_LINE" ] && [ "$SH_CALL_LINE" -lt "$SH_INSTALL_LINE" ]; then
  SH_ORDER="before"
else
  SH_ORDER="not-before"
fi
assert_equals "before" "$SH_ORDER" \
  "req-004 (f): setup.sh calls the cleanup before the enforcement hook install"

print_summary
