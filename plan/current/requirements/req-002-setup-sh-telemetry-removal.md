---
title: "Requirement: req-002 - setup-sh-telemetry-removal"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - setup-sh-telemetry-removal

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want `setup.sh` free of telemetry code, so that a fresh install offers no telemetry flags and writes no telemetry wiring.

## Functional Requirements
- Remove the flag default and argument parsing for `--structured-telemetry-mcp` and `--backend-url`, and remove both from the usage text.
- Delete the three whole telemetry functions: `merge_telemetry_hook_settings`, `verify_telemetry_hooks_installed`, and `install_telemetry_hooks`.
- Remove the telemetry sentinel write and the telemetry entries interleaved inside `install_enforcement_hooks`, `write_setup_config_override`, and `write_setup_flags_marker`, keeping the six surviving enforcement hook entries and the 0000032 setup-record behaviour intact.
- Remove the telemetry hook path variables from `setup/claude-code.sh`.

## Acceptance Criteria
- [ ] `grep -i telemetry planifest-zero/setup.sh` returns no matches.
- [ ] `planifest-zero/setup.sh --structured-telemetry-mcp` exits with a non-zero code and prints an unknown-argument error.
- [ ] A setup run's generated `.claude/settings.json` contains exactly six enforcement hook entries and no `mcp__structured-telemetry-mcp__emit_event` matcher, checked by a test in `planifest-zero/tests/`.

## Dependencies
- req-001 (the deleted telemetry modules must be gone before `setup.sh` stops referencing them).
