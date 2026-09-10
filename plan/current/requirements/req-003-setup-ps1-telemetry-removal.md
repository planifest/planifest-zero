---
title: "Requirement: req-003 - setup-ps1-telemetry-removal"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - setup-ps1-telemetry-removal

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer, I want `setup.ps1` free of telemetry code, so that a Windows install mirrors the Bash install with no telemetry flags or wiring.

## Functional Requirements
- Remove the flag default and argument parsing for `--structured-telemetry-mcp` and `--backend-url`, and remove both from the usage text.
- Delete the three whole telemetry functions: `Merge-TelemetryHookSettings`, `Test-TelemetryHooksInstalled`, and `Install-TelemetryHooks`.
- Remove the telemetry sentinel write and the telemetry entries interleaved inside `Merge-EnforcementHookSettings`, keeping the six surviving enforcement hook entries and the 0000032 setup-record behaviour intact.
- Remove the telemetry hook path variables from `setup/claude-code.ps1`.

## Acceptance Criteria
- [ ] `planifest-zero/setup.ps1` declares no telemetry flag, installs no telemetry hook, writes no telemetry entry, and writes no telemetry sentinel. The only telemetry strings it may contain are the module names, matcher, and paths that the legacy-cleanup function of req-004 must name to find them, and every such string sits inside that function or its comment.
- [ ] Static grep confirms `Merge-TelemetryHookSettings`, `Test-TelemetryHooksInstalled`, and `Install-TelemetryHooks` are absent from `setup.ps1`, and that `--structured-telemetry-mcp` and `--backend-url` are absent from its usage text.
- [ ] A line-by-line mirror review of `setup.ps1`'s argument parsing and `Merge-EnforcementHookSettings` array against `setup.sh`'s equivalent (req-002) confirms the same six surviving hook entries and no telemetry entry, recorded as the review outcome since PowerShell has no test runner (backlog 0000084).

## Dependencies
- req-001 (the deleted telemetry modules must be gone before `setup.ps1` stops referencing them).
