---
title: "Requirement: req-005 - layout-docs-updated"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - layout-docs-updated

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer reading the project's layout documentation, I want it to describe
`plan/state/` as the setup-config record's home, so that the docs match what the scripts
actually do.

## Functional Requirements
- `plan/README.md` documents `plan/state/` as a top-level folder holding durable,
  machine-written run state, distinct from `current/` and `_archive/`.
- `plan/feature-structure.md` adds `plan/state/` to the canonical layout diagram, described
  as machine-written and outside the per-feature `current/`/`_archive/` structure.
- `planifest-zero/pipeline-reference.md` updates its "Customising with planifest-overrides"
  section to remove `setup-config/` as a `planifest-overrides/` subfolder, and documents
  `plan/state/{tool}.md` as the tracked record's new location.
- `planifest-zero/pipeline-reference.md`'s "never touches `planifest-overrides/`" promise
  (in the "Re-run setup after update" section) is corrected: setup writes to `plan/state/`,
  not `planifest-overrides/`, and still never touches other `planifest-overrides/`
  subfolders.
- `planifest-zero/project-operations.md` updates its `planifest-overrides/` customisation
  table row for `setup-config/` to remove it, since it no longer lives there, and its "What
  to Commit" table reflects that `plan/state/` is git-tracked machine state, not
  `planifest-overrides/` content.
- No updated document still names `planifest-overrides/setup-config/` as the record's
  location.

## Acceptance Criteria
- [ ] `plan/README.md` has a `state/` row in its folder table, and `plan/feature-structure.md`'s layout diagram lists `plan/state/`.
- [ ] `planifest-zero/pipeline-reference.md` describes `plan/state/{tool}.md` in place of the `setup-config/` section, and its re-run text no longer claims setup never touches `planifest-overrides/` without naming the cleanup of the old record.
- [ ] A search for `planifest-overrides/setup-config` across the four docs (`plan/README.md`, `plan/feature-structure.md`, `planifest-zero/pipeline-reference.md`, `planifest-zero/project-operations.md`) returns no matches.

## Dependencies
- req-001
- req-002
- req-003
- req-004
