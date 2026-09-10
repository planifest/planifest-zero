---
title: "Requirement: req-001 - delete-telemetry-only-files"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - delete-telemetry-only-files

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want the 34 telemetry-only files deleted, so that no dead telemetry code remains in the repository.

## Functional Requirements
- Delete `hooks/telemetry/` and its nine modules: `emit-event`, `emit-phase-start`, `emit-phase-end`, `emit-event-receipt`, `context-pressure`, `resolve-phase`, `record-telemetry-failure`, `read-product-id`, and `get-flag-path`.
- Delete `hooks/enforcement/check-telemetry-failures.mjs`, `hooks/enforcement/check-telemetry-receipts.mjs`, `scripts/verify-telemetry-hooks.mjs`, `standards/telemetry-standards.md`, and `tests/helpers/controllable-backend.mjs`.
- Delete the 15 telemetry-only test suites under `tests/` and the 5 regression copies under `tests/regression/`.
- Delete `hooks/enforcement/phase-enum.mjs`, because all four of its exports are consumed only by files this requirement deletes.
- Keep `hooks/enforcement/read-stdin.mjs` unchanged. Six surviving enforcement hooks import it.

## Acceptance Criteria
- [ ] `test ! -d planifest-zero/hooks/telemetry` exits 0, confirming the telemetry hooks folder is gone.
- [ ] `find planifest-zero -name 'check-telemetry-*.mjs' -o -name 'verify-telemetry-hooks.mjs' -o -name 'telemetry-standards.md' -o -name 'controllable-backend.mjs' -o -name 'phase-enum.mjs'` prints no results.
- [ ] `test -f planifest-zero/hooks/enforcement/read-stdin.mjs` exits 0, and `grep -rl "read-stdin" planifest-zero/hooks/enforcement/*.mjs | wc -l` reports 6, one per surviving enforcement hook that imports it.

## Dependencies
- None. This requirement runs first; req-002 through req-004 and req-008 depend on it.
