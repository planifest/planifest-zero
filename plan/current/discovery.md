---
title: "Discovery - 0000031-five-phase-planifest-zero"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000031-five-phase-planifest-zero

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | Priority 2. `plan/_archive/` holds one feature directory and `docs/about.md` exists. No `planifest-overrides/instructions/external-versioning.md`, so priority 1 does not apply. |
| Git pre-flight | Branch was `main`, clean, level with `origin/main` at `8e45613`. Human confirmed all prior PRs merged. Working branch `feat/0000031-five-phase-planifest-zero` created from that commit. |
| Skills inbox | Empty. Only `.gitkeep` under `planifest-framework/skills-inbox/`. |

## Mode Findings

### Standard Iterative

- **Current version (`docs/about.md`):** `0.1.0`, set by feature 0000030 on 22 Aug 2026. `product.yml` agrees and carries `versionPolicy: max-component-version` with one component.

- **Declared product id:** `planifest-framework`. Present and non-empty, so the ADR-002 hard stop does not fire. The requested folder rename puts this value in question, since telemetry attributes events by it.

- **Prior features (`plan/_archive/`):** one directory.
  - `0000030-framework-cut-down-2026-08-22`. Reduced the repo to a Claude Code only framework, deleted the two `src/` components, removed every element of context-mode, deleted the vendored external skill library, and cleared the accumulated plan and docs history. Version reset from 0.28.1 to 0.1.0 under an explicit human override. Ran the Change Pipeline route.
  - Features 0000001 to 0000029 were emptied from the archive by that run. They remain in git history only.

- **Constraining ADRs (unless superseded):**
  - `0000030 ADR-001`, Claude Code is the only supported tool target. Accepted. Supersedes `0000001` ADR-001 to ADR-004. Binding on this feature, which does not reintroduce any tool target.
  - No other ADR text exists in the working tree.

- **Component and data-ownership map (`docs/`):** one active component, `planifest-framework`, typed `component-pack` in the developer-tooling domain. It owns the standards, skills, hooks, templates, schemas, and both setup scripts. `src/` holds an empty scaffold with a README. `context-mode-hooks` and `setup-hook-integration` were removed at 0000030 and are recoverable from git history only.

## Signals specific to this feature

Recorded here because they size the requested work and were read before coaching began.

- **Rename blast radius.** The literal `planifest-framework` appears 387 times across 93 files. Heaviest: `planifest-framework/tests/` (28 files), `planifest-framework/skills/` (16), `plan/backlog/` (9), `planifest-framework/migrations/` (6), `plan/_archive/` (5). It also appears in `product.yml`, the root `README.md`, and `refresh-planifest-framework-dir.ps1`. It does **not** appear in `.claude/settings.json`: the installed hook commands all resolve under `.claude/hooks/`, so the live session is insulated from the rename until `setup.sh` re-runs.

- **Phase contract.** `hooks/enforcement/phase-enum.mjs` holds seven values: spec, adr, codegen, validate, security, docs, ship. P0 has no enum value by design. Three consumers derive from it: `check-telemetry-receipts.mjs`, `resolve-phase.mjs`, and `emit-event-receipt.mjs`. `standards/telemetry-standards.md` is the stated source of truth for the values.

- **External telemetry dependency.** The CI job `validate-telemetry-schema` in `.github/workflows/planifest.yml` posts a live `phase_start` event for phase `ship` to `PLANIFEST_TELEMETRY_URL`. The endpoint is outside this repository. It exits 0 silently when the secret is unset.

- **Workflows present.** `planifest-framework/workflows/` holds `feature-pipeline.md`, `change-pipeline.md`, `fast-path.md`, and `retrofit.md`. The request removes all routes except feature change.

- **Context-mode residue.** Feature 0000030 removed context-mode. What remains is `hooks/telemetry/context-pressure.mjs`, ruled unrelated at 0000030 despite the shared name prefix, and guard tests that assert context-mode is absent by name.

- **Repo instructions (`planifest-overrides/instructions/`):** three files.
  - `custom-001-local-git-only.md`. Grants fetch, pull, push, and `gh pr create` without per-use approval. Reserves direct commits to `main` and PR merges to the human. Requires granular, continuous commits. Its filename says local-git-only while its content authorises remote operations, and the ship-agent branches on a `local-git-only` signal.
  - `custom-002-prefer-subagent-decomposition.md`. Default to parallel subagent decomposition for multi-unit work.
  - `custom-003-git-up-to-date-shorthand.md`. Defines the GUTD shorthand.

- **Setup config.** `planifest-overrides/setup-config/claude-code.md` is present.

- **Backlog.** Ten open entries, `0000075` through `0000084`, all filed 29 Aug 2026 from a review of feature 0000030. Four overlap this feature's stated scope: `0000078`, `0000079`, `0000080`, and `0000083` cover stale references and documentation drift; `0000081` asks for the skills to be trimmed to the surviving phases.

- **Pending migrations:** none. `planifest-framework/migrations/` holds only `_done/` and the two archive-dirname scripts.

- **Telemetry failure markers:** none under `plan/.telemetry-failures/`.

- **Telemetry signal:** active. `.planifest-setup-flags` records `--structured-telemetry-mcp` with backend `http://localhost:3741`, written 2026-08-22. The `.claude/telemetry-enabled` marker is present and the installed hook commands carry `PLANIFEST_TELEMETRY_URL`.
