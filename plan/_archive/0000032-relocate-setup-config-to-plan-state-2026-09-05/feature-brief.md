---
title: "Feature Brief - relocate-setup-config-to-plan-state"
summary: "The business case, scope, and product requirements for the feature."
status: "confirmed"
version: "0.1.0"
---
# Feature Brief - relocate-setup-config-to-plan-state

**Feature ID:** 0000032-relocate-setup-config-to-plan-state

> Written by a human. The orchestrator reads this and coaches you through any gaps before passing it to the spec-agent.

## Business Goal

`setup.sh`/`setup.ps1` write the tracked record of active setup flags and backend URL to
`planifest-overrides/setup-config/{tool}.md` (ADR-002, `0000025-pipeline-gate-and-config-fixes`).
That directory otherwise holds only human-authored, review-controlled configuration:
instructions, library preferences, capability skills. This file is machine-derived and
rewritten on every setup run (its `writtenAt` field changes even when nothing else does),
so it doesn't fit that category. This feature relocates it to a location under `plan/`
whose name signals durable run/machine state, distinct from `plan/current/` (in-progress
pipeline artifacts) and `planifest-overrides/` (human-owned configuration).

Confirmed location (P0 coaching, 2026-09-05): `plan/state/{tool}.md`.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Relocate setup-config record | As a maintainer, I want the active setup-flags/backend-url record stored under `plan/`, so that it's grouped with other durable pipeline state rather than under human-owned overrides | must-have | 1 |

## Waves

Not applicable - single feature, one user story.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-zero (`setup.sh`, `setup.ps1`) | tooling script | existing | Writes the tracked setup-config record and the gitignored completion marker |
| planifest-refresh-setup skill | skill | existing | Gains a Step 3 read of the tracked record as its first source. Today it reads only the marker and hook wiring. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| Setup-config record (flags, backendUrl, writtenAt) | setup.sh / setup.ps1 | planifest-refresh-setup (read-only) |

### Integration Points

Not applicable - no cross-component runtime integration, this is a file-location change
read by one other skill.

## Stack

Not applicable - existing bash/PowerShell tooling, no new stack.

| Concern | Decision |
|---------|----------|
| Build target | local |

## Scope Boundaries

### In Scope
- Relocate the tracked setup-config record from `planifest-overrides/setup-config/{tool}.md`
  to the new `plan/` location, for every tool `setup.sh`/`setup.ps1` supports.
- Update `write_setup_config_override` (and the PowerShell equivalent) to write to the new path.
- Add a Step 3 read of `plan/state/{tool}.md` to `planifest-refresh-setup` as its first source,
  validated before use, falling back to the marker and hook inference on a missing or
  malformed record.
- Delete the old `planifest-overrides/setup-config/{tool}.md` and its emptied folder after a
  successful write, one printed line per removal, warning and continuing on failure.
- Update layout docs: `plan/README.md`, `plan/feature-structure.md`, `pipeline-reference.md`,
  `project-operations.md`.
- Write a superseding ADR for 0000025 ADR 002 (git history only) recording the new location and why.

### Out of Scope
- `planifest-framework/`, the dev-time copy that runs this repo's own pipeline. It is
  refreshed from `planifest-zero/`, not edited.
- A migration file for the old record. Setup cleans it up inline.
- Changing the gitignored `.planifest-setup-flags` marker's role, format, or location -
  unaffected by this move.
- Changing precedence/reconciliation behaviour between the tracked file and the marker -
  ADR-002's rules carry over unchanged, only the tracked file's path changes.

### Deferred
- None identified yet.

## Non-Functional Requirements

Not applicable - internal tooling relocation, no runtime performance/availability targets.

## Constraints and Assumptions

### Constraints
- Must remain git-tracked and human-reviewable in diffs (the property that motivated
  ADR-002 in the first place - this feature relocates it, it does not undo that).

### Assumptions
- The new folder name should read as "state," not "config" or "overrides," to avoid
  repeating the category confusion this feature is fixing.

## Scenario Paths

**Happy path:** The maintainer runs `setup.sh` or `setup.ps1`. The tracked record now lives
at `plan/state/claude-code.md`. If an old record exists under `planifest-overrides/setup-config/`,
setup deletes it, prints one line, and removes the emptied folder. On a later refresh,
`planifest-refresh-setup` reads the record first at high confidence, ahead of the marker and
hook inference, and reconstructs the flags from it.

**First-run path:** On a brand-new repo, `plan/state/` doesn't exist. Setup creates it and writes
the record with no removal message. On a repo upgrading from the old layout, the first run writes
the new record, removes the old file and emptied folder, and prints one line per removal. If
setup has never run when refresh-setup looks, the read finds nothing and the existing fallback
to the marker and hook inference takes over.

**Error / sad path:** If the record's folder is missing or not writable, setup warns and carries
on with the run's flags. The record is saved on the next successful run. If the new write
succeeds but the old copy can't be removed, setup warns and continues, and the leftover copy has
no effect because nothing reads it. If refresh-setup finds the record unreadable or malformed, it
treats it as missing, falls back to the marker then hook inference, and reports which source it used.

**Cross-session continuity:** If a setup run stops between writing the new record and removing
the old one, nothing is lost. The new record already holds the flags. The next run rewrites it
and removes the stale file. Refresh-setup validates the record before trusting it, so a record
truncated mid-write falls through to the marker. An interrupted refresh run recovers from its
own marker's pending status as it does today.

## Acceptance Criteria

- [ ] Setup-config record for every supported tool lives under the new `plan/` location, not `planifest-overrides/setup-config/`.
- [ ] `planifest-refresh-setup` Step 3 reads the record from `plan/state/{tool}.md` first, validates it, and falls back to the marker then hook inference when it is missing or malformed.
- [ ] A superseding ADR documents the relocation and its reasoning.
- [ ] After a successful write, setup removes `planifest-overrides/setup-config/{tool}.md` and the emptied folder, one printed line each, and warns without failing if removal fails.
- [ ] Layout docs describe `plan/state/` and no longer describe `planifest-overrides/setup-config/`.
- [ ] The tracked record wins over the gitignored marker: setup writes both from the same flags, and refresh-setup consults the record before the marker.
