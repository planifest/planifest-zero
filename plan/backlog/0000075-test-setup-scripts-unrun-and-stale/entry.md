---
title: "Backlog Entry: 0000075 - test_setup scripts never run and assert on deleted targets"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000075 - test_setup scripts never run and assert on deleted targets

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/tests/run-tests.sh` line 29 discovers suites with the glob
`test-*.sh`, using a hyphen. Two files use an underscore instead:

- `planifest-framework/tests/test_setup.sh`
- `planifest-framework/tests/test_setup.ps1`

Neither is in `tests/regression/regression-manifest.json`. The runner has never
executed them. That is why feature 0000030 reported 51 feature suites and 20
regression suites passing while these two files still assert against deleted
behaviour.

Both invoke `setup.sh cursor` and check for `.cursor/skills/`. Both exercise the
`--include-full-skill-library` flag. Feature 0000030 removed the eight non-Claude
tool targets and that flag, so running either file today fails immediately.

The risk is a silent gap in coverage. Anyone reading the tests directory sees a
setup test and assumes setup is covered.

## Suggested Action

Decide whether setup needs its own suite. If it does, rename both files to the
`test-` prefix and rewrite them for the Claude Code target. If it does not,
delete both.

## Why Deferred

Out of scope for the cut-down, which removed features rather than reworking the
test harness. Filed ahead of a release that may change or remove much of this
surface, so re-verify the finding before pickup.
