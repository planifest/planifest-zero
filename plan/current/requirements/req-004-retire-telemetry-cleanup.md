---
title: "Requirement: req-004 - retire-telemetry-cleanup"
summary: "Setup in both shells drops the legacy telemetry cleanup and keeps the retired-hook list under a neutral name."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - retire-telemetry-cleanup

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Source:** US-004
**Priority:** must-have

## User Story

As a consumer, I run setup without the legacy telemetry cleanup, so that setup carries no dead code. (Backlog 0000095)

## Functional Requirements
- Remove `remove_legacy_telemetry_wiring` and its call from `ravintio-zero/setup.sh`.
- Remove `Remove-LegacyTelemetryWiring` and its call from `ravintio-zero/setup.ps1`.
- Rename the module list to a standalone retired-hooks list.
  - In `setup.sh`, define `RETIRED_HOOK_NAMES` with the same ten names and drop `TELEMETRY_HOOK_MODULES`.
  - In `setup.ps1`, define `$RetiredHookNames` as an array with the same ten names and drop `$TelemetryHookModules`.
- `prune_retired_hooks` and `Remove-RetiredHooks` (the 0000151 retired-hooks ADR (decision 7)) keep reading the renamed list and behave as before.
- Remove `TELEMETRY_MCP_MATCHER` and `$TelemetryMcpMatcher`, which only the cleanup used.
- Remove any helper or shared code that only the cleanup used. Keep helpers that other setup code still calls.
- Remove the comment references to the cleanup in both scripts (`setup.sh` lines near 73 and 984, `setup.ps1` lines near 272, 408 and 1217).
- Setup no longer reads or writes telemetry entries in `settings.json`, `.claude/telemetry-enabled`, or `plan/.telemetry-failures` and `plan/.telemetry-receipts`.
- This requirement retires the cleanup decided in 0000033 ADR-002 (`plan/_archive/0000033-remove-telemetry-mcp-2026-10-16/adr/ADR-002-setup-cleans-up-telemetry-wiring.md`). The plan phase records a superseding ADR.

## Acceptance Criteria
- [ ] `grep -n -i "remove_legacy_telemetry_wiring\|Remove-LegacyTelemetryWiring\|TELEMETRY_MCP_MATCHER\|TelemetryMcpMatcher\|TELEMETRY_HOOK_MODULES\|TelemetryHookModules" ravintio-zero/setup.sh ravintio-zero/setup.ps1` returns nothing.
- [ ] A setup run in both shells leaves a telemetry entry in `settings.json`, `.claude/telemetry-enabled`, and `plan/.telemetry-*` untouched and prints no telemetry line.
- [ ] A setup run in both shells still removes a retired hook file from `.claude/hooks/` and its `settings.json` entry, using `RETIRED_HOOK_NAMES` and `$RetiredHookNames`.

## Dependencies
- None on other requirements in this feature.
- REQ-009 carries the test changes, the manifest update, and the changelog note.
- Builds on the 0000151 retired-hooks ADR (decision 7) (retired-hook pruning).
