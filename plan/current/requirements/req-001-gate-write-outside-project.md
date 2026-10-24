---
title: "Requirement: REQ-001 - gate-write-outside-project"
summary: "gate-write passes any target whose real path is outside the project root."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - gate-write-outside-project

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-001 (backlog 0000162)
**Priority:** must-have

## User Story

As an agent, I write files outside the project without a design, so that hooks gate only this project.

## Functional Requirements
- Today `gate-write.mjs` resolves the target against `cwd` and compares normalised strings. A target outside `cwd` keeps its raw path as `relTarget`. It then fails Check 2 or Check 3 and exits 2.
- `gate-write.mjs` resolves `cwd` and the target to real paths with `realpathSync`.
- If the target does not exist yet, the hook resolves the nearest existing parent and rejoins the remaining segments.
- If the real target path is outside the real project root, the hook exits 0 before Check 0.
- If the real target path is inside the real project root, Checks 0 to 3 run as they do today.
- The hook adds no process or network call.

## Acceptance Criteria
- [ ] A target outside the project exits 0 when `plan/current/design.md` exists and when it does not.
- [ ] An in-project target outside the declared component paths still exits 2, and `plan/current/` writes still need the sentinel.
- [ ] A write through an in-project symlink whose real path is inside the project still gets the checks.

## Dependencies
- None. REQ-002 documents the behaviour this requirement sets.
- REQ-006 covers the symlink and Windows cases of this rule.
