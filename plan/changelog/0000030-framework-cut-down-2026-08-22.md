# Changelog: 0000030-framework-cut-down

**Date:** 22 Aug 2026
**Route:** Change Pipeline
**Component:** `planifest-framework`
**Version:** 0.28.1 → 0.1.0

---

## What changed

This build reduced the repo to a Claude Code only framework and cleared its accumulated history.

### Deleted

- `planifest-framework/external-skills/`, over 400 vendored third-party skills.
- `src/context-mode-hooks/` and `src/setup-hook-integration/`, both components, and their `product.yml` entries.
- Eight non-Claude setup script pairs: antigravity, cline, codex, copilot, cursor, opencode, roo-code, windsurf.
- All six hook adapters under `planifest-framework/hooks/adapters/`.
- `.cursorignore`, `.clineignore`, `.windsurfignore`, `.cursorindexingignore`, `tool-setup-reference.md`, `templates/cursor-boot.md`.
- Every element of context-mode: `hooks/context-mode/`, the `--context-mode-mcp` flag in both setup scripts, `docs/context-mode.md`, the coupling tests, and all doc references.
- `scripts/skill-sync.sh` and `.ps1`, plus the `--include-full-skill-library` flag and the `add-skill` subcommand family.

### Emptied

`plan/_archive/` (30 runs), `plan/backlog/` (23 entries), `plan/changelog/` (60 files), and `docs/` (8 files). Each folder kept a `.gitkeep`.

### Rewritten

- `README.md`, describing the cut-down framework rather than a tool-agnostic one.
- `product.yml`, one component, version 0.1.0.
- `planifest-framework/component.yml`, rewritten rather than patched. It carried 288 lines of per-feature history about a nine-tool framework.
- `docs/`: component-registry, dependency-graph, decisions-index, architecture-overview, and about, all rebuilt.

### Script reductions

| Script | Before | After |
|--------|-------:|------:|
| `setup.sh` | 1557 | 1104 |
| `setup.ps1` | 1528 | 1092 |

---

## Reason

The framework supported nine tool targets but only Claude Code was in use. Roughly a third of `setup.sh` existed to branch by tool tier. Commit 6a50af1 had already dropped context-mode from the boot templates, leaving `--context-mode-mcp` installing hooks nothing else referenced.

Full rationale and the alternatives considered: [ADR-001](../_archive/0000030-framework-cut-down-2026-08-22/adr/ADR-001-claude-code-only-target.md).

---

## Deviations from the confirmed design

Three items went beyond the eight in `design.md`, each recorded here rather than left silent:

1. **Skill sync removed.** Deleting `external-skills/` left `--include-full-skill-library` and `skill-sync.sh` with no source. The human confirmed removing both mid-build, since a flag that silently does nothing repeats the context-mode defect.
2. **`component.yml` rewritten, not patched.** Scope item 8 asked only for a version reset. The manifest described deleted components, a Copilot adapter, and Tier 1 install paths, which breaks the rule that documentation matches reality.
3. **`src/` scaffold restored.** `initialize_repo` recreates `src/` with a README on every setup run. Tracking the empty scaffold keeps the working tree clean. The two components are still gone.

---

## Version override

The orchestrator hard-blocks a version lower than the last known one. Last known was `0.28.1` and this build wrote `0.1.0`.

The human on the loop cleared the block explicitly. The same build emptied `plan/_archive/` and rewrote `docs/about.md` and `product.yml`, so the version history was deleted rather than contradicted.

---

## Route note

The human first selected the Fast Path. Fast Path was rejected at its own gate: this change edits `setup.sh` install logic, deletes two components, and rewrites `product.yml`, so none of its four criteria hold. The build ran through the Change Pipeline instead.

---

## Validation

Framework test suite: 51 feature suites and 20 regression suites, zero failures.

The sweep deleted `test-0000017-req-004-cross-platform-hooks.sh` and its regression copy, pruned both from `regression-manifest.json`, and cut the external-skills, Tier 1, opencode, and Copilot sections from the suites that survived.

`setup.sh claude-code --structured-telemetry-mcp` re-ran clean, exit 0, with the telemetry presence check passing 4 of 4 hooks.

---

## Left as-is by decision

- `.github/workflows/planifest.yml`. Its fast-path branch still requires `plan/changelog/`, which now holds one file.
- `refresh-planifest-framework-dir.ps1`. Still hardcodes `C:\d\planifest\framework\`. Its flags were corrected.
- The 21 pipeline skills. Trimming them to the phases this framework keeps is a separate build.
