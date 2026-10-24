---
title: "ADR 003: Retire the telemetry cleanup and keep the retired-hooks list"
summary: "Setup drops the legacy telemetry cleanup in both shells. The module list stays as RETIRED_HOOK_NAMES and $RetiredHookNames for retired-hook pruning."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Retire the telemetry cleanup and keep the retired-hooks list

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Component:** ravintio-zero
**Date:** 2026-10-24

## Context

0000033 ADR-002 made setup remove telemetry wiring on every run. That wiring came from `setup.sh --structured-telemetry-mcp`, which the pack removed in 0000033. The cleanup now runs in each setup for a case that no live consumer is known to have.

The cleanup code lives in `remove_legacy_telemetry_wiring` and `Remove-LegacyTelemetryWiring`, with a matcher constant and a list of ten module names. The module list also feeds retired-hook pruning (the 0000151 retired-hooks ADR (decision 7)). Deleting the list with the cleanup would break pruning.

## Decision

Setup in both shells drops the legacy telemetry cleanup and its call.

- Remove `remove_legacy_telemetry_wiring`, `Remove-LegacyTelemetryWiring`, `TELEMETRY_MCP_MATCHER`, and `$TelemetryMcpMatcher`.
- Keep the ten names as `RETIRED_HOOK_NAMES` in `setup.sh` and `$RetiredHookNames` in `setup.ps1`. The pruning functions read the renamed lists and behave as before.
- Delete or rewrite the suites that test the cleanup. Keep the pruning suites and change their list-name asserts.
- State in the 1.1.0 changelog that a pre-0000033 consumer removes stale telemetry wiring by hand.
- Leave the archived 0000033 ADR-002 as written. Archives record history.
- Hook install drops each `settings.json` entry that runs a hook on the retired-hooks list. Before 0000164, only the telemetry cleanup removed those entries. Pruning now removes them for any retired hook, so it keeps working after the cleanup goes.
- Setup no longer removes the `mcp__structured-telemetry-mcp__emit_event` matcher entries, `.claude/telemetry-enabled`, or the `plan/.telemetry-*` folders.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the cleanup | Repairs an old consumer on upgrade | Dead code runs on every setup in two shells, with ten test suites | No live consumer needs it |
| Delete the cleanup and the list together | Smaller scripts | Breaks retired-hook pruning from the 0000151 retired-hooks ADR (decision 7) | Pruning still needs the names |
| Move the cleanup into a one-off migration | Keeps the repair available | Adds migration machinery for a case with no known user | The changelog note covers the rare case |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-zero | `setup.sh`, `setup.ps1`, `component.yml`, the changelog, and about ten suites change |

## Consequences

**Positive:**
- Setup carries no dead telemetry code in either shell.
- Pruning keeps working from a list that no longer carries a telemetry name.

**Negative:**
- A pre-0000033 consumer keeps stale entries in `.claude/settings.json` and must remove them by hand. The changelog says so.
- The tool tries to run a missing module on every prompt in that consumer until they remove the entries.

**Risks:**
- A suite that still asserts cleanup output fails in CI. P1 lists every telemetry-mentioning suite and updates or deletes each one.

## Related ADRs

- the 0000151 retired-hooks ADR (decision 7) - depends-on (pruning reads the renamed list)
- 0000033 ADR-002 - supersedes

## Supersedes

- 0000033 ADR-002 - Setup cleans up telemetry wiring on every run

## Superseded By

- None
