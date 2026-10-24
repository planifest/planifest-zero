---
title: "Backlog Entry: 0000165 - user story mapping and Gherkin acceptance criteria"
summary: "A human-requested capability, filed for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000165 - user story mapping and Gherkin acceptance criteria

**Source feature:** 0000164-hardening-and-backlog-skill
**Source phase:** P2
**Deferral source:** human request
**Date filed:** 2026-10-25

---

## Problem

The plan phase derives one requirement per user story from the brief. Nothing checks the stories themselves for gaps. A story the brief missed never becomes a requirement. Acceptance criteria are free-text checkboxes, so their structure varies from one author to the next. Tests can't map to them line by line.

## Suggested Action

Add a user story mapping pass over the requirements in P1. It lays out the backbone of user activities and the steps under each, which shows stories the brief missed. Then write each acceptance criterion in Gherkin, as `Given`, `When`, and `Then` lines. Update `requirement.template.md` and `consistency-check.mjs` to match. Decide whether P0 or P1 owns the mapping pass, and whether Gherkin criteria still count against the three-criteria limit.

## Why Deferred

The human asked for it during 0000164 P2. It changes the plan skill, the requirement template, and the consistency check, so it needs its own design.
