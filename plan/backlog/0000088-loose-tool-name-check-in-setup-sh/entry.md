---
title: "Backlog Entry: 0000088 - loose tool-name check in setup.sh"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000088 - loose tool-name check in setup.sh

**Source feature:** 0000032-relocate-setup-config-to-plan-state
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-09-09

---

## Problem

`planifest-zero/setup.sh` line 1154 checks the tool name argument with:

```
echo "$VALID_TOOLS" | grep -qw "$TOOL"
```

`grep -w` matches a whole word inside a regular expression, not an exact
string. `claude`, `code`, `.*`, and `c.aude-code` all pass this check.
`planifest-zero/setup.ps1` line 1130 checks the same value with `-contains`,
an exact match, so the two scripts diverge on how strictly they validate the
same input.

The divergence predates this feature. It surfaced during the P5 security
review of feature 0000032 (finding S-002 in
`plan/current/security-report.md`), which also found it is not exploitable
today: `setup_tool` (lines 841-848) requires `setup/{tool}.sh` to exist and
exits under `set -e` before `write_setup_config_override` or
`remove_legacy_setup_config` run, and both of those functions quote `$tool`
so nothing expands as a glob.

## Suggested Action

Replace the `grep -w` check with an exact-match comparison loop over
`$VALID_TOOLS`, matching the `-contains` behaviour already in `setup.ps1`
line 1130.

## Why Deferred

The security report filed this as informational rather than a blocking
finding for 0000032, because the guard in `setup_tool` already closes the
exploitable path. See finding S-002 in `plan/current/security-report.md`
for the full reasoning.
