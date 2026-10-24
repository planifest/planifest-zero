---
title: "Requirement: REQ-008 - bash32-guard-test"
summary: "A guard test blocks the Bash 3.2 loop pattern and the full suite passes on both shells."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-008 - bash32-guard-test

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-003 (backlog 0000161)
**Priority:** must-have

## User Story

As a maintainer on macOS, I get the same suite results as CI, so that a local pass is a real pass.

## Functional Requirements
- A guard test under `ravintio-zero/tests/` fails when any file under `tests/` contains `done < <(`. The guard excludes its own file.
- The full suite runs on Bash 3.2 under `env -i` and on Bash 5 in CI.

## Acceptance Criteria
- [ ] The guard test exits non-zero when a temporary file under `tests/` contains `done < <(`, and exits 0 otherwise.
- [ ] The full suite passes on Bash 3.2 (`env -i` run) and on Bash 5 in CI.

## Dependencies
- REQ-003 (bash32-test-loops) converts the five loops that the guard then protects.
