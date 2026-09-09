---
title: "Requirement: req-003 - inline-cleanup-of-old-record"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - inline-cleanup-of-old-record

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer upgrading from the old layout, I want setup to remove the stale
`planifest-overrides/setup-config/{tool}.md` record once the new one is written, so
that my repository does not carry a duplicate, unread copy of the same state.

## Functional Requirements
- After `write_setup_config_override` (bash) or `Write-SetupConfigOverride` (PowerShell)
  writes `plan/state/{tool}.md` successfully, the script deletes
  `planifest-overrides/setup-config/{tool}.md` at its exact path, if it exists.
- After deleting that file, the script removes `planifest-overrides/setup-config/` if the
  directory is then empty. It does not remove the directory if other files remain in it.
- Each removal (the file, and the directory when applicable) prints one line naming the
  path removed.
- If the old file exists but cannot be removed, the script prints a warning naming the path
  and continues the run rather than aborting.
- If the write to `plan/state/{tool}.md` failed, the script does not attempt to remove the
  old file, since the record it depends on isn't in place yet.
- If no old file exists (a new repo, or a repo already upgraded), the script performs and
  prints nothing for this step.

## Acceptance Criteria
- [ ] Given `planifest-overrides/setup-config/claude-code.md` exists before `setup.sh claude-code`, afterwards the old file is gone, `plan/state/claude-code.md` exists, and one printed line names the removed old path. If the folder held only that file, the folder is gone too. If it held another file, the folder and that file remain.
- [ ] Given no old file or folder exists, or on a second run against a migrated repo, `setup.sh` exits `0` and prints no removal line. Given the old file cannot be removed (read-only folder), `setup.sh` prints one warning and exits `0`.
- [ ] A static test confirms `setup.ps1` removes the old `planifest-overrides\setup-config\{tool}.md` path and its emptied parent after a successful write.

## Dependencies
- req-001
- req-002
