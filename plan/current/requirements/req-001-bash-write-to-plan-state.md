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
- [ ] Running `setup.sh claude-code` on a repo with no `plan/state/` directory creates
  `plan/state/` and writes `plan/state/claude-code.md`.
- [ ] `plan/state/claude-code.md` contains a ```json block whose `tool` field is
  `"claude-code"`.
- [ ] `plan/state/claude-code.md` contains `flags` and `backendUrl` fields matching the
  flags passed to `setup.sh` for that run.
- [ ] Setup prints a line containing `plan/state/claude-code.md` after a successful write.
- [ ] Running `setup.sh` a second time changes only the `writtenAt` field in
  `plan/state/claude-code.md`.
- [ ] `setup.sh` exits `0` and still writes `{tool-dir}/.planifest-setup-flags` when
  `plan/state/` cannot be created (for example, `plan/` is read-only).
- [ ] `plan/state/claude-code.md` is not matched by any `.gitignore` rule and appears in
  `git status --porcelain` as trackable.

## Dependencies
- None.
