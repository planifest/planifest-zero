---
title: "Feature Brief - relocate-setup-config-to-plan-state"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
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

Proposed location, pending confirmation in coaching: `plan/state/{tool}.md` (or similar -
name TBD, this is the human's suggestion from discussion, not yet finalised).

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
| planifest-framework (`setup.sh`, `setup.ps1`) | tooling script | existing | Writes the tracked setup-config record and the gitignored completion marker |
| planifest-refresh-setup skill | skill | existing | Reads the tracked setup-config record (Step 3) to reconstruct flags for a refresh |

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
- Update `planifest-refresh-setup`'s Step 3 read path.
- Update ADR-002 (`0000025-pipeline-gate-and-config-fixes`) with a superseding ADR recording
  the new location and why.

### Out of Scope
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

**Happy path:** `setup.sh`/`setup.ps1` runs, writes the tracked record to the new `plan/`
location instead of `planifest-overrides/setup-config/`, and `planifest-refresh-setup`
reads it from the new path without behaviour change.

**First-run path:** {{to be coached}}

**Error / sad path:** {{to be coached}}

**Cross-session continuity:** {{to be coached}}

## Acceptance Criteria

- [ ] Setup-config record for every supported tool lives under the new `plan/` location, not `planifest-overrides/setup-config/`.
- [ ] `planifest-refresh-setup` reads the record from the new location.
- [ ] A superseding ADR documents the relocation and its reasoning.
- [ ] Existing precedence/reconciliation behaviour (tracked file wins over the gitignored marker) is unchanged.
