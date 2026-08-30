---
title: "Risk Register - five-phase-planifest-zero"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.2.0"
---
# Risk Register - five-phase-planifest-zero

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000031-five-phase-planifest-zero
**Version:** 0.2.0
**Overall Risk Level:** medium

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | A missed rename reference breaks a script, hook import, or test after the folder move | high | low | grep-sweep acceptance criterion plus `run-tests.sh` catch every live path; historical records are excluded deliberately | open |
| R-002 | technical | The telemetry backend rejects the five new phase enum values | medium | low | CI telemetry job extends to all five names and fails loudly; runtime failures surface via the marker protocol | open |
| R-003 | operational | The docs rewrite drops a fact still needed operationally | medium | medium | present-state audit at validate-and-accept; git history retains everything removed | open |
| R-004 | operational | This run rewrites the pipeline that governs its own resume | low | medium | granular commits; `plan/current/` formats held stable; the installed `.claude/` tree is insulated until setup re-runs | open |
| R-005 | technical | Merging nine skills into five loses a binding rule (a hard limit, gate, or protocol) in the compression | medium | medium | the plan phase maps every current skill section to its destination before implement begins; validate-and-accept checks the map | open |
| R-006 | technical | setup script pruning deletes user content in `.claude/` beyond retired skills | low | high | pruning is scoped to known retired skill folder names only, verified in the temp-clone execution test | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Telemetry backend tolerates unknown phase values or is updated separately | CI job red until the backend updates; no data corruption | open |
| A-002 | `context-pressure.mjs` is genuinely telemetry, separable from context-mode | It is deleted with wiring and test per req-005's both-outcomes rule | open |
| A-003 | `plan/current/` artifact formats stay stable for the rest of this run | Resume by the old installed orchestrator fails; recovery from git | open |
