#!/usr/bin/env bash
# test-0000010-framework-quality-improvements.sh
# Acceptance tests for feature 0000010
# Run from repo root: bash planifest-framework/tests/test-0000010-framework-quality-improvements.sh

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

TEMPLATE="planifest-framework/templates/requirement.template.md"
ORCH="planifest-framework/skills/planifest-orchestrator/SKILL.md"
CODEGEN="planifest-framework/skills/planifest-codegen-agent/SKILL.md"
VALIDATE="planifest-framework/skills/planifest-validate-agent/SKILL.md"
SETUP_SH="planifest-framework/setup.sh"
SETUP_PS1="planifest-framework/setup.ps1"

echo ""
echo "=== REQ-001: Input Validation section in requirement.template.md ==="
if grep -q "## Input Validation" "$TEMPLATE"; then
  pass "REQ-001: template contains ## Input Validation section"
else
  fail "REQ-001: template missing ## Input Validation section"
fi

if grep -q "conditional\|only required\|only include" "$TEMPLATE"; then
  pass "REQ-001: template marks Input Validation as conditional"
else
  fail "REQ-001: template does not mark Input Validation as conditional"
fi

if grep -q "allowed character\|allowed chars\|character set\|\[a-z\]\|pattern" "$TEMPLATE"; then
  pass "REQ-001: template contains allowed character pattern placeholder"
else
  fail "REQ-001: template missing allowed character pattern placeholder"
fi

if grep -q "max.*length\|maximum.*length\|max.*chars\|length.*max" "$TEMPLATE"; then
  pass "REQ-001: template contains max length placeholder"
else
  fail "REQ-001: template missing max length placeholder"
fi

if grep -q "failure.*behav\|on.*failure\|fallback\|default.*value" "$TEMPLATE"; then
  pass "REQ-001: template contains failure behaviour placeholder"
else
  fail "REQ-001: template missing failure behaviour placeholder"
fi

existing_sections=$(grep -c "^## " "$TEMPLATE" 2>/dev/null || echo 0)
if grep -q "^## Functional Requirements" "$TEMPLATE" && grep -q "^## Acceptance Criteria" "$TEMPLATE"; then
  pass "REQ-001: existing Functional Requirements and Acceptance Criteria sections unchanged"
else
  fail "REQ-001: existing required sections missing or renamed"
fi

echo ""
echo "=== REQ-002: Agent tool in setup.sh ==="
if grep -q "Agent\|allowedTools" "$SETUP_SH"; then
  pass "REQ-002: setup.sh references Agent/allowedTools"
else
  fail "REQ-002: setup.sh does not reference Agent or allowedTools"
fi

if grep -q '"Agent"' "$SETUP_SH"; then
  pass "REQ-002: setup.sh contains \"Agent\" string for allowedTools"
else
  fail "REQ-002: setup.sh missing \"Agent\" in allowedTools"
fi

echo ""
echo "=== REQ-002: Agent tool in setup.ps1 ==="
if grep -q '"Agent"\|allowedTools' "$SETUP_PS1"; then
  pass "REQ-002: setup.ps1 references Agent allowedTools"
else
  fail "REQ-002: setup.ps1 does not reference Agent allowedTools"
fi

echo ""
echo "=== REQ-002: Agent dispatch template in orchestrator SKILL.md ==="
if grep -q "Agent Dispatch Template\|## Agent Dispatch" "$ORCH"; then
  pass "REQ-002: orchestrator has Agent Dispatch Template section"
else
  fail "REQ-002: orchestrator missing Agent Dispatch Template section"
fi

if grep -q "self-contained\|self.contained" "$ORCH"; then
  pass "REQ-002: orchestrator dispatch template includes self-contained prompt rule"
else
  fail "REQ-002: orchestrator missing self-contained prompt rule"
fi

# 0000022: relocated to standards/agent-dispatch-standards.md (ADR-001) - orchestrator points to it
DISPATCH_STD_FILE="planifest-framework/standards/agent-dispatch-standards.md"
if [ -f "$DISPATCH_STD_FILE" ] && grep -q "native tool\|two levels\|parallel native" "$DISPATCH_STD_FILE"; then
  pass "REQ-002: agent-dispatch-standards.md clarifies two levels of parallelism"
else
  fail "REQ-002: agent-dispatch-standards.md missing two-levels-of-parallelism note"
fi

echo ""
echo "=== REQ-002: Parallel Dispatch Checklist in codegen-agent SKILL.md ==="
if grep -q "Parallel Dispatch Checklist\|## Parallel Dispatch" "$CODEGEN"; then
  pass "REQ-002: codegen-agent has Parallel Dispatch Checklist section"
else
  fail "REQ-002: codegen-agent missing Parallel Dispatch Checklist section"
fi

echo ""
echo "=== REQ-002: Pre-Execution Parallelism Plan in validate-agent SKILL.md ==="
if grep -q "Pre-Execution Parallelism\|## Pre-Execution" "$VALIDATE"; then
  pass "REQ-002: validate-agent has Pre-Execution Parallelism Plan section"
else
  fail "REQ-002: validate-agent missing Pre-Execution Parallelism Plan section"
fi

echo ""
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAIL test(s) failed."
  exit 1
fi
