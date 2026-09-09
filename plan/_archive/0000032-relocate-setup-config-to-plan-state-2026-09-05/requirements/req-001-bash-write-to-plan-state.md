---
title: "Requirement: req-001 - bash-write-to-plan-state"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - bash-write-to-plan-state

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want `setup.sh` to write the active setup-flags and backend-url
record under `plan/`, so that it is grouped with other durable pipeline state rather
than under human-owned overrides.

## Functional Requirements
- `write_setup_config_override` in `setup.sh` writes the record to `plan/state/{tool}.md`
  instead of `planifest-overrides/setup-config/{tool}.md`.
- The function creates `plan/state/` when it does not already exist.
- The record keeps its existing content shape: a fenced ```json block with `tool`, `flags`,
  `backendUrl`, and `writtenAt`.
- On a successful write, the function prints one line naming the new path,
  `plan/state/{tool}.md`.
- On a failed write (the directory cannot be created, or the file cannot be written), the
  function prints a warning naming the new path and returns non-zero, and the caller
  continues the run rather than aborting.
- The call site in `setup.sh` keeps calling `write_setup_config_override` before
  `write_setup_flags_marker`, so the gitignored marker keeps reconciling to the same values.

## Acceptance Criteria
- [ ] Running `setup.sh claude-code` on a repo with no `plan/state/` creates the folder and writes `plan/state/claude-code.md` with a ```json block whose `tool`, `flags`, and `backendUrl` fields match the run, and prints a line naming that path.
- [ ] A second run changes only the `writtenAt` field, and `git check-ignore plan/state/claude-code.md` exits non-zero.
- [ ] When `plan/state/` cannot be created (read-only `plan/`), `setup.sh` prints one warning, still writes `{tool-dir}/.planifest-setup-flags`, and exits `0`.

## Dependencies
- None.
