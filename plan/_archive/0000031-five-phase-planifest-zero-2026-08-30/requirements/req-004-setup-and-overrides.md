---
title: "Requirement: req-004 - setup-and-overrides"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.2.0"
---
# Requirement: req-004 - setup-and-overrides

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Source:** US-004
**Priority:** must-have

## User Story
As the maintainer, I keep setup and the overrides mechanism working unchanged in function, so that repo-level customisation survives the cut.

## Functional Requirements
- `setup.sh` and `setup.ps1` continue to live at the framework folder root and accept target `claude-code` and flag `--structured-telemetry-mcp`.
- Both scripts copy skills to `.claude/skills/`, copy hooks to `.claude/hooks/`, write the `.claude/settings.json` hook wiring, install git hooks (`commit-msg`, `pre-commit`, `pre-push`), write the boot file `CLAUDE.md`, and write the `.planifest-setup-flags` marker.
- Both scripts update every internal reference from `planifest-framework` to `planifest-zero` to match the folder rename.
- Both scripts copy exactly the 12-skill set and wire the five-phase hook configuration.
- When regenerating `.claude/skills/`, both scripts delete retired skill folders first, leaving exactly the 12 new skills.
- The `planifest-overrides/` mechanism keeps its current behaviour: `instructions/` is read at discovery and folded into the design, `capability-skills/` is registered by setup, `setup-config/claude-code.md` is read by setup, and `library-standards/` is honoured. Only references to the old folder name change.
- The `planifest-refresh-setup` skill survives in trimmed form: it reconstructs flags from the marker file and re-invokes setup.
- Scripts may drop dead branches left over from removed features, provided observable behaviour for target `claude-code`, with and without `--structured-telemetry-mcp`, is unchanged.

## Acceptance Criteria
- [ ] Running `setup.sh claude-code --structured-telemetry-mcp` in a fresh temp clone exits 0.
- [ ] After that run, all hooks are registered in `.claude/settings.json`.
- [ ] After that run, `.claude/skills/` contains exactly 12 skills.
- [ ] After that run, the boot file `CLAUDE.md` is generated and the `.planifest-setup-flags` marker is written.
- [ ] Running `setup.sh claude-code` without the flag in a fresh temp clone shows telemetry hooks absent and enforcement hooks present.
- [ ] `setup.ps1` passes the equivalent temp-clone execution test for both the with-flag and without-flag cases.
- [ ] All `planifest-overrides/` subdirectories (`instructions/`, `capability-skills/`, `setup-config/claude-code.md`, `library-standards/`) are honoured by the regenerated tree.
- [ ] The regenerated tree references only `planifest-zero` paths, with no remaining `planifest-framework` references.
- [ ] `run-tests.sh` exits 0.

## Dependencies
- The 12-skill set defined for the five-phase pipeline.
- The `planifest-framework` to `planifest-zero` folder rename.
- The five-phase hook configuration.
