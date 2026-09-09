---
title: "Backlog Entry: 0000089 - this repo's own setup-config record stays at the old path"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000089 - this repo's own setup-config record stays at the old path

**Source feature:** 0000032-relocate-setup-config-to-plan-state
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-09-09

---

## Problem

Feature 0000032 moves the tracked setup-config record from
`planifest-overrides/setup-config/{tool}.md` to `plan/state/{tool}.md`, but
only inside `planifest-zero/`, the product component. `planifest-framework/`,
the dev-time copy that runs this repository's own pipeline, keeps its old
`setup.sh` until it is next refreshed from `planifest-zero/`. Until that
refresh happens, this repository's own record stays at
`planifest-overrides/setup-config/claude-code.md`, the exact path this
feature exists to retire everywhere else.

## Suggested Action

Refresh `planifest-framework/` from `planifest-zero/` (the standard
dev-copy refresh this repository already uses after a product change), then
confirm `planifest-overrides/setup-config/claude-code.md` is gone and
`plan/state/claude-code.md` exists.

## Why Deferred

Recorded as an accepted, certain-likelihood, low-impact risk in this
feature's own risk register (R-002, `plan/current/risk-register.md`) and as
a documented Negative Consequence in ADR-001
(`plan/current/adr/ADR-001-setup-config-record-lives-in-plan-state.md`).
Both artifacts scope this feature to `planifest-zero/` only, per the
design's Engineering Layer and Component Paths sections, so refreshing
`planifest-framework/` is left to a separate run.
