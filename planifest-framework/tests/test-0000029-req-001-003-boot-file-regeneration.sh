#!/usr/bin/env bash
# Tests for feature 0000029-context-mode-removal-and-boot-file-regeneration-fix.
#
# req-001: write_boot_file/Write-PlanifestBootFile always overwrite the boot
#          file from the current template (skip-if-exists guard removed), with
#          planifest-overrides/instructions/ content re-applied every run.
# req-002: templates/standard-boot.md carries no context-mode MCP reference;
#          generated boot files carry none; the opt-in --context-mode-mcp
#          hook-install path is untouched.
# req-003: planifest-overrides/instructions/custom-001-local-git-only.md
#          (repo-local config, not distributed source) authorizes pull/push/PR
#          creation and names commits-to-main and PR-merge as human-only.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."
REPO_ROOT="$(cd "$FRAMEWORK/.." && pwd)"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }
grep_count() { local c; c=$(grep -ci "$1" "$2" 2>/dev/null || true); echo "${c:-0}"; }
fn_has() {
  # grep inside one shell/PowerShell function body only (start pattern to closing brace)
  sed -n "/$1/,/^}/p" "$3" | grep -q "$2" && echo "yes" || echo "no"
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000029_test_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/planifest-framework"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a) req-001: fresh workspace, boot file created ─────────────────────────

echo ""
echo "=== (a) req-001: setup.sh claude-code creates CLAUDE.md on fresh workspace ==="

WS=$(make_workspace); cd "$WS"
bash planifest-framework/setup.sh claude-code >/tmp/planifest_0000029_a.log 2>&1
assert_exit_zero "$?" "(a): setup.sh claude-code exits 0 on fresh workspace"
assert_equals "yes" "$(file_exists "CLAUDE.md")" "(a): CLAUDE.md created"

# ── (b) req-001: rerun regenerates, hand-edit is replaced ───────────────────

echo ""
echo "=== (b) req-001: rerun overwrites an existing CLAUDE.md (no skip-if-exists) ==="

echo "SENTINEL-HAND-EDIT-0000029" >> CLAUDE.md
bash planifest-framework/setup.sh claude-code >/tmp/planifest_0000029_b.log 2>&1
assert_exit_zero "$?" "(b): rerun exits 0"
assert_equals "no" "$(grep_has "SENTINEL-HAND-EDIT-0000029" "CLAUDE.md")" \
  "(b): hand-edited sentinel is gone after rerun (file regenerated)"

# ── (c) req-001: override instructions re-applied on every run ──────────────

echo ""
echo "=== (c) req-001: planifest-overrides/instructions/ content present after rerun ==="

mkdir -p planifest-overrides/instructions
printf '### Test Override\nOVERRIDE-MARKER-0000029\n' > planifest-overrides/instructions/custom-900-test.md
bash planifest-framework/setup.sh claude-code >/tmp/planifest_0000029_c.log 2>&1
assert_exit_zero "$?" "(c): rerun with overrides exits 0"
assert_equals "yes" "$(grep_has "OVERRIDE-MARKER-0000029" "CLAUDE.md")" \
  "(c): override content re-applied into regenerated CLAUDE.md"

# ── (d) req-001: setup.ps1 parity (static) ──────────────────────────────────

echo ""
echo "=== (d) req-001: Write-PlanifestBootFile has no skip-if-exists branch ==="

assert_equals "no" "$(fn_has "^function Write-PlanifestBootFile" "skipped" "$FRAMEWORK/setup.ps1")" \
  "(d): Write-PlanifestBootFile no longer has a skip branch (function-scoped check)"
assert_equals "no" "$(fn_has "^write_boot_file()" "skipped" "$FRAMEWORK/setup.sh")" \
  "(d): write_boot_file no longer has a skip branch (function-scoped check)"

# ── (e) req-002: standard-boot.md carries no context-mode reference ─────────

echo ""
echo "=== (e) req-002: templates/standard-boot.md is context-mode free ==="

BOOT_TEMPLATE="$FRAMEWORK/templates/standard-boot.md"
assert_equals "0" "$(grep_count "context-mode" "$BOOT_TEMPLATE")" \
  "(e): zero 'context-mode' occurrences in standard-boot.md"
assert_equals "0" "$(grep_count "ctx_batch_execute" "$BOOT_TEMPLATE")" \
  "(e): zero 'ctx_batch_execute' occurrences in standard-boot.md"

# ── (f) req-002: generated boot file carries no context-mode reference ──────

echo ""
echo "=== (f) req-002: regenerated CLAUDE.md is context-mode free ==="

assert_equals "0" "$(grep_count "context-mode" "$WS/CLAUDE.md")" \
  "(f): zero 'context-mode' occurrences in generated CLAUDE.md"

# ── (g) req-002: opt-in --context-mode-mcp path untouched ───────────────────

echo ""
echo "=== (g) req-002: install_context_mode_hooks still present in setup.sh ==="

assert_equals "yes" "$(grep_has "install_context_mode_hooks" "$FRAMEWORK/setup.sh")" \
  "(g): install_context_mode_hooks function still exists (out of scope, untouched)"
assert_equals "yes" "$(grep_has "context-mode-mcp" "$FRAMEWORK/setup.sh")" \
  "(g): --context-mode-mcp flag still parsed (out of scope, untouched)"

# ── (h) req-003: repo-local git-permission override wording ─────────────────

echo ""
echo "=== (h) req-003: custom-001 override authorizes pull/push/PR-create ==="

OVERRIDE_FILE="$REPO_ROOT/planifest-overrides/instructions/custom-001-local-git-only.md"
assert_equals "no" "$(grep_has "pull, push or otherwise attempt" "$OVERRIDE_FILE")" \
  "(h): old 'don't fetch, pull, push' wording removed"
assert_equals "yes" "$(grep_has "gh pr create" "$OVERRIDE_FILE")" \
  "(h): PR creation via gh pr create named as authorized"
assert_equals "yes" "$(grep_has "human-only" "$OVERRIDE_FILE")" \
  "(h): human-only actions named"
assert_equals "yes" "$(grep_count "main" "$OVERRIDE_FILE" | grep -q "^0$" && echo no || echo yes)" \
  "(h): commits to main addressed in the wording"

cd "$SCRIPT_DIR"
print_summary
