---
title: "Backlog Entry: 0000083 - library-standards-plan.md is a spent plan at the plan root"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000083 - library-standards-plan.md is a spent plan at the plan root

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`plan/library-standards-plan.md` describes work that appears to be done. It
proposes a new `planifest-framework/standards/library-standards.md` covering a
version policy and per-stack avoid and prefer lists. That standard now exists as
a directory, `planifest-framework/standards/library-standards/`, and the
orchestrator's `bundle_standards` list loads
`library-standards/_version-policy.md`.

The file sits at the `plan/` root. It belongs to neither `plan/current/` nor
`plan/_archive/`, so no route will ever archive it. A reader cannot tell from
its location whether it is pending or spent.

## Suggested Action

Compare the plan against the delivered `library-standards/` directory. If the
plan is fully delivered, delete it. If part of it is outstanding, file that part
as its own backlog entry and delete the document. Apply the same test to
`plan/feature-structure.md`, which shares the location problem and is covered
separately by entry 0000080.

## Why Deferred

Out of scope for the cut-down, which emptied `plan/_archive/`,
`plan/backlog/`, and `plan/changelog/` without auditing the loose documents at
the `plan/` root. Filed ahead of a release that may change or remove much of
this surface, so re-verify the finding before pickup.
