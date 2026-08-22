---
title: "Requirement: REQ-001 - Boot File Always Regenerates"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-001 - Boot File Always Regenerates

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Source:** US-001
**Priority:** must-have

## User Story

As a human running a Planifest refresh, I want CLAUDE.md/AGENTS.md to always regenerate from the current template, so that stale instructions do not linger once local customization already lives in planifest-overrides/instructions/.

## Functional Requirements
- `write_boot_file` in `setup.sh` overwrites the boot file unconditionally with freshly rendered template content, instead of skipping when the file already exists.
- `Write-BootFile` (or equivalent) in `setup.ps1` carries the identical fix, in parity with `setup.sh`.
- `append_override_instructions` continues to run after regeneration exactly as before, so `planifest-overrides/instructions/` content is re-applied every time.
- Behavior applies uniformly to every tool that calls `write_boot_file`, not gated by tool identity.

## Acceptance Criteria
- [ ] Running `setup.sh <tool>` a second time in a repo with an existing boot file overwrites it with freshly rendered content.
- [ ] Override instructions from `planifest-overrides/instructions/` are present in the regenerated file, identical in content to before the fix.
- [ ] Running `setup.ps1 <tool>` a second time exhibits the same behavior on Windows.
- [ ] A repo with no `planifest-overrides/instructions/` directory still regenerates successfully, producing base template content with no override section.

## Dependencies
- None. Self-contained change to `setup.sh`/`setup.ps1`.
