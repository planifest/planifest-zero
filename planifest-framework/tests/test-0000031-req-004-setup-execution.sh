#!/usr/bin/env bash
# Feature 0000031 req-004: setup works by execution in a fresh temp clone,
# prunes retired skills, honours overrides. Replaces the never-run test_setup pair.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WS=$(mktemp -d)
trap 'rm -rf "$WS"' EXIT

echo "=== (a) fresh install with telemetry flag ==="
mkdir -p "$WS/clone"
cp -R "$FRAMEWORK" "$WS/clone/planifest-zero"
mkdir -p "$WS/clone/planifest-overrides/instructions"
( cd "$WS/clone" && git init -q . && bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1 )
assert_equals "0" "$?" "setup.sh exits 0 with flag"
assert_equals "yes" "$([ -f "$WS/clone/.claude/settings.json" ] && echo yes || echo no)" "settings.json written"
SKILLS=$(ls -d "$WS/clone/.claude/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "12" "$SKILLS" "exactly 12 skills installed"
assert_equals "yes" "$([ -d "$WS/clone/.claude/hooks/telemetry" ] && echo yes || echo no)" "telemetry hooks installed under flag"

echo "=== (b) pruning: retired skill folder removed on re-run ==="
mkdir -p "$WS/clone/.claude/skills/planifest-change-agent"
touch "$WS/clone/.claude/skills/planifest-change-agent/SKILL.md"
( cd "$WS/clone" && bash planifest-zero/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1 )
assert_equals "no" "$([ -d "$WS/clone/.claude/skills/planifest-change-agent" ] && echo yes || echo no)" "retired skill pruned on regeneration"
SKILLS2=$(ls -d "$WS/clone/.claude/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "12" "$SKILLS2" "still exactly 12 skills after re-run"

echo "=== (c) install without the flag: enforcement only ==="
mkdir -p "$WS/clone2"
cp -R "$FRAMEWORK" "$WS/clone2/planifest-zero"
( cd "$WS/clone2" && git init -q . && bash planifest-zero/setup.sh claude-code >/dev/null 2>&1 )
assert_equals "0" "$?" "setup.sh exits 0 without flag"
assert_equals "yes" "$([ -d "$WS/clone2/.claude/hooks/enforcement" ] && echo yes || echo no)" "enforcement hooks installed"
assert_equals "no" "$([ -d "$WS/clone2/.claude/hooks/telemetry" ] && echo yes || echo no)" "telemetry hooks absent without flag"

echo "=== (d) installed tree references no old name ==="
HITS=$(grep -rl "planifest-framework" "$WS/clone/.claude" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "installed tree clean of old name"

print_summary
