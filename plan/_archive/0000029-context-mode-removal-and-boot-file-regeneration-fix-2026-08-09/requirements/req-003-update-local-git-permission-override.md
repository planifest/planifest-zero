---
title: "Requirement: REQ-003 - Update Local Git Permission Override"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-003 - Update Local Git Permission Override

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop, I want the agent's standing git-permission instruction updated to reflect that pull, push, and PR creation are now authorized, so that the agent's actual authority matches what has been granted.

## Functional Requirements
- `planifest-overrides/instructions/custom-001-local-git-only.md` states that pull, push, and PR creation (via `gh pr create`) are authorized for the agent by default in this repo.
- The same file states explicitly that commits directly to `main` and merging pull requests remain human-only, with no exception.
- The "Commit Granularly, Continuously" section in the same file is left unchanged.
- The heading "Local Git Only" is renamed or reworded since it is no longer accurate once pull/push/PR-create is authorized; new wording must not imply the old restriction still holds.

## Acceptance Criteria
- [ ] The regenerated `CLAUDE.md` (via `append_override_instructions`) reflects the updated wording, no reference to "don't fetch, pull, push" remains.
- [ ] The file explicitly names commits to `main` and PR merges as the only remaining human-only actions.
- [ ] This file's change is confirmed as repo-local configuration, not a `planifest-framework` distributed-source change, and is not represented as a fix that ships to other repos.

## Dependencies
- None. Self-contained change to `planifest-overrides/instructions/custom-001-local-git-only.md`.
