---
title: "Requirement: req-005 - telemetry-only-mcp"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-005 - telemetry-only-mcp

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-005
**Priority:** must-have

## User Story
As the maintainer, I keep the telemetry MCP integration and remove every remaining trace of context-mode, so that one MCP concern remains.

## Functional Requirements
- Keep the whole `hooks/telemetry/` family: `emit-event.mjs`, `emit-phase-start.mjs`, `emit-phase-end.mjs`, `resolve-phase.mjs`, `emit-event-receipt.mjs`, `record-telemetry-failure.mjs`, `read-product-id.mjs`, and `get-flag-path.mjs`.
- Keep the `--structured-telemetry-mcp` setup flag, `standards/telemetry-standards.md`, the failure-marker protocol, and the CI telemetry schema job.
- Investigate `hooks/telemetry/context-pressure.mjs` to determine what it does, since it shares only a name prefix with the removed context-mode feature and was ruled unrelated during feature 0000030.
  - If the file emits a genuine context-pressure telemetry event and contains no context-mode logic, keep it and confirm it carries no context-mode references.
  - If the file exists only to serve the removed context-mode feature, delete it along with its wiring in the `.claude/settings.json` template inside the setup scripts and its test, `tests/test-context-pressure.sh`.
- Remove guard assertions that keep the term "context-mode" alive in the tree, including the zero-occurrence grep assertion in `tests/test-0000029-req-001-003-boot-file-regeneration.sh`. Delete the assertion or the whole guard test, whichever leaves the suite coherent.
- Remove any remaining doc or standards mentions of "context-mode" outside change records (`plan/_archive/`, `plan/changelog/`, and git history are exempt).
- Leave the telemetry phase enum change out of scope. That change belongs to req-003.

## Acceptance Criteria
- [ ] `grep -ri "context-mode"` over the repository, excluding `plan/_archive/`, `plan/changelog/`, and `.git`, returns zero hits.
- [ ] The decision on `context-pressure.mjs` is recorded and acted on: either kept with confirmed telemetry-only content, or deleted with its setup wiring and test removed.
- [ ] Telemetry hooks remain installed and fire under the `--structured-telemetry-mcp` flag, verified in the req-004 temp-clone run.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- req-004 (setup-and-overrides): provides the temp-clone run used to verify telemetry hooks still fire.
- Feature 0000030: removed context-mode's hooks, flag, docs, and components; this requirement finishes that removal.
