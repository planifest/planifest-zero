---
title: "Backlog Entry: 0000077 - .gitattributes references the deleted skill-sync script"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000077 - .gitattributes references the deleted skill-sync script

**Source feature:** 0000030-framework-cut-down
**Source phase:** Post-run review, no pipeline phase active
**Deferral source:** tech debt
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/.gitattributes` line 11 reads:

```
planifest-framework/scripts/skill-sync.sh text eol=lf
```

Feature 0000030 deleted `scripts/skill-sync.sh` and `scripts/skill-sync.ps1`
along with the `--include-full-skill-library` flag. The rule now matches
nothing.

The effect is cosmetic rather than behavioural. Git ignores a pattern with no
matching file. The cost is that a reader of `.gitattributes` infers the script
still exists.

## Suggested Action

Delete the line. Check the rest of the file for other patterns that no longer
match anything.

## Why Deferred

Out of scope for the cut-down, which tracked deletions by directory rather than
by every incoming reference. Filed ahead of a release that may change or remove
much of this surface, so re-verify the finding before pickup.
