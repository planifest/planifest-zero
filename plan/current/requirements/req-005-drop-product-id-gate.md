---
title: "Requirement: req-005 - drop-product-id-gate"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - drop-product-id-gate

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want the product-id gate removed, so that P0 no longer hard-stops asking for an id that only telemetry ever consumed.

## Functional Requirements
- Remove the top-level `id` field from `product.yml` and from `planifest-zero/templates/product.template.yml`.
- Remove step 9's product-id hard stop from `planifest-zero/skills/planifest-orchestrator/SKILL.md`.
- Keep `components[].id` in `product.yml` unchanged, because `planifest-zero/scripts/product-version.mjs` reads it.

## Acceptance Criteria
- [ ] `product.yml` has no top-level `id:` key, checked by a test that parses the file and asserts the top-level key is absent.
- [ ] `planifest-zero/templates/product.template.yml` has no top-level `id:` key, checked the same way.
- [ ] `grep -i "product.*id" planifest-zero/skills/planifest-orchestrator/SKILL.md` finds no hard-stop wording, while `grep "id:" product.yml` still finds the `id:` field nested under `components[]`.

## Dependencies
- None.
