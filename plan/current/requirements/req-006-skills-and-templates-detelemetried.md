---
title: "Requirement: req-006 - skills-and-templates-detelemetried"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - skills-and-templates-detelemetried

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want every skill and template free of telemetry wording, so that the framework's own instructions describe a system with no telemetry.

## Functional Requirements
- Remove the `## Telemetry` section and the `telemetry-standards.md` bundle reference from the six skills that carry them.
- Remove the `hooks: phase:` frontmatter key from all twelve skills that carry it, since no code reads it.
- Remove the `Telemetry` row and the summary's telemetry-gap count from `planifest-zero/templates/build-log.template.md`, and remove the telemetry clause from the orchestrator's build-log Hard Limit while keeping the phase block mandatory.
- Remove the telemetry bullet from `planifest-zero/templates/standard-boot.md`.

## Acceptance Criteria
- [ ] `grep -rl "## Telemetry" planifest-zero/skills/` returns no matches.
- [ ] `grep -rl "hooks:" planifest-zero/skills/*/SKILL.md | xargs grep -l "phase:"` returns no matches across all twelve skill files.
- [ ] `planifest-zero/templates/build-log.template.md` has no `Telemetry` row (`grep -i telemetry` returns no matches) while still containing its phase block section (`grep -i "phase"` still matches).

## Dependencies
- None.
