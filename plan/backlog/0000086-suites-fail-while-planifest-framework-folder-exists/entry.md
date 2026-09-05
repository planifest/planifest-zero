---
title: "Backlog Entry: 0000086 - two suites fail while the planifest-framework folder exists"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000086 - two suites fail while the planifest-framework folder exists

**Source feature:** 0000032-relocate-setup-config-to-plan-state
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-05

---

## Problem

Two feature suites fail on `main` and on every branch since PR #4 re-added
`planifest-framework/` as the dev-time workflow copy:

- `test-0000031-req-001-rename.sh`: "old folder absent" and "live files
  referencing the old name".
- `test-0000031-req-005-telemetry-only-mcp.sh`: "live files mentioning the
  retired MCP".

Both suites assert the state feature 0000031 shipped: no `planifest-framework/`
folder and no live reference to the old name. PR #4 reversed that on purpose
for this repo only. The suites now encode a rule the repo no longer follows, so
every run reports two red suites that nobody acts on.

A third file, `test-skill-telemetry.sh` (present in both `tests/` and
`tests/regression/`), exits with `planifest: unbound variable` at line 11. The
runner does not count it as a failure.

## Suggested Action

Decide whether the 0000031 assertions should exclude `planifest-framework/`
when it is the declared workflow copy, or whether the two suites should move to
the regression pack with that carve-out. Fix or delete `test-skill-telemetry.sh`
so it either runs or stops being discovered.

## Why Deferred

Out of scope for 0000032, which relocates the setup-config record. The fix
needs a decision about what the repo promises regarding `planifest-framework/`.
