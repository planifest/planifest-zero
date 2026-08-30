#!/usr/bin/env bash
# Telemetry wiring across the phase skills. Each phase skill points at
# telemetry-standards.md and names its phase value. Event ownership lives in
# the standards owner table, not repeated per skill.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" && pwd)"
STANDARDS="$(cd "$SCRIPT_DIR/../standards" && pwd)/telemetry-standards.md"
source "$SCRIPT_DIR/helpers/assert.sh"

declare -A PHASE_OF=(
  [planifest-orchestrator]="discovery"
  [planifest-plan]="plan"
  [planifest-implement]="implement"
  [planifest-validate-and-accept]="validate-and-accept"
  [planifest-ship]="ship"
)

for skill in planifest-orchestrator planifest-plan planifest-implement planifest-validate-and-accept planifest-ship; do
  echo ""
  echo "=== $skill ==="
  file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    assert_equals "present" "missing" "$skill: SKILL.md exists"
    continue
  fi
  content=$(cat "$file")
  assert_contains "## Telemetry" "$content" "$skill: has ## Telemetry section"
  assert_contains "telemetry-standards.md" "$content" "$skill: points at telemetry-standards.md"
  assert_contains "${PHASE_OF[$skill]}" "$content" "$skill: names its phase value"
done

echo ""
echo "=== standards: mandatory gate and interactive failure protocol ==="
STD=$(cat "$STANDARDS")
assert_contains "mandatory, not best-effort" "$STD" "standards: emission is mandatory when the signal is active"
assert_contains "lock until resolved" "$STD" "standards: interactive block-or-proceed protocol"
assert_contains "phase_start" "$STD" "standards: phase_start documented"
assert_contains "phase_end" "$STD" "standards: phase_end documented"

echo ""
echo "=== standards: event ownership table ==="
own() { # event, owner-fragment
  LINE=$(grep "\`$1\`" "$STANDARDS" | head -1)
  assert_contains "$2" "$LINE" "standards: $1 owned by $2"
}
own phase_skip planifest-orchestrator
own spec_gap planifest-orchestrator
own mcp_impact planifest-orchestrator
own adr_decision planifest-plan
own deviation planifest-implement
own migration_proposal planifest-implement
own doc_gap planifest-implement
own validation_failure planifest-validate-and-accept
own self_correction planifest-validate-and-accept
own security_finding planifest-validate-and-accept
own retry_limit_exceeded "any phase skill"

print_summary
