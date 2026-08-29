---
title: "Backlog Entry: 0000078 - framework .gitignore still lists removed tool targets"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000078 - framework .gitignore still lists removed tool targets

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/.gitignore` ignores directories and boot files for tool
targets that feature 0000030 removed:

- Line 3: `.cursor/`
- Line 6: `.gemini/`
- Line 8: `.windsurf/`
- Line 9: `.clinerules/`
- Line 12: `GEMINI.md`

No setup path writes any of these now. `setup.sh` and `setup.ps1` accept
`claude-code` only.

The root `.gitignore` carries the same stale entries. Check both files, not just
the framework copy.

## Suggested Action

Remove the patterns for tools the framework no longer targets. Keep `.claude/`,
`CLAUDE.md`, and the shared patterns. Confirm nothing under `planifest-overrides/`
depends on a removed pattern before deleting it.

## Why Deferred

Out of scope for the cut-down. Filed ahead of a release that may change or
remove much of this surface, so re-verify the finding before pickup.
