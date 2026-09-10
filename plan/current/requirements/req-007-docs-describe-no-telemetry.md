---
title: "Requirement: req-007 - docs-describe-no-telemetry"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - docs-describe-no-telemetry

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want the documentation to describe a framework with no telemetry, so that a reader never finds a stale reference to a removed system.

## Functional Requirements
- Update `pipeline-reference.md` to state the five phase names directly in prose, since `hooks/enforcement/phase-enum.mjs` no longer exists as their source.
- Update `project-operations.md` and `getting-started.md` to remove telemetry wording and the outbound link to the telemetry backend project.
- Update `tests/README.md` and `component.yml` to remove telemetry references, including any interface, inventory, or risk entries that mention telemetry.

## Acceptance Criteria
- [ ] `grep -ril telemetry planifest-zero/pipeline-reference.md planifest-zero/project-operations.md planifest-zero/getting-started.md` returns no matches.
- [ ] `grep -ril telemetry planifest-zero/tests/README.md planifest-zero/component.yml` returns no matches.
- [ ] `pipeline-reference.md` names all five pipeline phases directly in its own prose, without citing a module as their source. A test greps the file for each literal name: `discovery`, `plan`, `implement`, `validate-and-accept`, `ship`.

## Dependencies
- None.
