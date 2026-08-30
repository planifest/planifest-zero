---
title: "Requirement: req-003 - five-phases"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-003 - five-phases

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-003
**Priority:** must-have

## User Story
As the maintainer, I collapse the ten phases into discovery, plan, implement, validate-and-accept, and ship, so that runs carry less ceremony.

## Functional Requirements
- The orchestrator collapses the ten-phase pipeline into five phases: discovery, plan, implement, validate-and-accept, and ship.
- Discovery replaces the old P0. It covers the brief, coaching, `discovery.md`, backlog pickup, and version selection.
- Plan merges the old P1 and P2. It produces one requirements and ADR artifact set behind one human gate.
- Implement merges the old P3 and P6. Code, tests, and docs land together, driven by a TDD loop per requirement.
- Validate-and-accept merges the old P4 and P5. It covers CI, self-correction, security review, verify-by-execution, and the human acceptance gate.
- Ship merges the old P7, P8, and P9. It covers archive, build assessment, changelog, tag, and PR.
- Scope lock stays inside discovery. The orchestrator drafts the four scenario answers inline, without dispatching `planifest-scope-lock-agent`.
- The skill set shrinks from 21 files to 12.
  - New five-phase skills: `planifest-orchestrator` (rewritten, owns routing and discovery), `planifest-plan` (merges `planifest-spec-agent` and `planifest-adr-agent`), `planifest-implement` (merges `planifest-codegen-agent` and `planifest-docs-agent`), `planifest-validate-and-accept` (merges `planifest-validate-agent`, `planifest-security-agent`, and `planifest-verify-by-execution`), `planifest-ship` (merges `planifest-ship-agent` and `planifest-build-assessment-agent`).
  - Surviving skills, unchanged: `planifest-test-writer`, `planifest-implementer`, `planifest-refactor`, `planifest-loop-runner`, `planifest-optimise-agent`, `planifest-migrator`, `planifest-refresh-setup`.
  - Retired skills, folded into the five-phase skills above: `planifest-change-agent`, `planifest-spec-agent`, `planifest-adr-agent`, `planifest-codegen-agent`, `planifest-security-agent`, `planifest-docs-agent`, `planifest-verify-by-execution`, `planifest-build-assessment-agent`, `planifest-ship-agent`, `planifest-design-critic`, `planifest-reversal-assessor`, `planifest-scope-lock-agent`.
- `hooks/enforcement/phase-enum.mjs` shrinks its telemetry phase enum from seven values (`spec`, `adr`, `codegen`, `validate`, `security`, `docs`, `ship`) to five values (`discovery`, `plan`, `implement`, `validate-and-accept`, `ship`).
- The three consumers of `phase-enum.mjs` (`check-telemetry-receipts.mjs`, `resolve-phase.mjs`, `emit-event-receipt.mjs`) derive their phase values from the enum rather than duplicating it.
- `standards/telemetry-standards.md`, the stated source of truth, is updated to list the same five phase values.
- `resolve-phase.mjs` rewrites its skill-to-phase map to cover the 12 surviving skills.
- The response prefix convention changes to five prefixes: `D:` for discovery, `PL:` for plan, `IM:` for implement, `VA:` for validate-and-accept, and `SH:` for ship.
- The CI telemetry job in `.github/workflows/planifest.yml` extends to post a `phase_start` event for all five phase names, not only `ship`.
- The combined text of the orchestrator and phase skills stays at or below 50% of the current total line count, measured with `wc -l` over `skills/` before and after.

## Acceptance Criteria
- [ ] Exactly 12 skill folders exist under `skills/`.
- [ ] `phase-enum.mjs` exports exactly five phase values: `discovery`, `plan`, `implement`, `validate-and-accept`, `ship`.
- [ ] `check-telemetry-receipts.mjs`, `resolve-phase.mjs`, and `emit-event-receipt.mjs` derive their phase values from `phase-enum.mjs`.
- [ ] `standards/telemetry-standards.md` lists the same five phase values as `phase-enum.mjs`.
- [ ] `.github/workflows/planifest.yml` posts a `phase_start` event for all five phase names.
- [ ] The combined line count of the orchestrator and phase skill text is at or below 50% of the current total line count, measured with `wc -l` over `skills/` before and after.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- `hooks/enforcement/phase-enum.mjs` and its three consumers: `check-telemetry-receipts.mjs`, `resolve-phase.mjs`, and `emit-event-receipt.mjs`.
- `standards/telemetry-standards.md` as the source of truth for phase names.
- The CI telemetry job in `.github/workflows/planifest.yml`.
- The confirmed skill-fate mapping that decides which of the 21 existing skills merge, survive, or retire.
