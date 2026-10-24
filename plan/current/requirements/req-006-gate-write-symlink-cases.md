---
title: "Requirement: REQ-006 - gate-write-symlink-cases"
summary: "The outside-project rule holds for symlinks, path aliases, and Windows path forms."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-006 - gate-write-symlink-cases

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-001 (backlog 0000162)
**Priority:** must-have

## User Story

As an agent, I write files outside the project without a design, so that hooks gate only this project.

## Functional Requirements
- Resolving both paths the same way handles an in-project symlink that points outside and the macOS `/private/tmp` and `/tmp` aliasing.

## Acceptance Criteria
- [ ] A write through an in-project symlink whose real path is outside the project exits 0.
- [ ] A target path outside the project whose real path is inside the project, through a symlink, still gets the checks.
- [ ] `ravintio-zero/tests/test-gate-write-windows.mjs` and `ravintio-zero/tests/test-gate-write-windows.sh` still pass, so Windows path forms work.

## Dependencies
- REQ-001 (gate-write-outside-project) sets the core rule that these cases extend.
