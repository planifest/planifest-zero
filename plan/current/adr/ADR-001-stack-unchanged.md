---
title: "ADR 001: Stack unchanged"
summary: "The feature keeps the declared stack and adds no dependency."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Component:** ravintio-zero
**Date:** 2026-10-24

## Context

The feature changes a Node.js hook, two setup scripts, five Bash suites, and adds one Markdown skill. The design declares Bash, PowerShell 5.1 and 7, Node.js ESM, Markdown, and GitHub Actions. No requirement needs a new language, library, or service.

## Decision

The feature keeps the declared stack and adds no dependency. `gate-write.mjs` uses `realpathSync` from `node:fs`, which ships with Node.js. The new skill is Markdown only.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add a path library for real-path handling | Hides platform differences | Adds a dependency to a drop-in pack that has none | `realpathSync` covers every case in REQ-001 |
| Write the backlog skill as a script | Testable by running it | Needs a new runtime path and a third implementation beside Bash and PowerShell | A skill that the agent follows needs no code |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-zero | No change to `product.yml` stack or approved dependencies |

## Consequences

**Positive:**
- Consumers copy the pack and run setup with no new install step.
- The existing CI hosts cover every change.

**Negative:**
- `gate-write.mjs` must handle Windows and macOS path aliasing itself, with no library to absorb it.

**Risks:**
- A later requirement may need a dependency. That requirement needs its own ADR.

## Related ADRs

- ADR-002 - related-to (uses `realpathSync`)

## Supersedes

- None

## Superseded By

- None
