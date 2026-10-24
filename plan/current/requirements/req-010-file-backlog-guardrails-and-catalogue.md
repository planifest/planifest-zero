---
title: "Requirement: REQ-010 - file-backlog-guardrails-and-catalogue"
summary: "The file-backlog skill states its git guardrails, and the catalogue and skill-count suites list it."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-010 - file-backlog-guardrails-and-catalogue

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-005
**Priority:** must-have

## User Story

As a human, I ask the agent to file a backlog entry in another repo, and it writes one uncommitted entry folder, so that the repo's git state stays untouched. (Backlog 0000163)

## Functional Requirements
- The skill never commits, pushes, switches branches, stashes, or opens a pull request in the target repo.
- Register the skill in `ravintio-zero/skills/ravintio-orchestrator/references/orchestrator-skills-catalogue.md` under "Standalone and Subagent Skills". The row gives the trigger (the human asks to file a backlog entry in another repo) and the relationship (standalone, invoke any time). Setup copies that file into the installed `.claude/skills/ravintio-orchestrator/references/` copy.
- Tests that enumerate the skill set change from 12 to 13 skills:
  - `ravintio-zero/tests/test-0000031-req-004-setup-execution.sh` asserts "exactly 12 skills installed" twice.
  - `ravintio-zero/tests/test-0000031-req-003-five-phases.sh` names 12 skills in its header and loop. Add `ravintio-file-backlog`.
- A structure test asserts the never-commit rule, naming commit, push, branch switch, stash, and pull request.
- Assert the catalogue holds a row for the skill.

## Acceptance Criteria
- [ ] The skill text states that it never commits, pushes, switches branches, stashes, or opens a pull request in the target repo, and that it reports the path written. A structure test asserts the rule.
- [ ] The skills catalogue lists `ravintio-file-backlog`, and the skill-count suites expect 13 skills and pass.

## Dependencies
- REQ-005 (file-backlog-skill) creates the skill that this requirement registers and constrains.
