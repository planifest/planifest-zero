---
title: "Discovery - 0000033-remove-telemetry-mcp"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000033-remove-telemetry-mcp

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds three feature directories and `docs/about.md` exists. No `planifest-overrides/instructions/external-versioning.md`. |
| Git pre-flight | PR #5 was open at pre-flight. The human merged it. Checked out `main`, pulled to e1b6244, branched `feat/0000033-remove-telemetry-mcp`. Tree clean, no untracked files. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md` and `product.yml`): `0.3.0`. Product id `planifest-zero`, policy `max-component-version`.
- Prior features (`plan/_archive/`):
  - `0000030-framework-cut-down-2026-08-22`: Claude Code only target, history cleared, v0.1.0.
  - `0000031-five-phase-planifest-zero-2026-08-30`: five phases, one route, folder renamed, v0.2.0.
  - `0000032-relocate-setup-config-to-plan-state-2026-09-05`: setup record moved to `plan/state/`, v0.3.0.
- Constraining ADRs (unless superseded):
  - 0000030 ADR 001: Claude Code is the only supported tool target.
  - 0000031 ADR 001: five-phase pipeline contract.
  - 0000031 ADR 003: one route, the feature pipeline. So this run takes a minor bump.
  - 0000031 ADR 004: living docs describe the present only.
  - 0000032 ADR 001 to 003: the setup record lives at `plan/state/{tool}.md`, refresh-setup reads it first, setup removes the legacy record inline. This feature edits the same setup functions, so it must not regress them.
- Repo instructions (`planifest-overrides/instructions/`): `custom-001-local-git-only.md` (push and PR allowed, no direct commits to main, no merging), `custom-002-prefer-subagent-decomposition.md`, `custom-003-git-up-to-date-shorthand.md`.
- Backlog (`plan/backlog/`): `0000084` test runner silent skips, `0000086` two suites fail while `planifest-framework/` exists, `0000088` loose tool-name check, `0000089` repo record path. Entry `0000085` (receipt hook rejects the orchestrator phase name) was discarded at this P0: it describes a hook this feature deletes.

## Telemetry Surface in planifest-zero

A read-only survey mapped every telemetry reference inside `planifest-zero/`. `planifest-framework/`
keeps its telemetry and is out of scope.

**Files that exist only for telemetry, 34 in total.**

- `hooks/telemetry/`, 9 modules: `emit-event`, `emit-phase-start`, `emit-phase-end`,
  `emit-event-receipt`, `context-pressure`, `resolve-phase`, `record-telemetry-failure`,
  `read-product-id`, `get-flag-path`.
- `hooks/enforcement/check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs`. Both sit in
  the enforcement folder but serve telemetry only.
- `scripts/verify-telemetry-hooks.mjs`, `standards/telemetry-standards.md`,
  `tests/helpers/controllable-backend.mjs`.
- 15 test suites under `tests/` and 5 copies under `tests/regression/`.

**Files needing surgical edits, roughly 45.**

- `setup.sh`, 1166 lines, ten distinct telemetry blocks. Three whole functions delete cleanly
  (`merge_telemetry_hook_settings`, `verify_telemetry_hooks_installed`, `install_telemetry_hooks`).
  The rest is interleaved: flag defaults, argument parsing, usage text, the sentinel write, and the
  flags arrays inside `write_setup_config_override` and `write_setup_flags_marker`.
- `setup.ps1`, 1143 lines, the same shape mirrored.
- `setup/claude-code.sh` and `setup/claude-code.ps1`, three lines each.
- `component.yml`, about a dozen scattered edits across purpose, interfaces, inventories, and risks.
- 12 skill files. Six carry a `## Telemetry` section and bundle `telemetry-standards.md`. All 12
  carry a `hooks: phase:` frontmatter key that no code reads.
- Docs: `pipeline-reference.md`, `project-operations.md`, `getting-started.md`, `tests/README.md`.
- Templates: `build-log.template.md` (the per-phase `Telemetry` row and the summary count) and
  `standard-boot.md` (one bullet).
- 19 mixed test suites plus `tests/regression/regression-manifest.json`, which registers five
  telemetry entries and carries a "do not edit manually" notice.

**Shared modules that must survive.**

- `hooks/enforcement/read-stdin.mjs` is imported by six surviving enforcement hooks and by seven
  deleted telemetry hooks. Keep it. Its header comment argues the enforcement and telemetry install
  tiers, so the comment needs rewriting.
- `hooks/enforcement/phase-enum.mjs` loses all three of its importers, because every one of them is
  a telemetry hook. `pipeline-reference.md` and `test-0000031-req-003-five-phases.sh` treat it as
  the canonical five-phase source of truth. Its fate is an open decision.

The dependency direction is strictly one way. No surviving enforcement hook imports anything from
`hooks/telemetry/`, so deleting that folder is safe as long as the two shared modules stay.

**The MCP server is never registered.** Setup writes no `mcpServers` block and no `.mcp.json`. The
server appears only as a hook matcher string, `mcp__structured-telemetry-mcp__emit_event`, written
into `.claude/settings.json` at three points in `setup.sh` and one in `setup.ps1`.
`getting-started.md` carries the only outbound link to the server project.

**Riskiest edits identified by the survey.**

1. `install_enforcement_hooks` in `setup.sh` and `Merge-EnforcementHookSettings` in `setup.ps1`. The
   two telemetry entries are interleaved with six surviving enforcement hooks in the same array
   build and the same de-duplication filter.
2. `phase-enum.mjs`, which becomes orphaned while remaining the documented phase vocabulary.
3. `skills/planifest-orchestrator/SKILL.md`, where Hard Limit 9 makes a blank build-log `Telemetry`
   field a pipeline error, and the `product.yml` id hard stop is justified only by telemetry.
