---
title: "Recommendations - 0000032-relocate-setup-config-to-plan-state"
summary: "P6 recommendations, deferred items, and tech debt filed for this feature."
status: "draft"
version: "0.1.0"
---
# Recommendations - 0000032-relocate-setup-config-to-plan-state

**Skill:** [docs-agent](../../.claude/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Date:** 2026-09-09

## Deferred Items

Items judged out of scope for this feature on purpose, with the reasoning already recorded elsewhere in this feature's own artifacts.

| Item | Reference | Status |
|------|-----------|--------|
| No PowerShell suite runs through `planifest-zero/tests/run-tests.sh`. `setup.ps1` parity for `Write-SetupConfigOverride` is covered by static grep tests plus a manual `pwsh` procedure (req-002 acceptance criteria), not by an automated runner. | Risk R-005 in `plan/current/risk-register.md`. Already tracked as backlog 0000084. | Referenced, not refiled. |
| Two feature suites (`test-0000031-req-001-rename`, `test-0000031-req-005-telemetry-only-mcp`) fail on `main` because `planifest-framework/` exists again since PR #4. The P4 gate for this feature was overridden past these pre-existing failures. | Build log P4 entry. Already tracked as backlog 0000086. | Referenced, not refiled. |
| The framework's own telemetry receipt hook rejects the `"orchestrator"` phase name that `telemetry-standards.md` tells agents to send, so every `emit_event` call from the orchestrator writes a failure marker instead of a receipt. Surfaced again at this run's P0. | Build log P0 entry. Already tracked as backlog 0000085. | Referenced, not refiled. |
| This repo's own tracked record stays at `planifest-overrides/setup-config/claude-code.md` until `planifest-framework/` is refreshed from `planifest-zero/`. The dev-time copy still runs the old `setup.sh`, so it keeps writing the old path. | ADR-001 Negative Consequences; Risk R-002 in `plan/current/risk-register.md` (likelihood: certain, impact: low, accepted). | Filed as backlog 0000089. |

## Tech Debt

Acknowledged debt found or left in place during this feature, filed alongside the code that carries it.

| Item | Reference | Status |
|------|-----------|--------|
| `planifest-zero/setup.sh` line 1154 checks the tool name with `echo "$VALID_TOOLS" \| grep -qw "$TOOL"`, a regex word-boundary match rather than an exact comparison. `claude`, `code`, and `.*` all pass the check. `setup.ps1` line 1130 already uses an exact `-contains` match. Not exploitable today, since `setup_tool` requires `setup/{tool}.sh` to exist and exits before either path function runs. | Security report finding S-002 (informational, `plan/current/security-report.md`). | Filed as backlog 0000088. |

## Deliberate Absence: No per-component `docs/` folder

This run produced no `src/{component-id}/docs/` tree and none of the nine per-component artifacts a docs-agent run normally writes (`purpose.md`, `interface-contract.md`, and the rest). This is not a gap this run left behind. It follows from how this repository is structured.

`planifest-zero/` is the product this repository ships, and it is also the single component the framework's own `component.yml` describes (`planifest-zero/component.yml`). There is no `src/` tree here separate from the product folder, because the component being built *is* the framework. Feature 0000031 (five-phase pipeline) did not create a `src/{component-id}/docs/` tree either, for the same reason. This feature follows that same, already-established structure rather than introducing a new one.

Any future feature that adds a genuinely separate component to this repository, one with its own interface contract distinct from `planifest-zero/` itself, should get its own `src/{component-id}/docs/` tree at that point. Until then, `planifest-zero/component.yml`, `planifest-zero/pipeline-reference.md`, and `planifest-zero/project-operations.md` carry the documentation role that per-component docs would otherwise hold.

## Other Notes for the Ship Agent

- `plan/current/risk-register.md` R-003 reads `mitigated`. The orchestrator moved it during P5, after `test-0000025-req-004-setup-config-relocation.sh` was rewritten to assert the `plan/state/{tool}.md` path.
- `docs/decisions-index.md` already carries the three ADR rows for this feature and the Superseded row for 0000025 ADR 002. The orchestrator wrote them during P3, alongside req-005's layout-doc changes.
