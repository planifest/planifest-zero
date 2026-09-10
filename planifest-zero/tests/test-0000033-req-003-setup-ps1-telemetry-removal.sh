#!/usr/bin/env bash
# Tests for feature 0000033-remove-telemetry-mcp, req-003:
# setup-ps1-telemetry-removal.
#
# Covers ADR-001 (telemetry is not a framework concern): setup.ps1 carries no
# telemetry flag, no telemetry function, and no telemetry hook entry, while the
# surviving enforcement hooks and the 0000032 setup-config record still install.
# ADR-001 decision 6 drops the backendUrl field from the record and the marker.
#
# No PowerShell runner exists in this CI (backlog 0000084), so pwsh is not
# installed on this machine and these assertions are static: they grep
# setup.ps1's source rather than executing it. A documented manual pwsh run
# fills the execution gap — see tests/README.md.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."
SETUP_PS1="$FRAMEWORK/setup.ps1"
TOOL_PS1="$FRAMEWORK/setup/claude-code.ps1"

# Extracts one function body: from its `function` line up to the next
# top-level `function` line. Scoping matters here because a neighbouring
# function's text would otherwise satisfy an assertion about this one.
extract_function_body() {
  local name="$1"
  awk -v name="function $name" '
    $0 ~ "^" name { flag=1 }
    flag && /^function / && $0 !~ "^" name { exit }
    flag { print }
  ' "$SETUP_PS1"
}

echo ""
echo "=== req-003: setup.ps1 carries no telemetry string ==="

TELEMETRY_HITS="$(grep -c -i 'telemetry' "$SETUP_PS1")"
assert_equals "0" "$TELEMETRY_HITS" \
  "req-003: setup.ps1 contains no telemetry string"

BACKEND_HITS="$(grep -c -i 'backend' "$SETUP_PS1")"
assert_equals "0" "$BACKEND_HITS" \
  "req-003: setup.ps1 contains no backend-url string"

echo ""
echo "=== req-003: telemetry functions are gone ==="

for fn in Merge-TelemetryHookSettings Test-TelemetryHooksInstalled Install-TelemetryHooks; do
  if grep -q "$fn" "$SETUP_PS1"; then
    FOUND="yes"
  else
    FOUND="no"
  fi
  assert_equals "no" "$FOUND" "req-003: $fn is absent from setup.ps1"
done

echo ""
echo "=== req-003: surviving enforcement hooks still install ==="

ENFORCEMENT_BODY="$(extract_function_body 'Merge-EnforcementHookSettings')"

for hook in gate-write check-design auto-trigger-orchestrator check-orchestrator-presence; do
  assert_contains "$hook" "$ENFORCEMENT_BODY" \
    "req-003: Merge-EnforcementHookSettings still names $hook"
done

# Each surviving UserPromptSubmit hook must appear in the de-duplication filter
# as well as the entry build, so a re-run replaces rather than duplicates it.
DEDUP_BLOCK="$(echo "$ENFORCEMENT_BODY" | awk '/UserPromptSubmit \| Where-Object/{flag=1} flag{print} flag && /^        \}\)/{exit}')"
for hook in auto-trigger-orchestrator check-orchestrator-presence check-design; do
  assert_contains "$hook" "$DEDUP_BLOCK" \
    "req-003: UserPromptSubmit de-duplication filter still matches $hook"
done

if echo "$ENFORCEMENT_BODY" | grep -q -i 'telemetry'; then
  FOUND_TELEMETRY_ENTRY="yes"
else
  FOUND_TELEMETRY_ENTRY="no"
fi
assert_equals "no" "$FOUND_TELEMETRY_ENTRY" \
  "req-003: Merge-EnforcementHookSettings has no telemetry entry"

echo ""
echo "=== req-003: setup-config record drops backendUrl ==="

CONFIG_BODY="$(extract_function_body 'Write-SetupConfigOverride')"
ORDERED_HASH="$(echo "$CONFIG_BODY" | awk '/\[ordered\]@\{/{flag=1} flag{print} flag && /^    \} \| ConvertTo-Json/{exit}')"
FIELD_ORDER="$(echo "$ORDERED_HASH" | grep -oE '^\s*(tool|flags|backendUrl|writtenAt)\s*=' | grep -oE '(tool|flags|backendUrl|writtenAt)')"
EXPECTED_ORDER=$'tool\nflags\nwrittenAt'

assert_equals "$EXPECTED_ORDER" "$FIELD_ORDER" \
  "req-003: record hash declares exactly tool, flags, writtenAt"

echo ""
echo "=== req-003: --strict-orchestrator is the only recordable flag ==="

MARKER_BODY="$(extract_function_body 'Write-SetupFlagsMarker')"
CONFIG_FLAGS="$(echo "$CONFIG_BODY" | grep -oE "\\\$flags \+= '--[a-z-]+'" | grep -oE "\-\-[a-z-]+")"
MARKER_FLAGS="$(echo "$MARKER_BODY" | grep -oE "\\\$flags \+= '--[a-z-]+'" | grep -oE "\-\-[a-z-]+")"

assert_equals "--strict-orchestrator" "$CONFIG_FLAGS" \
  "req-003: Write-SetupConfigOverride records only --strict-orchestrator"
assert_equals "--strict-orchestrator" "$MARKER_FLAGS" \
  "req-003: Write-SetupFlagsMarker records only --strict-orchestrator"

if echo "$MARKER_BODY" | grep -q 'backendUrl'; then
  MARKER_BACKEND="yes"
else
  MARKER_BACKEND="no"
fi
assert_equals "no" "$MARKER_BACKEND" \
  "req-003: Write-SetupFlagsMarker no longer writes backendUrl"

echo ""
echo "=== req-003: unknown flags still fail ==="

assert_contains "Unknown flag" "$(cat "$SETUP_PS1")" \
  "req-003: argument parsing keeps the unknown-flag failure path"

echo ""
echo "=== req-003: setup/claude-code.ps1 has no telemetry variable ==="

TOOL_TELEMETRY_HITS="$(grep -c -i 'telemetry' "$TOOL_PS1")"
assert_equals "0" "$TOOL_TELEMETRY_HITS" \
  "req-003: setup/claude-code.ps1 contains no telemetry variable"

print_summary
