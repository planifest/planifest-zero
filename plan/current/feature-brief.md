---
title: "Feature Brief - hardening and backlog skill"
summary: "Four backlog entries: a gate-write fix, Bash 3.2 test loops, telemetry cleanup retirement, and a backlog-filing skill."
status: "approved"
version: "1.1.0"
---
# Feature Brief - hardening and backlog skill

**Feature ID:** 0000164-hardening-and-backlog-skill

## Business Goal

The pack blocks agent writes outside the project, such as memory files. macOS test passes can be false, and setup still runs dead telemetry cleanup. This release fixes those three problems. It also adds a skill that files a backlog entry in another repo without touching that repo's git state.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| gate-write outside the project (0000162) | As an agent, I write files outside the project, such as memory, without a design, so that hooks gate only this project. | must-have | 1 |
| gate-write documented scope (0000162) | As a maintainer, I read in `CLAUDE.md` and the hook which paths it gates, including `plan/backlog/` and `plan/roadmap/` between runs, so that the docs match the behaviour. | must-have | 1 |
| Bash 3.2 test loops (0000161) | As a maintainer on macOS, I get the same suite results as CI, so that a local pass is a real pass. | must-have | 1 |
| Retire telemetry cleanup (0000095) | As a consumer, I run setup without the legacy telemetry cleanup, so that setup carries no dead code. Retired-hook pruning keeps working. | should-have | 1 |
| Backlog-filing skill (0000163) | As a human, I ask the agent to file a backlog entry in another repo, and it writes one uncommitted entry folder there, so that the other repo's branch and work stay untouched. | should-have | 1 |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| ravintio-zero | component-pack | existing | The drop-in pipeline pack: skills, hooks, setup, templates, and tests |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| none | | |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| Claude Code | `gate-write.mjs` | PreToolUse hook | JSON on stdin, exit 0 or 2 |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, PowerShell 5.1 and 7, Node.js ESM, Markdown |
| Testing | Shell and PowerShell suites under `ravintio-zero/tests/` |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- `gate-write` exits 0 for a target whose real path is outside the project root.
- `gate-write` names `plan/backlog/` and `plan/roadmap/` as allowed, and `CLAUDE.md` describes what the hook gates.
- The five suites that use `done < <(...)` switch to `done <<< "$(...)"`, plus a guard test.
- Setup drops the telemetry cleanup in both shells and keeps the retired-hooks list.
- New skill `ravintio-file-backlog`, listed in the skills catalogue, with tests.

### Out of Scope
- Narrowing the `plan/` or `docs/` allowed set.
- Backlog entries 0000100, 0000110, and 0000159.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Hook latency | No added process or network call in `gate-write` | Code review |
| Portability | Every suite passes on Bash 3.2, Bash 5, and PowerShell 5.1 and 7 | CI and a local `env -i` run |

## Constraints and Assumptions

### Constraints
- The skill never commits, pushes, switches branches, or opens a PR in the other repo.
- Retired-hook pruning (0000151 ADR-007) keeps working.

### Assumptions
- No live consumer still carries pre-0000033 telemetry wiring.

## Scenario Paths

See the Scope Lock lines in `plan/current/build-log.md`.

## Acceptance Criteria

- [ ] A write to a path outside the project passes `gate-write`, with and without `design.md`.
- [ ] A symlink inside the project that points outside does not skip the in-project checks.
- [ ] No suite under `ravintio-zero/tests/` uses `done < <(`, and a guard test fails if one does.
- [ ] Setup in both shells has no telemetry cleanup, and retired hooks are still pruned.
- [ ] `ravintio-file-backlog` writes one entry with the next free id and leaves git state unchanged.
