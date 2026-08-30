---
title: "Requirement: req-006 - present-tense-docs"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-006 - present-tense-docs

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-006
**Priority:** must-have

## User Story
As the maintainer, I rewrite all living docs to describe only the current state, so that history lives solely in change records.

## Functional Requirements
- Living documentation describes the present system only. This covers `docs/`, `README.md`, the framework folder's own `.md` files, `standards/`, `skills/`, `templates/`, `getting-started.md`, `pipeline-reference.md`, `project-operations.md`, `tests/README.md`, `plan/README.md`, and `plan/feature-structure.md`.
- Living documentation carries no historical narrative. Remove phrases such as "introduced in feature NNNN", "previously", "as of 0000030", ADR-number narrative, and removed-at tables.
- Historical narrative lives only in `plan/changelog/`, `plan/_archive/`, ADR files themselves, and git history.
- `docs/component-registry.md` loses its "Removed at 0000030" table and its "Last updated: 0000030" lines.
- `docs/decisions-index.md` is exempt from the present-tense rule. It is by nature an index of ADRs across features, so it survives as a change record in the same way a changelog does.
- `docs/about.md` keeps its frontmatter `version` field as the live version record. Its `feature` field stays too, as an acceptable pointer to the change record.
- `docs/dependency-graph.md` loses its reference to "the Tier 1 adapter path" history.
- `docs/architecture-overview.md` is audited for historical narrative and rewritten where it carries any.
- `tests/README.md` documents Claude Code as the only target. Remove all references to Cursor (folded backlog 0000079).
- `plan/feature-structure.md` no longer contradicts itself over per-feature subfolders versus `plan/current/`. Rewrite it around `plan/current/`, `plan/_archive/`, and the five phases (folded backlog 0000080).
- `plan/README.md` has its stale second line fixed to match the rewritten `plan/feature-structure.md`.
- `plan/library-standards-plan.md` is a spent plan document at the `plan/` root. Verify its work was delivered, then delete it (folded backlog 0000083).
- The framework `.gitignore` and the repository root `.gitignore` both lose the stale patterns `.cursor/`, `.gemini/`, `.windsurf/`, `.clinerules/`, and `GEMINI.md` (folded backlog 0000078). Keep `.claude/`, `CLAUDE.md`, and `AGENTS.md` where setup still writes them, along with any shared patterns.
- `tests/test_setup.sh` and `tests/test_setup.ps1` are deleted. Neither has ever run, since the test runner globs `test-*.sh` and these files use an underscore, and both assert deleted Cursor behaviour (folded backlog 0000075). The req-004 temp-clone execution check replaces them.
- Code and hook comments may keep requirement or ADR reference tags, such as "per 0000028-ADR-002", only where the tag cites a binding decision. Narrative history sentences around such tags are removed.

## Acceptance Criteria
- [ ] A grep across living docs for "0000030", "introduced in", "previously", and "Removed at" finds no narrative-history hits outside the exempt files: `docs/decisions-index.md`, the `feature` field in `docs/about.md`, `plan/changelog/`, and `plan/_archive/`.
- [ ] `docs/component-registry.md` has no "Removed at" table and no "Last updated: 0000030" line.
- [ ] `docs/dependency-graph.md` has no historical reference to "the Tier 1 adapter path".
- [ ] `docs/architecture-overview.md` is audited and carries no historical narrative.
- [ ] `tests/README.md` documents Claude Code only, with no Cursor references.
- [ ] `plan/feature-structure.md` and `plan/README.md` describe the same model: `plan/current/`, `plan/_archive/`, and the five phases, with no contradiction.
- [ ] `plan/library-standards-plan.md` is deleted, after confirming its work was delivered.
- [ ] The framework `.gitignore` and the repository root `.gitignore` no longer list `.cursor/`, `.gemini/`, `.windsurf/`, `.clinerules/`, or `GEMINI.md`.
- [ ] `tests/test_setup.sh` and `tests/test_setup.ps1` are deleted.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- req-004 (temp-clone execution check), which replaces the deleted `test_setup.sh` and `test_setup.ps1` coverage.
- Folded backlog items 0000075, 0000078, 0000079, and 0000083.
- Feature 0000031-five-phase-planifest-zero pipeline.
