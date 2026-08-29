#!/usr/bin/env bash
# Content-pinning tests for the 4 doc/workflow-only requirements in feature
# 0000027 that have no runtime behaviour to execute: req-003 (subagent
# backlog filing), req-005 (framework update policy), req-007 (skill-scope
# ADR pointer), req-008 (minimal Phase 1 artifact set). Follows this repo's
# established convention (see test-skill-telemetry.sh) of asserting exact
# required content exists rather than executing prose.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "=== req-003: subagent out-of-scope discoveries file to plan/backlog/ ==="

DISPATCH_STANDARDS="$FRAMEWORK_DIR/standards/agent-dispatch-standards.md"
content=$(cat "$DISPATCH_STANDARDS")
assert_contains "0000027-req-003" "$content" "req-003: agent-dispatch-standards.md references req-003"
assert_contains "plan/backlog/{id}-{slug}/entry.md" "$content" "req-003: dispatch template instructs filing to plan/backlog/"
assert_contains "pre-computes the next available backlog ID" "$content" "req-003: dispatching agent pre-computes the backlog ID"
assert_contains "Subagent self-lookup" "$content" "req-003: subagent self-lookup explicitly rejected"

for skill in planifest-codegen-agent planifest-spec-agent planifest-validate-agent planifest-security-agent planifest-docs-agent; do
  skill_content=$(cat "$FRAMEWORK_DIR/skills/$skill/SKILL.md")
  assert_contains "backlog" "$skill_content" "req-003: $skill references backlog-filing guidance"
done

echo ""
echo "=== req-005: explicit P0 flow for a planifest-zero/ dependency update ==="

ORCHESTRATOR_SKILL="$FRAMEWORK_DIR/skills/planifest-orchestrator/SKILL.md"
orch_content=$(cat "$ORCHESTRATOR_SKILL")
assert_contains "1a. **Detect a" "$orch_content" "req-005: orchestrator has a distinct P0 Start Actions step for framework updates"
assert_contains "framework-update-policy.md" "$orch_content" "req-005: orchestrator points to the Framework Update Policy doc"

assert_equals "yes" "$([ -f "$FRAMEWORK_DIR/standards/framework-update-policy.md" ] && echo yes || echo no)" \
  "req-005: standards/framework-update-policy.md exists"

if [ -f "$FRAMEWORK_DIR/standards/framework-update-policy.md" ]; then
  policy_content=$(cat "$FRAMEWORK_DIR/standards/framework-update-policy.md")
  assert_contains "provenance" "$policy_content" "req-005: Framework Update Policy requires provenance confirmation"
fi

echo ""
echo "=== req-007: skill-scope ADR referenced from the process that adds a skill ==="

assert_contains "0000027-ADR-003" "$orch_content" "req-007: orchestrator references ADR-003 by ID"
assert_contains "skill-scope test" "$orch_content" "req-007: orchestrator names the skill-scope test"

# 0000030 emptied plan/_archive/, so the ADR-003 file assertion has no artifact
# left to find. The skill-scope principle itself survives as a referenced rule
# in the orchestrator, which is what the requirement actually protects.

echo ""
echo "=== req-008: minimal Phase 1 artifact set agrees between workflow and spec-agent ==="

PIPELINE_WORKFLOW="$FRAMEWORK_DIR/workflows/feature-pipeline.md"
pipeline_content=$(cat "$PIPELINE_WORKFLOW")
assert_contains "minimal default Phase 1 artifact set" "$pipeline_content" "req-008: feature-pipeline.md names the minimal default set"
assert_contains "execution plan, functional requirements" "$pipeline_content" "req-008: feature-pipeline.md's always-produced list starts with execution plan + requirements"
assert_contains "OpenAPI Specification — the component acts as an API provider" "$pipeline_content" "req-008: feature-pipeline.md states OpenAPI's trigger condition"
assert_contains "Operational Model — the feature introduces or modifies a deployed runtime service" "$pipeline_content" "req-008: feature-pipeline.md states Operational Model's trigger condition"

spec_agent_content=$(cat "$FRAMEWORK_DIR/skills/planifest-spec-agent/SKILL.md")
assert_contains "produced when the component acts as an API provider" "$spec_agent_content" "req-008: planifest-spec-agent states OpenAPI's trigger condition"
assert_contains "produced when the feature introduces or modifies a deployed runtime service" "$spec_agent_content" "req-008: planifest-spec-agent states Operational Model/SLO trigger condition"
assert_contains "ADR-004" "$spec_agent_content" "req-008: planifest-spec-agent references ADR-004"

README_CONTENT=$(cat "$SCRIPT_DIR/../../README.md")
assert_contains "five Phase 1 artifacts" "$README_CONTENT" "req-008: README states the default artifact count"

docs_agent_content=$(cat "$FRAMEWORK_DIR/skills/planifest-docs-agent/SKILL.md")
assert_contains "0000027-ADR-004" "$docs_agent_content" "req-008: planifest-docs-agent's completeness check references ADR-004's conditional set"

print_summary
