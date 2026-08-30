---
title: "Requirement: req-002 - single-route"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-002 - single-route

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-002
**Priority:** must-have

## User Story
As the maintainer, I remove the Change Pipeline, Fast Path, and Retrofit routes, so that every change runs the one feature pipeline.

## Functional Requirements
- Delete `workflows/change-pipeline.md`, `workflows/fast-path.md`, and `workflows/retrofit.md`.
- Rewrite `workflows/feature-pipeline.md` as the sole route, covering five phases: discovery, plan, implement, validate-and-accept, and ship.
- Delete the `planifest-change-agent` skill folder under `skills/`.
- Remove the orchestrator's routing directive: the three-track decision tree, the fast-path criteria, and the "Invoking the Change Pipeline" section. Every request routes to the feature pipeline, and a trivial change is a small feature run.
- Fold the retrofit structured-scan content into the orchestrator's discovery phase text as a short subsection. Keep the adoption modes in reduced form. Leave no reference to a deleted `workflows/retrofit.md` file.
- In `.github/workflows/planifest.yml`, delete the `validate-branch` job's fast-path exemption branch that matches commits against `^fix\(fast-path\):` and applies a weaker check. The standard presence check must apply to every diff.
- Mirror the same deletion into the framework's `hooks/planifest.yml` copy that `setup.sh` ships to consumer repos.
- Delete or rewrite tests that assert the existence of the three removed routes or the `planifest-change-agent` skill.

## Acceptance Criteria
- [ ] Exactly one file remains in `workflows/`.
- [ ] No skill named `planifest-change-agent` exists in the repository.
- [ ] `.github/workflows/planifest.yml` has no fast-path exemption branch in the `validate-branch` job.
- [ ] The framework's `hooks/planifest.yml` copy carries the matching deletion.
- [ ] A grep for `fast-path`, `change-pipeline`, and `Change Pipeline route` finds no live references outside `plan/_archive/`, `plan/changelog/`, and git history.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- Requires the rewritten `workflows/feature-pipeline.md` to define all five phases before dependent skills or tests can reference it.
- Requires coordination with the orchestrator skill content, since its routing directive changes alongside route removal.
