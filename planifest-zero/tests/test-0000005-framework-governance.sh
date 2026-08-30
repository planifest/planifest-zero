#!/usr/bin/env bash
# Tests for feature 0000005-framework-governance
# Covers: req-001 through req-016
# Amended for the 0000030 framework cut-down. Retired agent skills
# (codegen-agent, validate-agent, change-agent) are gone, so the wiring
# assertions now point at the surviving phase skills that carry the
# same rules (planifest-plan, planifest-implement,
# planifest-validate-and-accept).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
STANDARDS="$FRAMEWORK/standards"
SKILLS="$FRAMEWORK/skills"
MIGRATIONS="$FRAMEWORK/migrations"

# -----------------------------------------------------------------------

echo ""
echo "=== req-001: library standards directory tree ==="

assert_file_exists() {
  local path="$1" label="$2"
  if [ -e "$path" ]; then
    assert_equals "0" "0" "$label"
  else
    assert_equals "exists" "missing" "$label: $path"
  fi
}

assert_file_exists "$STANDARDS/library-standards/_version-policy.md"       "req-001: _version-policy.md exists"
assert_file_exists "$STANDARDS/library-standards/typescript/prefer-avoid.md" "req-001: typescript/prefer-avoid.md"
assert_file_exists "$STANDARDS/library-standards/typescript/test-frameworks.md" "req-001: typescript/test-frameworks.md"
assert_file_exists "$STANDARDS/library-standards/python/prefer-avoid.md"    "req-001: python/prefer-avoid.md"
assert_file_exists "$STANDARDS/library-standards/go/prefer-avoid.md"        "req-001: go/prefer-avoid.md"
assert_file_exists "$STANDARDS/library-standards/java/prefer-avoid.md"      "req-001: java/prefer-avoid.md"

# -----------------------------------------------------------------------

echo ""
echo "=== req-002: database standards ==="

assert_file_exists "$STANDARDS/library-standards/databases/prefer-avoid.md" "req-002: databases/prefer-avoid.md"
DB=$(cat "$STANDARDS/library-standards/databases/prefer-avoid.md")
assert_contains "PostgreSQL" "$DB" "req-002: covers PostgreSQL"
assert_contains "Redis"      "$DB" "req-002: covers Redis"

# -----------------------------------------------------------------------

echo ""
echo "=== req-003: test framework coverage ==="

assert_file_exists "$STANDARDS/library-standards/typescript/test-frameworks.md" "req-003: typescript test-frameworks.md"
assert_file_exists "$STANDARDS/library-standards/python/test-frameworks.md"     "req-003: python test-frameworks.md"
assert_file_exists "$STANDARDS/library-standards/go/test-frameworks.md"         "req-003: go test-frameworks.md"

# -----------------------------------------------------------------------

echo ""
echo "=== req-004: implement-phase library-standards wiring ==="

# 0000030: codegen-agent is retired. Its library-standards wiring now
# lives in planifest-implement. formatting-standards.md moved to the
# planifest-plan bundle.
IMPLEMENT=$(cat "$SKILLS/planifest-implement/SKILL.md")
PLAN=$(cat "$SKILLS/planifest-plan/SKILL.md")
assert_contains "formatting-standards.md"       "$PLAN" "req-004: formatting-standards.md in planifest-plan bundle_standards"
assert_contains "library-standards/_version-policy.md" "$IMPLEMENT" "req-004: _version-policy.md in planifest-implement bundle_standards"
assert_contains "prefer-avoid.md"                "$IMPLEMENT" "req-004: library audit references prefer-avoid.md"
assert_contains "planifest-overrides/library-standards" "$IMPLEMENT" "req-004: references planifest-overrides path"

# -----------------------------------------------------------------------

echo ""
echo "=== req-005: validate-and-accept library audit wiring ==="

# 0000030: validate-agent is retired. The library audit now lives in
# planifest-validate-and-accept. _version-policy.md is bundled by
# planifest-implement rather than the validate phase.
VALIDATE=$(cat "$SKILLS/planifest-validate-and-accept/SKILL.md")
assert_contains "formatting-standards.md"       "$VALIDATE" "req-005: formatting-standards.md in bundle_standards"
assert_contains "library-standards/_version-policy.md" "$IMPLEMENT" "req-005: _version-policy.md bundled by planifest-implement"
assert_contains "Library audit"                 "$VALIDATE" "req-005: Library audit step present"
assert_contains "avoided library"               "$VALIDATE" "req-005: avoided library check present"

# -----------------------------------------------------------------------

echo ""
echo "=== req-006: pipeline standards wiring ==="

# 0000030: the orchestrator no longer bundles these standards. The
# underlying rule, that both standards are wired into the pipeline,
# now lives in the phase skills. planifest-plan bundles
# formatting-standards.md and planifest-implement bundles
# library-standards/_version-policy.md.
ORCH=$(cat "$SKILLS/planifest-orchestrator/SKILL.md")
assert_contains "formatting-standards.md"       "$PLAN" "req-006: formatting-standards.md in planifest-plan bundle_standards"
assert_contains "library-standards/_version-policy.md" "$IMPLEMENT" "req-006: _version-policy.md in planifest-implement bundle_standards"

# -----------------------------------------------------------------------

echo ""
echo "=== req-007: orchestrator sentinel ==="

GATE=$(cat "$FRAMEWORK/hooks/enforcement/gate-write.mjs")
assert_contains "orchestrator-active"           "$GATE" "req-007: sentinel path in gate-write"
assert_contains "plan/current/"                 "$GATE" "req-007: plan/current guard present"

CHECK=$(cat "$FRAMEWORK/hooks/enforcement/check-design.mjs")
assert_contains "orchestrator-active"           "$CHECK" "req-007: sentinel path in check-design"
assert_contains "feature-brief"                 "$CHECK" "req-007: feature-brief check present"

# -----------------------------------------------------------------------

echo ""
echo "=== req-008: check-design hard-stop injection ==="

assert_contains "STOP"                          "$CHECK" "req-008: STOP message present"
assert_contains "additionalContext"             "$CHECK" "req-008: additionalContext output"

# -----------------------------------------------------------------------

echo ""
echo "=== req-010: capability skill intake ==="

assert_contains "skills-inbox"                  "$ORCH" "req-010: skills-inbox referenced in orchestrator"
assert_contains "capability-skills"             "$ORCH" "req-010: capability-skills referenced"
assert_file_exists "$FRAMEWORK/skills-inbox/.gitkeep" "req-010: skills-inbox directory exists"

# -----------------------------------------------------------------------

echo ""
echo "=== req-011: skill registries ==="

assert_file_exists "$FRAMEWORK/../planifest-overrides/capability-skills/.gitkeep" "req-011: planifest-overrides/capability-skills/ exists"
assert_contains "Copy-CapabilitySkills"          "$(cat "$FRAMEWORK/setup.ps1")" "req-011: setup.ps1 has Copy-CapabilitySkills"
assert_contains "capability-skills"              "$(cat "$FRAMEWORK/setup.ps1")" "req-011: setup.ps1 copies from capability-skills"

# -----------------------------------------------------------------------

echo ""
echo "=== req-012: Active Skills in execution-plan template ==="

EXEC_TPL=$(cat "$FRAMEWORK/templates/execution-plan.template.md")
assert_contains "Active Skills"                 "$EXEC_TPL" "req-012: execution-plan template has Active Skills section"

# -----------------------------------------------------------------------

echo ""
echo "=== req-013: formatting standards ==="

assert_file_exists "$STANDARDS/formatting-standards.md"      "req-013: formatting-standards.md exists"
FMT=$(cat "$STANDARDS/formatting-standards.md")
assert_contains "DD MMM YYYY"                   "$FMT" "req-013: DD MMM YYYY date format"
assert_contains "British English"               "$FMT" "req-013: British English locale"
assert_contains "Verbosity"                     "$FMT" "req-013: verbosity standard"

# -----------------------------------------------------------------------

echo ""
echo "=== req-014: migration infrastructure ==="

assert_file_exists "$MIGRATIONS/_done/0001-date-format.md"   "req-014: 0001-date-format.md"
assert_file_exists "$MIGRATIONS/_done/0002-british-english.md" "req-014: 0002-british-english.md"
assert_file_exists "$MIGRATIONS/_done/.gitkeep"              "req-014: _done/ archive dir"
assert_file_exists "$SKILLS/planifest-migrator/SKILL.md"     "req-014: planifest-migrator skill"
MIGRATOR=$(cat "$SKILLS/planifest-migrator/SKILL.md")
assert_contains "batch"                         "$MIGRATOR" "req-014: migrator uses batched presentation"
assert_contains "_done"                         "$MIGRATOR" "req-014: migrator archives to _done/"

# -----------------------------------------------------------------------

echo ""
echo "=== req-015: British English rewrite ==="

TESTING=$(cat "$STANDARDS/testing-standards.md")
assert_contains "behaviour"                     "$TESTING" "req-015: behaviour (British) in testing-standards"

# 0000030: change-agent is retired. Check a surviving skill that uses
# British English instead.
assert_contains "behaviour"                     "$VALIDATE" "req-015: behaviour (British) in planifest-validate-and-accept"

# -----------------------------------------------------------------------

echo ""
echo "=== req-016: planifest-overrides directory ==="

# setup.sh must not contain mkdir/cp commands targeting planifest-overrides/
UNSAFE_WRITES=$(grep -E "(mkdir|cp )[^#]*planifest-overrides" "$FRAMEWORK/setup.sh" || true)
if [ -z "$UNSAFE_WRITES" ]; then
  assert_equals "0" "0" "req-016: setup.sh does not write to planifest-overrides/"
else
  assert_equals "no writes" "$UNSAFE_WRITES" "req-016: setup.sh does not write to planifest-overrides/"
fi

assert_contains "planifest-overrides"           "$(cat "$FRAMEWORK/setup.ps1")" "req-016: setup.ps1 reads planifest-overrides"
assert_file_exists "$FRAMEWORK/../planifest-overrides/library-standards/.gitkeep" "req-016: planifest-overrides scaffolded"

# -----------------------------------------------------------------------

print_summary
