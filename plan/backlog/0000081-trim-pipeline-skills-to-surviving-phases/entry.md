---
title: "Backlog Entry: 0000081 - trim the 21 pipeline skills to the surviving framework"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000081 - trim the 21 pipeline skills to the surviving framework

**Source feature:** 0000030-framework-cut-down
**Source phase:** PC (Change Pipeline)
**Deferral source:** deliberate scope decision
**Date filed:** 2026-08-29

---

## Problem

`planifest-framework/skills/` holds 21 skills written for a framework that
supported nine tool targets, context-mode, and a vendored external skill
library. Feature 0000030 removed all three.

The 0000030 changelog records the deferral verbatim: "The 21 pipeline skills.
Trimming them to the phases this framework keeps is a separate build."

The skills carry two costs while they stay as they are. Every one of them loads
into an agent's context at its phase, so surplus prose is paid for on every run.
Passages written for removed features may also send an agent down a path that no
longer exists.

## Suggested Action

Audit each skill against the surviving framework. `planifest-optimise-agent`
exists for this and presents one suggestion at a time for human confirmation.
Decide first whether every one of the 21 skills is still earning its place,
using the skill-scope test in 0000027-ADR-003.

## Why Deferred

Named in the 0000030 changelog as a separate build. The cut-down removed files
and rewrote documentation. Reworking skill content is a different kind of change
and needs its own design decision. Filed ahead of a release that may change or
remove much of this surface, so re-verify the finding before pickup.
