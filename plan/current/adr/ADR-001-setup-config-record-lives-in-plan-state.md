---
title: "ADR 001: The setup-config record lives in plan/state/"
summary: "The tracked record of active setup flags moves from planifest-overrides/setup-config/{tool}.md to plan/state/{tool}.md. It stays git-tracked. planifest-overrides/ returns to holding only human-authored configuration. Supersedes 0000025 ADR 002."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - The setup-config record lives in plan/state/

**Skill:** [adr-agent](../../../.claude/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Component:** planifest-zero
**Date:** 2026-09-05

## Context

Feature 0000025 (ADR 002, now in git history only) made `planifest-overrides/setup-config/{tool}.md` the tracked record of the flags and backend URL in effect for a tool. That gave the record the properties it needed: git-versioned, reviewable in diffs, present after a fresh clone.

The location was the wrong category. Every other file under `planifest-overrides/` is human-authored and review-controlled: instructions, library preferences, capability skills. The record is machine-derived and rewritten on every setup run, so its `writtenAt` field changes even when nothing else does. A reader of that folder cannot tell reviewed configuration from generated state, and the doc promise that setup "never touches `planifest-overrides/`" became untrue.

`plan/` already holds machine-written run state as tracked dotfiles. `setup.sh` writes `plan/.orchestrator-strict`, and the orchestrator writes `plan/.orchestrator-active` and `plan/.orchestrator-ack`. Since 0000030 ADR 001 the only supported tool is Claude Code, so the record is one file.

The stack is unchanged: bash and PowerShell setup scripts, markdown skills, bash test suites. No new stack choice is made by this feature.

## Decision

1. The record moves to `plan/state/{tool}.md`. The setup scripts create `plan/state/` when it is absent.
2. The record keeps its format: a markdown file with one JSON block holding `tool`, `flags`, `backendUrl`, and `writtenAt`.
3. The record stays git-tracked. No `.gitignore` rule may match it.
4. `planifest-overrides/` returns to holding only human-authored configuration. Setup writes nothing there. The one exception is the inline removal of the old record, decided in ADR-003.
5. The gitignored marker `{tool-dir}/.planifest-setup-flags` keeps its role, format, and location.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `planifest-overrides/setup-config/` | No change, no upgrade path | Generated state stays mixed with reviewed configuration, and the doc promise stays untrue | The category confusion is the problem this feature exists to fix |
| A tracked dotfile at `plan/.setup-config-{tool}.md` | Sits beside the existing `plan/.orchestrator-*` dotfiles | Dotfiles are hidden in listings and easy to miss in review, which undoes the reviewability the record exists for | Reviewability outweighs consistency with the dotfiles |
| `plan/setup/{tool}.md` | Names what wrote it | "setup" reads as configuration input rather than recorded state, repeating the confusion in a new place | The folder name must read as state |
| `docs/state/{tool}.md` | `docs/` is living, present-state content (0000031 ADR 004) | `docs/` describes the system for readers. A machine-rewritten record with a timestamp is not documentation | `docs/` is for prose the docs agent maintains |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-zero (`setup.sh`, `setup.ps1`) | `write_setup_config_override` and `Write-SetupConfigOverride` write to the new path and create the folder |
| planifest-zero (`planifest-refresh-setup` skill) | Reads the record from the new path, see ADR-002 |
| planifest-zero (layout docs) | `plan/README.md`, `plan/feature-structure.md`, `pipeline-reference.md`, and `project-operations.md` describe `plan/state/` |
| planifest-zero (tests) | The 0000025 relocation suite is rewritten for the new path |

## Consequences

**Positive:**
- A reader of `planifest-overrides/` sees only files a human wrote and reviewed.
- The record sits with the other machine-written pipeline state and keeps every property 0000025 gave it.

**Negative:**
- Every consumer repo carries an upgrade step on its next setup run, and this repo's own record stays at the old path until the dev-time framework copy is refreshed.
- Two locations exist in history, so anyone reading old changelogs or ADRs must map the old path to the new one.

**Risks:**
- A consumer's `.gitignore` could match `plan/state/` by a broad `plan/` rule. The relocation test asserts the record is not ignored, but only in this repo.

## Related ADRs

- ADR-002 - depends-on (source precedence for the refresh-setup skill)
- ADR-003 - depends-on (inline cleanup of the old record)
- 0000030 ADR 001 - related-to (Claude Code is the only tool, so one record)
- 0000031 ADR 002 - related-to (product folder is `planifest-zero/`)

## Supersedes

- 0000025 ADR 002 (Setup config overrides precedence). Its decisions 1 to 4 carry over with the path changed. Its decision 5, that `.orchestrator-strict` is out of scope, still holds.

## Superseded By

- None
