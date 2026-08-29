---
title: "Backlog Entry: 0000080 - feature-structure.md contradicts the plan/current layout"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000080 - feature-structure.md contradicts the plan/current layout

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`plan/feature-structure.md` contradicts itself and contradicts the orchestrator.

Line 42 states that `plan/` is "organised by feature. Each feature gets a
subfolder." Line 46 draws that layout as `plan/{feature-id}/`. Lines 113 to 123
of the same file then give worked paths under `plan/current/`, including
`plan/current/design.md` and `plan/current/adr/ADR-001-*.md`.

Orchestrator Hard Limit 10 forbids the first layout outright: "Never leave a
permanent `plan/{feature-id}/` folder behind." Every route archives to
`plan/_archive/{feature-id}-{date}/`.

`plan/README.md` repeats the stale claim in its second line and points at
`feature-structure.md` as the canonical layout. A reader following that link
reaches a document that disagrees with itself.

## Suggested Action

Rewrite the early sections of `feature-structure.md` around the
`plan/current/` and `plan/_archive/` convention, then correct the second line of
`plan/README.md`. Check whether any skill or template still cites the
`plan/{feature-id}/` form.

## Why Deferred

Out of scope for the cut-down, which emptied `plan/_archive/` and
`plan/changelog/` without auditing the root-level plan documents that survived.
Filed ahead of a release that may change or remove much of this surface, so
re-verify the finding before pickup.
