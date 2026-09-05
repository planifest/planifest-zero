---
title: "Requirement: req-002 - powershell-write-to-plan-state"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - powershell-write-to-plan-state

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer using Windows, I want `setup.ps1` to write the active setup-flags and
backend-url record under `plan/`, so that it is grouped with other durable pipeline
state rather than under human-owned overrides, matching the bash behaviour.

## Functional Requirements
- `Write-SetupConfigOverride` in `setup.ps1` writes the record to `plan/state/{tool}.md`
  instead of `planifest-overrides\setup-config\{tool}.md`.
- The function creates `plan/state/` when it does not already exist.
- The record keeps its existing content shape: a fenced ```json block with `tool`, `flags`,
  `backendUrl`, and `writtenAt`.
- On a successful write, the function writes one host line naming the new path,
  `plan/state/{tool}.md`.
- On a failed write, the function emits a warning naming the new path and returns `$false`,
  and the caller continues the run rather than aborting.
- The call site inside `Invoke-PlanifestSetup` keeps calling `Write-SetupConfigOverride`
  before `Write-SetupFlagsMarker`, so the gitignored marker keeps reconciling to the same
  values.

## Acceptance Criteria
- [ ] `Write-SetupConfigOverride` in `setup.ps1` references `plan/state` and not `planifest-overrides`, and `Invoke-PlanifestSetup` calls it before `Write-SetupFlagsMarker`. Verified by a static test.
- [ ] The ```json block shape (`tool`, `flags`, `backendUrl`, `writtenAt`) matches req-001 field for field, confirmed by mirror review because no PowerShell runner exists in CI (backlog 0000084).
- [ ] A documented manual `pwsh` run of `setup.ps1 claude-code` produces `plan/state/claude-code.md` with the correct `tool` field, prints a line naming the path, and a repeat run changes only `writtenAt`.

## Dependencies
- None.
