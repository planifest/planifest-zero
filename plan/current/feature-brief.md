---
title: "Feature Brief - five-phase-planifest-zero"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.2.0"
---
# Feature Brief - five-phase-planifest-zero

**Feature ID:** 0000031-five-phase-planifest-zero

> Assembled by the orchestrator from the human's dictated scope of 2026-08-29 and
> nine pulled-in backlog entries (0000075 to 0000083). Confirmed decisions from
> the coaching Q&A are folded in; the audit trail is in build-log.md.

## Business Goal

The framework carries the weight of a nine-tool, ten-phase past that no longer exists. Cut it to one route, five phases, and a folder name that matches the product, so every run pays less context and no document describes a framework that is not there.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Rename | As the maintainer, I rename `planifest-framework/` to `planifest-zero/` with every reference updated, so that the folder matches the product. | must-have | 1 |
| Single route | As the maintainer, I remove the Change Pipeline, Fast Path, and Retrofit routes, so that every change runs the one feature pipeline. | must-have | 1 |
| Five phases | As the maintainer, I collapse the ten phases into discovery, plan, implement, validate-and-accept, and ship, so that runs carry less ceremony. | must-have | 1 |
| Simplified workflow | As the maintainer, I keep setup and the overrides mechanism working unchanged in function, so that repo-level customisation survives the cut. | must-have | 1 |
| Telemetry only MCP | As the maintainer, I keep the telemetry MCP integration and remove every remaining trace of context-mode, so that one MCP concern remains. | must-have | 1 |
| Present-tense docs | As the maintainer, I rewrite all living docs to describe only the current state, so that history lives solely in change records. | must-have | 1 |

## Waves

One wave. Human decision of 2026-08-29: single run, no waves.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-zero | component-pack | existing (renamed from planifest-framework) | Standards, skills, hooks, templates, schemas, setup scripts enforcing the five-phase pipeline |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| plan/ artifacts, docs/, telemetry markers | planifest-zero | none |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| telemetry hooks | structured-telemetry MCP backend | HTTP POST | telemetry-standards.md event envelope; phase enum shrinks to five values |
| setup.sh / setup.ps1 | .claude/ installed tree | file copy | regenerated on setup re-run; live session insulated until then |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, PowerShell, Node.js (ESM hooks), Markdown |
| Runtime | Node 20+, bash, pwsh |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | bash test suites via run-tests.sh |
| IaC | none |
| Cloud | none |
| Compute | local |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- Rename `planifest-framework/` to `planifest-zero/` and update all 387 references across 93 files, including `product.yml` id, tests, skills, standards, migrations, and archive/backlog documents where they refer to the live path.
- Delete `workflows/change-pipeline.md`, `workflows/fast-path.md`, `workflows/retrofit.md`; rewrite `workflows/feature-pipeline.md` for five phases.
- Reduce 21 skills to 12 per the confirmed fate table (build log, P0).
- Rewrite the orchestrator for five phases: discovery, plan, implement, validate-and-accept, ship.
- Shrink the telemetry phase enum to five values; update `phase-enum.mjs`, its three consumers, `telemetry-standards.md`, and CI's schema check.
- Remove all remaining context-mode traces: `hooks/telemetry/context-pressure.mjs` if truly context-mode, guard tests asserting absence, and doc mentions.
- Rewrite `docs/` and all surviving framework docs to present state only. Historical narrative lives only in `plan/changelog/` and `plan/_archive/`.
- Keep `planifest-overrides/` mechanics and both setup scripts functionally intact, updated for new paths and phase names.
- Folded backlog items: 0000075 (delete or fix test_setup files), 0000076 (fix or delete refresh script), 0000077 (.gitattributes), 0000078 (.gitignore stale targets), 0000079 (tests README), 0000080 (feature-structure.md), 0000081 (skill trim, subsumed), 0000082 (CI fast-path branch removed), 0000083 (delete spent library-standards plan doc).

### Out of Scope
- Any change to the telemetry MCP backend server itself (external to this repo).
- Reintroducing any non-Claude tool target.
- Changes under `src/` beyond what setup regenerates.
- Backlog 0000084 (test-runner silent-skip design) stays open.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Context cost | Orchestrator + phase skill text ≤ 50% of current total line count | wc -l before/after |
| Test health | run-tests.sh exits 0 with zero failures | CI and local run |
| Setup integrity | Fresh `setup.sh claude-code --structured-telemetry-mcp` in a temp clone exits 0 and registers all hooks | verify-by-execution |
| Reference hygiene | Zero occurrences of `planifest-framework` outside `plan/changelog/`, `plan/_archive/`, and git history | grep sweep |

## Constraints and Assumptions

### Constraints
- 0000030 ADR-001 binds: Claude Code is the only tool target.
- The live `.claude/` tree is not touched by hand; it changes only when setup re-runs (human clarification, 2026-08-29).
- Version 0.2.0, confirmed.
- Commit standards: no AI attribution, ≤72-char subjects, granular commits.

### Assumptions
- The telemetry backend at localhost:3741 tolerates unknown phase values or is updated separately; failures surface via the marker protocol and do not block.
- `product.yml` id changes to `planifest-zero`; telemetry attribution restarts under the new id.
- Squash-merge on GitHub; branch history stays local.

## Scenario Paths

**Happy path:** The build executes the rename, the phase collapse, the route deletion, the skill cut, and the docs rewrite. Success: the grep for the old name is clean outside change records, run-tests.sh exits 0, and a fresh setup.sh in a temp clone completes without error. You merge the PR, setup.sh re-runs to activate the new contract, and feature 0000032 runs under the five phases.

**First-run path:** setup.sh regenerates `.claude/` with the 12-skill suite and five-phase hooks, and deletes the nine retired skills rather than leaving them beside the new set. Discovery initialises `plan/current/` from empty after the auto-trigger fires. Telemetry attribution restarts under the `planifest-zero` product id. setup.sh must complete before any pipeline command.

**Error / sad path:** Most likely failure: the telemetry backend rejects the five new phase enum values. This fails loudly in CI, whose telemetry job is extended to post all five phase names, rather than degrading silently. The failure-marker protocol stays for runtime errors.

**Cross-session continuity:** Uncommitted rename state is the exposure; granular commits minimise it and git recovers the rest. Resume reads `plan/current/`, which the old installed orchestrator parses, so this feature must not change the live artifact formats mid-run.

## Acceptance Criteria

- [ ] `planifest-zero/` exists; `planifest-framework/` does not; grep for the old name finds hits only in `plan/changelog/`, `plan/_archive/`, and commit history.
- [ ] Exactly one workflow file remains and it describes five phases: discovery, plan, implement, validate-and-accept, ship.
- [ ] Exactly 12 skills remain, matching the confirmed fate table.
- [ ] `phase-enum.mjs` exports exactly five values and all three consumers derive from it.
- [ ] No file outside change records mentions context-mode except to say nothing (i.e. zero mentions; guard tests either deleted or rewritten without the term).
- [ ] Every `docs/` file describes present state only; no "introduced in feature NNNN" narrative outside `plan/changelog/` and `plan/_archive/`.
- [ ] `setup.sh claude-code --structured-telemetry-mcp` from a fresh temp clone exits 0; regenerated `.claude/` tree references only `planifest-zero` paths.
- [ ] run-tests.sh exits 0.
- [ ] `planifest-overrides/` instructions, setup-config, capability-skills, and library-standards dirs all still honoured by the renamed scripts.
- [ ] `setup.sh` deletes retired skills from `.claude/skills/` when regenerating, leaving exactly the 12 new skills.
- [ ] The CI telemetry job posts all five phase names, not only `ship`.
