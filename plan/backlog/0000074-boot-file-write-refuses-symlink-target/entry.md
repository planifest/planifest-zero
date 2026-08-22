---
title: "Backlog Entry: 0000074 - Boot-file write refuses symlink target"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000074 - Boot-file write refuses symlink target

**Source feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-09

---

## Problem

`write_boot_file` (setup.sh) and `Write-PlanifestBootFile` (setup.ps1) write through a symlink at the boot-file path. Feature 0000029 made these writes unconditional on every run (previously an existing file, symlink included, was skipped), so a symlink planted at `CLAUDE.md`/`AGENTS.md` redirects the template write to any user-writable path on every setup run. Exploitability is limited (requires prior repo write access; content written is template plus overrides, not attacker free text) but the write-through is silent. See 0000029 security-report SEC-001.

## Suggested Action

Both functions check whether the target exists as a symlink before writing; refuse with a clear message (or warn and skip) rather than writing through. Mirror the check in both scripts for parity.

## Why Deferred

Out of 0000029's confirmed scope (a behaviour hardening, not part of the regeneration fix); risk assessed Low with no in-the-wild trigger.
