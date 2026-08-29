---
title: "Backlog Entry: 0000082 - CI fast-path branch applies a weaker parity check"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000082 - CI fast-path branch applies a weaker parity check

**Source feature:** 0000030-framework-cut-down
**Source phase:** PC (Change Pipeline)
**Deferral source:** deliberate scope decision
**Date filed:** 2026-08-29

---

## Problem

`.github/workflows/planifest.yml` runs two code and documentation parity checks
in the `validate-branch` job, and they accept different evidence.

The fast-path branch, lines 20 to 33, triggers when every commit subject matches
`^fix\(fast-path\):`. For a diff touching `src/`, it accepts only
`component.yml` or `plan/changelog/`.

The standard branch, lines 39 to 44, accepts `plan/`, `docs/`, or any
`component.yml`.

The 0000030 changelog flags the branch under "Left as-is by decision", noting
that its `plan/changelog/` requirement now points at a directory holding one
file.

Two questions need answering before anyone edits the file. First, whether the
fast-path exemption should exist at all now that Fast Path has its own gate in
`workflows/fast-path.md`. Second, whether a `docs/`-only change should satisfy
the fast-path branch, as it already satisfies the standard one.

## Suggested Action

Decide whether to align the two branches on the same evidence, or to delete the
fast-path exemption and let every diff meet the standard check. Mirror whatever
lands into `planifest-framework/hooks/planifest.yml`, the copy `setup.sh` ships
to consumer repositories.

## Why Deferred

Named in the 0000030 changelog as left as-is. This needs a design decision about
what Fast Path should prove in CI, not a mechanical edit. Filed ahead of a
release that may change or remove much of this surface, so re-verify the finding
before pickup.
