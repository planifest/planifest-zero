---
title: "Discovery - 0000029-context-mode-removal-and-boot-file-regeneration-fix"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000029-context-mode-removal-and-boot-file-regeneration-fix

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `docs/about.md` present (version 0.28.0) and `plan/_archive/` contains multiple prior features |
| Git pre-flight | `main`, confirmed up to date with `origin/main` (0/0 divergence). One pre-existing uncommitted file, `planifest-overrides/setup-config/claude-code.md`, folded into this feature's scope. |
| Skills inbox | `planifest-framework/skills-inbox/` empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.28.0`
- Prior features (`plan/_archive/`, most recent 5): `0000024-declared-product-id-for-telemetry`, `0000025-pipeline-gate-and-config-fixes-and-ship-agent-fixes`, `0000026-context-hook-and-telemetry-backstop-fixes`, `0000027-backlog-batch-governance-tooling-fixes`, `0000028-telemetry-hardening-and-enforcement-fixes`
- Constraining ADRs: none identified that bear on boot-file regeneration behavior or context-mode template content specifically. `0000017` and `0000018` established the context-mode enforcement hook install path (`--context-mode-mcp`) and its later decoupling from telemetry; this feature removes references to that flag's associated MCP plugin from generated boot files but does not remove the `--context-mode-mcp` flag or its hook-install code path from `setup.sh` itself (out of scope, see Scope below).
- Component / data-ownership map: three components declared in `product.yml`, `planifest-framework` (this feature's target), `setup-hook-integration`, `context-mode-hooks`. This feature touches `planifest-framework` only (setup.sh, setup.ps1, templates/, planifest-overrides/instructions/).
