---
title: "Requirement: req-008 - test-suite-cleanup"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - test-suite-cleanup

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want the test suite cleaned of telemetry assertions, so that the runner proves the framework works with no telemetry present, and no test masks a real regression.

## Functional Requirements
- Edit the 19 mixed test suites under `tests/` to drop their telemetry assertions while keeping every other assertion in the same file.
- Remove the five telemetry entries from `tests/regression/regression-manifest.json`, keeping the file valid JSON despite its "do not edit manually" notice.
- Confirm the two suites already failing on `main` because `planifest-framework/` exists (backlog 0000086) still fail for that same pre-existing reason, not because of this cleanup.

## Acceptance Criteria
- [ ] `planifest-zero/tests/run-tests.sh` (or the project's equivalent runner) exits 0 with no telemetry suite listed in its output.
- [ ] `grep -ril telemetry planifest-zero/tests/` returns no matches, and `tests/regression/regression-manifest.json` parses as valid JSON with `grep -c telemetry tests/regression/regression-manifest.json` returning 0.
- [ ] The two suites tracked by backlog 0000086 fail with the same error signature before and after this change, confirmed by comparing their output to a pre-change baseline capture.

## Dependencies
- req-001 through req-006 (test cleanup verifies the deletions and edits those requirements make).
