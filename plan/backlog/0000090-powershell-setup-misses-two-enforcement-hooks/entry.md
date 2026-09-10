---
title: "Backlog Entry: 0000090 - the PowerShell setup wires four enforcement hooks, not six"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000090 - the PowerShell setup wires four enforcement hooks, not six

**Source feature:** 0000033-remove-telemetry-mcp
**Source phase:** P3
**Deferral source:** discovered mid-flight

**Date filed:** 2026-09-10

---

## Problem

`planifest-zero/setup.sh` installs six enforcement hooks: `gate-write`, `check-design`,
`ratchet-check`, `em-dash-guard`, `auto-trigger-orchestrator`, and
`check-orchestrator-presence`. `planifest-zero/setup.ps1` installs four of them.
`ratchet-check` and `em-dash-guard` appear nowhere in the PowerShell script.

A count of each hook name across both scripts shows the gap plainly:

| Hook | setup.ps1 | setup.sh |
|------|-----------|----------|
| gate-write | 6 | 7 |
| check-design | 5 | 6 |
| ratchet-check | 0 | 7 |
| em-dash-guard | 0 | 6 |
| auto-trigger-orchestrator | 3 | 5 |
| check-orchestrator-presence | 4 | 6 |

This predates feature 0000033. The same zero counts hold on `main`, checked with
`git show main:planifest-zero/setup.ps1`.

A Windows user who installs with `setup.ps1` therefore gets no ratchet protection
on acceptance-criteria weakening, and no em-dash guard. Both are enforcement
controls the framework describes as active. Nothing reports the difference,
because no PowerShell suite runs through the test runner (backlog 0000084) and
the bash suites only ever read `setup.sh`.

## Suggested Action

Add the two missing hooks to `Merge-EnforcementHookSettings` in `setup.ps1`,
matching the bash entries and the de-duplication filter. Then add a static
parity test that compares the hook names wired by each script and fails when
they diverge, so the next omission surfaces on the first run rather than years
later.

## Why Deferred

Out of scope for 0000033, which removes telemetry. Adding two hooks to the
PowerShell installer is new enforcement behaviour on a platform with no runnable
coverage, so it needs its own verification plan.
