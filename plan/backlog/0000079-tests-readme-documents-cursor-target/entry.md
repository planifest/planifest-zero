---
title: "Backlog Entry: 0000079 - tests README documents Cursor as a target tool"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000079 - tests README documents Cursor as a target tool

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/tests/README.md` describes a multi-tool setup that no
longer exists:

- Line 14 names "Claude Code or Cursor" as the agents under test.
- Line 38 says the setup script "is called for various target tools (e.g.
  `claude-code`, `cursor`)".
- Line 40 lists "`.claude/skills` or `.cursor/skills`" as the folders checked.

Feature 0000030 reduced both setup scripts to the Claude Code target. The README
contradicts the code it documents, which breaks the rule that documentation
matches reality.

## Suggested Action

Rewrite the three passages for a single target. Read the file end to end while
doing so, since other passages may carry the same assumption.

## Why Deferred

Out of scope for the cut-down, which rewrote the root README and the `docs/`
set but not the per-directory README files. Filed ahead of a release that may
change or remove much of this surface, so re-verify the finding before pickup.
