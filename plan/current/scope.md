---
title: "Scope - five-phase-planifest-zero"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.2.0"
---
# Scope - five-phase-planifest-zero

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Version:** 0.2.0

## In Scope

- Rename `planifest-framework/` to `planifest-zero/` via `git mv`, updating all live references (387 occurrences, 93 files). Historical records in `plan/_archive/` and `plan/changelog/` are not rewritten.
- `product.yml` id becomes `planifest-zero`. Telemetry attribution restarts under the new id.
- Delete `workflows/change-pipeline.md`, `workflows/fast-path.md`, `workflows/retrofit.md`. Rewrite `workflows/feature-pipeline.md` as the sole route.
- Delete the CI fast-path exemption branch in `.github/workflows/planifest.yml` and mirror the change to the shipped `hooks/planifest.yml` copy.
- Reduce 21 skills to 12 per the confirmed fate table. Merge content upward into the five phase skills.
- Rewrite the orchestrator for the five phases: discovery, plan, implement, validate-and-accept, ship.
- Shrink the telemetry phase enum to five values in `phase-enum.mjs`, its three consumers, and `telemetry-standards.md`. Extend the CI telemetry job to post all five names.
- Purge remaining context-mode traces: investigate `context-pressure.mjs` and act per req-005, delete or rewrite guard tests, remove doc mentions.
- Update both setup scripts for the rename, the 12-skill set, five-phase hook config, and retired-skill pruning on regeneration.
- Rewrite living docs to present state only per req-006, including the four folded doc-cleanup backlog items (0000078, 0000079, 0000080, 0000083).
- Delete `tests/test_setup.sh` and `tests/test_setup.ps1` (folded 0000075). The temp-clone execution check replaces them.
- Rename and fix `refresh-planifest-framework-dir.ps1` (folded 0000076). Remove the dead `.gitattributes` line (folded 0000077).

## Out of Scope

- Any change to the telemetry MCP backend server. It lives outside this repository.
- Reintroducing any non-Claude tool target (bound by 0000030 ADR-001).
- Changes under `src/` beyond what setup regenerates.
- Backlog 0000084 (test-runner silent-skip design). It stays open for a future run.
- Editing the live `.claude/` installed tree by hand. It changes only when setup re-runs.

## Deferred

Nothing deferred.
