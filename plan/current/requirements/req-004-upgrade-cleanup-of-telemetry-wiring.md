---
title: "Requirement: req-004 - upgrade-cleanup-of-telemetry-wiring"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - upgrade-cleanup-of-telemetry-wiring

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want every setup run to clean up a project's prior telemetry wiring, so that an upgraded project stops pointing at deleted hook modules.

## Functional Requirements
- On every run, remove telemetry hook entries from the project's `.claude/settings.json`, delete `.claude/telemetry-enabled`, and delete `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` when present.
- Print one line per item removed, following the 0000032 ADR 003 precedent for inline cleanup.
- Warn and continue rather than fail the run when a removal fails, and stay silent when nothing is present to remove.

## Acceptance Criteria
- [ ] Running setup on a project with prior telemetry wiring prints one line per removed item and leaves the settings entries, sentinel file, and both marker directories absent afterward.
- [ ] Running setup a second time on that now-clean project prints no removal lines and exits 0.
- [ ] Running setup against a `.claude/settings.json` that a removal step cannot write prints one warning line and still exits 0.

## Dependencies
- req-002 and req-003 (the cleanup logic runs inside the already-detelemetried `setup.sh` and `setup.ps1`).

## Input Validation

- [ ] Input source: filesystem path `.claude/settings.json` in the target project, read and rewritten by the setup script.
- [ ] Allowed character pattern: the file must parse as valid JSON; a hook entry is identified for removal only by an exact match against the known telemetry command substring `mcp__structured-telemetry-mcp__emit_event`.
- [ ] Maximum length: not limited by this requirement beyond the file remaining valid JSON.
- [ ] Failure behaviour: if the file is malformed or unreadable, print one warning, leave the file unmodified, and exit 0.
- [ ] Logging policy: the raw contents of `.claude/settings.json` are never logged. Only the one-line-per-removal summary is printed.
