---
title: "Discovery - 0000030-framework-cut-down"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000030-framework-cut-down

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 30 feature directories and `docs/about.md` exists (priority 2). No `planifest-overrides/instructions/external-versioning.md`, so External Anchor does not apply. |
| Git pre-flight | Started on `main`. Human confirmed previous PRs merged and main up to date. Branch `feat/0000030-framework-cut-down` created. One uncommitted file, `planifest-overrides/setup-config/claude-code.md`, committed to the branch first as `6da7bac`. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.28.1`. `product.yml` agrees at `0.28.1` under `versionPolicy: max-component-version`.
- Prior features (`plan/_archive/`): 30 directories spanning `0000001-context-mode-enforcement-hooks` to `0000029-context-mode-removal-and-boot-file-regeneration-fix` (2026-08-09), plus `backlog-triage-2026-07-11`.
- Constraining ADRs, unless superseded:
  - `0000001` ADR-001 to ADR-004 govern the context-mode hook design. This feature removes context-mode outright, so all four become obsolete.
  - `0000016` ADR-002 defines `product.yml` as the product-level version manifest with live component version derivation. This feature edits its `components` list.
  - `0000024` requires a non-empty `product.yml` `id` for telemetry attribution. Present and unchanged.
  - `0000027` ADR-001 (minimal default Phase 1 artifact set) and ADR-003 (skill-scope principle) stay in force.
- Component and data-ownership map (`docs/component-registry.md`), three active components:
  - `planifest-framework` at `planifest-framework/component.yml`. Core standards, skills, hooks, and setup scripts. Survives this feature.
  - `context-mode-hooks` at `src/context-mode-hooks/`. Blocking PreToolUse hook scripts. Marked for deletion.
  - `setup-hook-integration` at `src/setup-hook-integration/`. Setup and hook install infrastructure. Marked for deletion.
- Pending framework migrations: none. `planifest-framework/migrations/` holds only `_done/` and two `migrate-archive-dirname` scripts.
- Telemetry: active. `.claude/.planifest-setup-flags` records `--structured-telemetry-mcp` with backend `http://localhost:3741`. No markers under `plan/.telemetry-failures/`.
- Backlog: 23 entries under `plan/backlog/`. Entry `0000062-no-lightweight-track-for-projects-without-src-components` describes the exact routing gap this run hit when the Fast Path gate failed.

## Signals that could not be determined

None. Every signal above read cleanly.
