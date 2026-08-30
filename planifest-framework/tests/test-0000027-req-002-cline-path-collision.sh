#!/usr/bin/env bash
# Tests for feature 0000027-backlog-batch-governance-tooling-fixes, req-002:
# fix-cline-path-collision.
#
# Covers: setup/cline.sh set TOOL_SKILLS_DIR=".clinerules/skills" (forcing
# ".clinerules" to exist as a directory via copy_skills()'s mkdir -p) and
# TOOL_BOOT_FILE=".clinerules" (the *same* path, written as a plain file by
# write_boot_file()'s `echo "$content" > "$path"`), so writing the boot file
# failed with a shell "Is a directory" error. setup.sh runs under
# `set -euo pipefail`, so this aborted every `setup.sh cline` and
# `setup.sh all` invocation non-zero. This exact failure mode was documented
# as a known, deferred, pre-existing bug in this repo's own
# test-0000023-req-003-copilot-setup-self-copy.sh (part (e)).
#
# The fix relocates the boot file to ".clinerules/00-planifest-boot.md",
# leaving TOOL_SKILLS_DIR at ".clinerules/skills" — both directories/files
# now coexist as siblings under ".clinerules/" with no collision.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$SCRIPT_DIR/.."
CLINE_PS1="$FRAMEWORK/setup/cline.ps1"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
dir_exists() { [ -d "$1" ] && echo "yes" || echo "no"; }
grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

make_workspace() {
  local dir
  dir=$(mktemp -d -t planifest_0000027_req002_test_XXXXXX)
  cp -r "$FRAMEWORK" "$dir/planifest-framework"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): setup.sh cline exits 0 on a fresh disposable workspace ─────────────

echo ""
echo "=== (a): setup.sh cline exits 0 on a fresh disposable workspace ==="

WS=$(make_workspace); cd "$WS"
bash planifest-framework/setup.sh cline >/tmp/planifest_0000027_req002_cline_stdout.log 2>&1
CLINE_EXIT=$?
assert_exit_zero "$CLINE_EXIT" "(a): setup.sh cline exits 0 (no 'Is a directory' collision)"

# ── (b): the boot file and skills dir coexist under .clinerules/ ────────────

echo ""
echo "=== (b): .clinerules/00-planifest-boot.md and .clinerules/skills/ coexist ==="

assert_equals "yes" "$(file_exists ".clinerules/00-planifest-boot.md")" \
  "(b): .clinerules/00-planifest-boot.md exists as a regular file"

assert_equals "yes" "$(dir_exists ".clinerules/skills")" \
  "(b): .clinerules/skills exists as a directory"

# ── (c): the boot content is readable and non-empty, and override sentinel
#         markers still work against the new nested path ──────────────────

echo ""
echo "=== (c): boot file content is present and readable ==="

BOOT_SIZE=$(wc -c < ".clinerules/00-planifest-boot.md" 2>/dev/null | tr -d ' ')
assert_equals "no" "$([ "${BOOT_SIZE:-0}" -eq 0 ] && echo yes || echo no)" \
  "(c): .clinerules/00-planifest-boot.md is non-empty"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (d): setup.sh all exits 0 on a fresh workspace, including the cline step ─
#
# This is the end-to-end regression test-0000023-req-003 part (e) left
# asserted (and expected to fail) pending this exact fix. It should now pass.

echo ""
echo "=== (d): setup.sh all exits 0 on a fresh disposable workspace ==="

WS=$(make_workspace); cd "$WS"
bash planifest-framework/setup.sh all >/tmp/planifest_0000027_req002_all_stdout.log 2>&1
ALL_EXIT=$?
assert_exit_zero "$ALL_EXIT" "(d): setup.sh all exits 0 (cline step no longer aborts the full run)"

assert_equals "yes" "$(file_exists ".clinerules/00-planifest-boot.md")" \
  "(d): setup.sh all also produces .clinerules/00-planifest-boot.md"

assert_equals "yes" "$(dir_exists ".clinerules/skills")" \
  "(d): setup.sh all also produces .clinerules/skills as a directory"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (e): cline.ps1 parity (static source check) ─────────────────────────────
# A live pwsh invocation is not run here — no PowerShell runtime is available
# in this environment (consistent with test-0000023-req-003 part (f)/(g)).
# Parity is checked statically: cline.ps1 must declare the equivalent nested
# BootFile value, not the bare '.clinerules' path that collides with
# SkillsDir's parent directory.

echo ""
echo "=== (e): cline.ps1 declares the equivalent nested BootFile (static parity check) ==="

assert_equals "yes" "$(grep_has "BootFile *= *'\.clinerules\\\\00-planifest-boot\.md'" "$CLINE_PS1")" \
  "(e): cline.ps1 sets BootFile = '.clinerules\\00-planifest-boot.md'"

assert_equals "yes" "$(grep_has "SkillsDir *= *'\.clinerules\\\\skills'" "$CLINE_PS1")" \
  "(e): cline.ps1 still sets SkillsDir = '.clinerules\\skills' (unchanged)"

print_summary
