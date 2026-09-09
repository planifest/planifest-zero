---
title: "Discovery - 0000032-relocate-setup-config-to-plan-state"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000032-relocate-setup-config-to-plan-state

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds two feature directories and `docs/about.md` exists. No `planifest-overrides/instructions/external-versioning.md`. |
| Git pre-flight | Branch `feat/0000032-relocate-setup-config-to-plan-state`, tree clean, in sync with origin. Local `main` equals `origin/main`. No open pull requests. Confirmed by observation on 2026-09-05. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.2.0`. `product.yml` agrees, id `planifest-zero`, policy `max-component-version`.
- Prior features (`plan/_archive/`):
  - `0000030-framework-cut-down-2026-08-22`: Claude Code only target, history cleared, v0.1.0.
  - `0000031-five-phase-planifest-zero-2026-08-30`: five phases, one route, folder renamed to `planifest-zero/`, v0.2.0.
- Constraining ADRs (unless superseded):
  - 0000030 ADR 001: Claude Code is the only supported tool target. "Every tool `setup.sh` supports" in the brief means one tool, `claude-code`.
  - 0000031 ADR 001: five-phase pipeline contract for the product.
  - 0000031 ADR 002: product folder is `planifest-zero/`, product id `planifest-zero`.
  - 0000031 ADR 003: one route, the feature pipeline. Change Pipeline and Fast Path are dropped for this product, so this feature runs the feature pipeline and takes a minor bump.
  - 0000031 ADR 004: living docs describe the present only.
  - 0000025 ADR 002 (the decision the brief supersedes) is not in the working tree. Feature 0000030 emptied the archive for 0000001 to 0000029. Its text lives in git history only.
- Component / data-ownership map (`docs/`): one component, `planifest-zero` (component-pack, developer-tooling, active). Setup-config record owner today: `planifest-zero/setup.sh` and `setup.ps1`, written by `write_setup_config_override` and `Write-SetupConfigOverride`, read by `planifest-zero/skills/planifest-refresh-setup`.
- Two copies of the setup tooling exist in the tree. `planifest-zero/` is the product component. `planifest-framework/` (v0.28.1) is the dev-time framework re-added by PR #4 and runs this repo's own pipeline. Both contain the setup-config write path, the refresh-setup skill, and a test named `test-0000025-req-004-setup-config-relocation.sh`. The brief names `planifest-framework` as the component, which conflicts with 0000031 ADR 002.
- Current record on disk: `planifest-overrides/setup-config/claude-code.md`, flags `--structured-telemetry-mcp`, backend `http://localhost:3741`. The gitignored `.planifest-setup-flags` marker is absent.
- Repo instructions (`planifest-overrides/instructions/`): `custom-001-local-git-only.md` (push and PR allowed, no direct commits to main, no merging), `custom-002-prefer-subagent-decomposition.md`, `custom-003-git-up-to-date-shorthand.md`.
- Backlog (`plan/backlog/`): `0000084` test runner silently skips non-conforming files (tech debt, from 0000030). `0000085` receipt hook rejects the `orchestrator` phase name (filed this run).
