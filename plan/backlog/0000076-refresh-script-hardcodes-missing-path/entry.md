---
title: "Backlog Entry: 0000076 - refresh script hardcodes a path this repo does not use"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000076 - refresh script hardcodes a path this repo does not use

**Source feature:** 0000030-framework-cut-down
**Source phase:** PC (Change Pipeline)
**Deferral source:** deliberate scope decision
**Date filed:** 2026-08-29

---

## Problem

`refresh-planifest-framework-dir.ps1` opens with:

```powershell
$repoDir = "C:\d\planifest\framework\"
```

It then runs `Remove-Item -Path "$repoDir\.claude\" -Recurse` and deletes
`CLAUDE.md` and `AGENTS.md` under that path, before calling `setup.ps1`.

This repository is `planifest/zero`, not `planifest/framework`. The path is
wrong for this clone and wrong for any other machine. `Remove-Item` carries
`-EA SilentlyContinue`, so the script reports nothing when the path is absent.
It then runs `Set-Location $repoDir`, which fails, and calls `setup.ps1` from
whatever directory the shell was left in.

The 0000030 changelog records this file under "Left as-is by decision". Its
flags were corrected during that build but its path was not.

## Suggested Action

Derive the repository root from the script's own location, for example with
`$PSScriptRoot`, and drop the hardcoded literal. If the script has no remaining
use now that `planifest-refresh-setup` exists as a skill, delete it instead.

## Why Deferred

Named in the 0000030 changelog as left as-is. The cut-down corrected the flags
the script passes and stopped there. Filed ahead of a release that may change or
remove much of this surface, so re-verify the finding before pickup.
