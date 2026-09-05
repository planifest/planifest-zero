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
- [ ] Given `planifest-overrides/setup-config/claude-code.md` exists before a run, after
  `setup.sh claude-code` the file no longer exists and `plan/state/claude-code.md` does.
- [ ] Setup prints a line naming `planifest-overrides/setup-config/claude-code.md` as
  removed.
- [ ] When `planifest-overrides/setup-config/` holds only the removed file, the directory
  itself no longer exists after the run.
- [ ] When `planifest-overrides/setup-config/` holds an additional unrelated file, the
  directory still exists after the run and the unrelated file is untouched.
- [ ] Given no `planifest-overrides/setup-config/` directory exists before a run, `setup.sh`
  exits `0` and prints no removal line.
- [ ] Running `setup.sh` a second time against an already-migrated repo (old file already
  gone) prints no removal line.
- [ ] `setup.ps1` defines the matching removal logic: a static check confirms
  `Write-SetupConfigOverride` (or its caller) references removing the old
  `planifest-overrides\setup-config\{tool}.md` path and its emptied parent directory.

## Dependencies
- req-001
- req-002
