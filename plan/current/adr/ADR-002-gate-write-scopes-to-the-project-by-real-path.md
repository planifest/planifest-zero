---
title: "ADR 002: gate-write scopes to the project by real path"
summary: "gate-write exits 0 when the target's real path lies outside the project's real root. A symlink inside the project that points outside counts as outside."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - gate-write scopes to the project by real path

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Component:** ravintio-zero
**Date:** 2026-10-24

## Context

`gate-write.mjs` resolves the target against `cwd` and compares normalised strings. A target outside `cwd` keeps its raw path and fails Check 2 or Check 3, so the hook exits 2. This blocks legitimate writes such as agent memory files and the backlog skill's writes to another repo.

The docs also describe the hook as blocking only `src/`. The real hook gates every in-project path that is not always permitted. The `CLAUDE.md` bullet, `standard-boot.md`, `pipeline-reference.md`, and `project-operations.md` all say the narrower thing.

A string comparison cannot tell a symlink from a plain path. On macOS, `/tmp` and `/private/tmp` name the same place, so a string comparison can also misjudge an in-project write.

## Decision

`gate-write.mjs` exits 0 when the target's real path lies outside the project's real root. Hooks gate this project only.

- The hook resolves both the project root and the target with the same `realpathSync` call.
- If the target does not exist, the hook resolves the nearest existing parent and rejoins the remaining segments.
- If the real target path is inside the real root, Checks 0 to 3 run as before.
- The hook adds no process or network call.

The real path decides, even when the target goes through a symlink. A symlink inside the project that points outside counts as outside. The agent can therefore write through such a link to an outside location without a design. The hook accepts this trade-off, because the destination really is outside the project and REQ-001 states that rule. The hook has no more authority over that location than over any other outside path.

A symlink inside the project that points to another place inside the project gets the checks. A symlink cannot route a write past a gated path, because the gated path is the real destination.

The allowed set under `plan/` and `docs/` stays as it is. The hook header names `plan/backlog/` and `plan/roadmap/` as allowed between runs. The four docs describe the real gate: every in-project path that is not always permitted, the `plan/current/` sentinel check, and that outside targets pass.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Gate only `src/` | Matches the old docs | Drops the `plan/current/` sentinel check and the declared-component check on other paths | The human rejected it in P0 |
| Keep blocking outside writes | No behaviour change | Blocks agent memory writes and the backlog skill | It gates paths this project does not own |
| Treat an outside-pointing symlink as inside | Closes the write-through-link path | Needs a second resolution rule, and the link still points at a place this project does not own | The real path is the truth, and REQ-001 states it |
| Compare lexical paths and resolve only `cwd` | Smaller change | `/tmp` and `/private/tmp` aliasing misjudges targets | Both sides must resolve the same way |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-zero | `gate-write.mjs` gains real-path scoping. `CLAUDE.md`, `standard-boot.md`, `pipeline-reference.md`, and `project-operations.md` change wording. Tests cover outside targets and symlinks |

## Consequences

**Positive:**
- Agent memory writes and writes to another repo pass without a design.
- The docs match what the hook does.
- A symlink to a place inside the project cannot dodge the gate.

**Negative:**
- A symlink inside the project that points outside lets the agent write to that outside location without a design. The hook does not cover it.
- Real-path resolution adds filesystem calls on every write check, though no process or network call.

**Risks:**
- Real-path resolution differs on Windows or under macOS `/private/tmp`, so an in-project write reads as outside and skips the gate. Both sides use the same call and tests run on all three CI hosts.

## Related ADRs

- ADR-001 - depends-on (uses `realpathSync` from the stack)
- ADR-004 - related-to (the backlog skill relies on outside targets passing)

## Supersedes

- None

## Superseded By

- None
