---
title: "Requirement: req-001 - rename-folder"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-001 - rename-folder

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-001
**Priority:** must-have

## User Story
As the maintainer, I rename `planifest-framework/` to `planifest-zero/` with every reference updated, so that the folder matches the product.

## Functional Requirements
- Rename the `planifest-framework/` directory to `planifest-zero/` with `git mv`, so history follows the folder.
- Update the `id` field in `product.yml` to `planifest-zero`.
- Update every reference to `planifest-framework` across the repository, including in `tests/`, `skills/`, `plan/backlog/`, `migrations/`, root `README.md`, the standards, the templates, and both setup scripts.
- Rename `refresh-planifest-framework-dir.ps1` to `refresh-planifest-zero-dir.ps1`.
- Change the renamed script to derive the repository directory from `$PSScriptRoot`, and remove the hardcoded `C:\d\planifest\framework\` path.
- Remove the `.gitattributes` line for `scripts/skill-sync.sh`, since that file no longer exists.
- Leave references inside `plan/_archive/` and `plan/changelog/` unchanged, since these are historical records.
- Leave the historical mentions in the `plan/backlog/0000084` entry unchanged.
- Leave the installed `.claude/` tree unchanged. It regenerates only when setup re-runs.

## Acceptance Criteria
- [ ] `planifest-zero/` exists in the repository.
- [ ] `planifest-framework/` no longer exists in the repository.
- [ ] `grep -r "planifest-framework"` over the repository, excluding `.git`, `plan/_archive/`, and `plan/changelog/`, returns zero hits.
- [ ] `product.yml` has an `id` field of `planifest-zero`.
- [ ] `refresh-planifest-zero-dir.ps1` exists and derives the repository directory from `$PSScriptRoot`.
- [ ] `refresh-planifest-framework-dir.ps1` no longer exists.
- [ ] `.gitattributes` no longer contains a line for `scripts/skill-sync.sh`.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- Folded backlog entry 0000076, which covers the rename of `refresh-planifest-framework-dir.ps1` and the removal of its hardcoded path.
- Folded backlog entry 0000077, which covers removal of the stale `.gitattributes` line for `scripts/skill-sync.sh`.
