---
title: "Backlog Entry: 0000084 - the test runner silently skips files that miss its glob"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000084 - the test runner silently skips files that miss its glob

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/tests/run-tests.sh` discovers suites with two globs:
`"$SCRIPT_DIR"/test-*.sh` on line 29 and `"$REGRESSION_DIR"/test-*.sh` on line
42. It then reports pass and fail counts and exits.

Nothing checks that every test file in either directory was considered. A file
that misses the naming convention is never run and never mentioned. The counts
look healthy because the runner counts only what it found.

This is the same failure mode the runner was written to fix. Its own comment on
line 27 records the history: "backlog 0000004: hardcoded list silently skipped
5 of 14 suites, including this feature's own." Replacing the list with a glob
removed that instance. It did not remove the class.

`test_setup.sh` is the standing proof. It has never run, and feature 0000030
reported 51 feature suites and 20 regression suites passing while the file sat
in the same directory asserting against deleted Cursor behaviour. Entry 0000075
covers those two files. This entry covers the mechanism that hid them.

Two narrower gaps sit alongside it:

- The runner is bash only. `test_setup.ps1` is the sole PowerShell suite and no
  discovery path reaches it, so the PowerShell setup script has no runnable
  coverage through the runner on any platform.
- `tests/regression/regression-manifest.json` registers regression suites by
  hand while the regression glob discovers them automatically. Nothing reconciles
  the two. A regression suite present in one and absent from the other goes
  unreported either way.

## Suggested Action

Make non-discovery loud rather than silent. One approach is a pre-flight pass in
`run-tests.sh`: list every file in `tests/` and `tests/regression/`, subtract the
known non-suite files and the discovered suites, then fail the run if anything
remains. That turns a stray filename into a red run instead of a quiet gap.

Decide separately whether PowerShell suites need a discovery path, and whether
`regression-manifest.json` should be generated from the directory rather than
maintained alongside it.

## Why Deferred

Out of scope for the cut-down, which removed features rather than reworking the
test harness. Fixing this needs a decision about what the runner should treat as
a suite and what it should treat as an error, so it is a design change rather
than a mechanical edit. Filed ahead of a release that may change or remove much
of this surface, so re-verify the finding before pickup.
