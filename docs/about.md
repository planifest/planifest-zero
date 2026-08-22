---
version: "0.1.0"
feature: "0000030-framework-cut-down"
updated: "22 Aug 2026"
---
# About

> This file is the canonical version record for this project.
> Do not edit manually; version changes are confirmed during P0 coaching.

| Field | Value |
|-------|-------|
| Version | `0.1.0` |
| Last feature | `0000030-framework-cut-down` |
| Updated | `22 Aug 2026` |

## Version reset

Feature 0000030 reset the version from `0.28.1` to `0.1.0`. The orchestrator
hard-blocks a downward version, and the human on the loop cleared that block
explicitly. The same feature emptied `plan/_archive/`, `plan/changelog/`, and
`docs/`, so the version history was deleted rather than contradicted.

Everything before `0.1.0` is recoverable from git history only.
