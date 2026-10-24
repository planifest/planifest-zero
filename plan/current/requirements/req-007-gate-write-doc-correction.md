---
title: "Requirement: REQ-007 - gate-write-doc-correction"
summary: "CLAUDE.md and three other files describe the full gate-write scope."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-007 - gate-write-doc-correction

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-002 (backlog 0000162)
**Priority:** must-have

## User Story

As a maintainer, I read in `CLAUDE.md` and the hook which paths it gates, including `plan/backlog/` and `plan/roadmap/` between runs, so that docs match behaviour.

## Functional Requirements
- The `gate-write` bullet in `CLAUDE.md` says the hook gates every in-project path that is not always permitted. It also states the `plan/current/` sentinel check and that targets outside the project pass.
- The same correction applies to each other file that describes `gate-write` as blocking only `src/`:
  - `ravintio-zero/templates/standard-boot.md`, which setup copies into consumer `CLAUDE.md` files.
  - `ravintio-zero/pipeline-reference.md`, in the hooks table and the section "How gate-write interacts with design.md".
  - `ravintio-zero/project-operations.md`, in the hooks table.

## Acceptance Criteria
- [ ] The `gate-write` bullet in `CLAUDE.md` no longer says it "Blocks writes to `src/`". It states the gated paths, the sentinel check, and that outside targets pass.
- [ ] `standard-boot.md`, `pipeline-reference.md`, and `project-operations.md` carry the same description.

## Dependencies
- REQ-002 (gate-write-documented-scope) names the allowed paths.
- REQ-001 sets the outside-project behaviour that these docs describe.
