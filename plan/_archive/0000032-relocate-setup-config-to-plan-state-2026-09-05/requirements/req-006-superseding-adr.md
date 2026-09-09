---
title: "Requirement: req-006 - superseding-adr"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - superseding-adr

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer reviewing architecture history, I want a new ADR that supersedes
0000025 ADR 002's storage location, so that the record of why the setup-config record
moved is durable and findable alongside the original decision.

## Functional Requirements
- A new ADR, produced at P2, records the decision to store the setup-config record at
  `plan/state/{tool}.md` instead of `planifest-overrides/setup-config/{tool}.md`.
- The ADR states what it supersedes: 0000025 ADR 002's decision that the tracked record
  lives under `planifest-overrides/setup-config/`. 0000025 ADR 002 itself exists only in
  git history and this feature does not restore or edit it.
- The ADR records the context: `planifest-overrides/` otherwise holds only human-authored,
  review-controlled configuration, and a record rewritten by every setup run does not fit
  that category.
- The ADR records what carries over unchanged: the record stays git-tracked, the gitignored
  `.planifest-setup-flags` marker's role and precedence rules are untouched, and only the
  record's path moves.
- The ADR records the consequence for consumer repos: on their next `setup.sh`/`setup.ps1`
  run, the relocation and old-file cleanup happen inline, with no separate migration file.
- `docs/decisions-index.md` gains a row for the new ADR, and marks the superseded 0000025 ADR 002
  row as superseded, naming the new ADR.

## Acceptance Criteria
- [ ] A new ADR under `plan/current/adr/` follows `planifest-framework/templates/adr.template.md` and names 0000025 ADR 002 as the decision it supersedes.
- [ ] The ADR names `plan/state/{tool}.md` as the new location, `planifest-overrides/setup-config/{tool}.md` as the old one, and states that the marker file's role, format, and location are unchanged.
- [ ] `docs/decisions-index.md` has a row for the new ADR and a Superseded row for 0000025 ADR 002 naming it.

## Dependencies
- None.
