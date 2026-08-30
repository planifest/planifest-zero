# Changelog: 0000031-five-phase-planifest-zero

**Date:** 30 Aug 2026
**Route:** Feature Pipeline
**Component:** `planifest-zero`
**Version:** 0.1.0 → 0.2.0

---

## What changed

This build renamed the framework folder to match the product, collapsed the ten-phase pipeline into five phases, and made the feature pipeline the only route.

### Renamed

- `planifest-framework/` became `planifest-zero/` via `git mv`. 78 live files swept for the old name. Historical records in `plan/_archive/` and `plan/changelog/` keep their original text.
- `product.yml` id became `planifest-zero`. Telemetry attribution restarts under the new id.
- `refresh-planifest-framework-dir.ps1` became `refresh-planifest-zero-dir.ps1` and derives its path from `$PSScriptRoot` instead of a hardcoded machine path.

### The five-phase contract

- Phases: discovery, plan, implement, validate-and-accept, ship. Prefixes `D:`, `PL:`, `IM:`, `VA:`, `SH:`. Build-log headings `### P<n>: {Name}`, n 1 to 5.
- 21 skills became 12. New core: rewritten orchestrator (372 lines) plus planifest-plan, planifest-implement, planifest-validate-and-accept, planifest-ship. Surviving: the TDD trio, loop-runner, optimise-agent, migrator, refresh-setup. Thirteen skill folders deleted.
- Skill text: 2,895 lines became 1,315, inside the 50% budget.
- The telemetry phase enum shrank from seven values to five. `phase-enum.mjs`, its three consumers, and `telemetry-standards.md` agree. The CI schema guard posts all five names.

### Single route

- `workflows/change-pipeline.md`, `workflows/fast-path.md`, and `workflows/retrofit.md` deleted. `feature-pipeline.md` rewritten as the sole route. The retrofit scan lives in the orchestrator's discovery text.
- The CI fast-path exemption branch deleted from both workflow copies, closing its weaker parity check.

### Kept

- Both setup scripts, functionally intact for `claude-code` with and without `--structured-telemetry-mcp`, now pruning retired skills from `.claude/skills/` on regeneration.
- The `planifest-overrides/` mechanism, unchanged in function.
- The whole telemetry hook family, including `context-pressure.mjs`, confirmed as genuine telemetry with its stale flag reference removed.

### Docs

All living documentation rewritten to present state only. History lives in change records: `plan/changelog/`, `plan/_archive/`, ADR files, and `docs/decisions-index.md`. Folded backlog fixes: stale `.gitignore` patterns removed from both files, the tests README rewritten for one tool, `plan/feature-structure.md` rewritten around `plan/current/`, the spent `plan/library-standards-plan.md` deleted, the never-run `test_setup` pair deleted, and the dead `.gitattributes` line removed.

---

## Reason

The framework carried a nine-tool, ten-phase past. One maintainer, one tool, one route needed far less. Full rationale: the four ADRs in the archive for this feature.

---

## Deviations from the confirmed design

1. **Three compressed rules restored.** The skill merge dropped the orchestrator push cadence, the ship-phase version derivation via `product-version.mjs`, and the canonical commit phrase in the plan skill. All three were restored during the test sweep.
2. **Consistency-check finding accepted.** All six requirements exceed three acceptance criteria. The human confirmed the six-story single-run design at discovery, so the build was not re-split. The new plan skill makes this check a gate for future runs.
3. **LOW-001 fixed in-run.** The security review found the new skill pruning would follow a planted symlink. Both setup scripts now skip symlinks and junctions.
4. **`test-0000031-req-005` renamed** to `test-0000031-req-005-telemetry-only-mcp.sh` so the purge target string does not live in a filename.

---

## Validation

52 feature suites and 20 regression files pass with zero failures, including six new suites, one per requirement. Setup verified by execution in fresh temp clones, both flag states, including prune behaviour. Self-description check passes. Skill text budget met with 132 lines to spare.

Deferred to the backlog: nothing new. Backlog 0000084 (test-runner silent skip) remains open.

---

## Left as-is by decision

- The telemetry backend at the configured URL must accept the five new phase values. The CI guard fails loudly if it does not. The backend is outside this repository.
- The installed `.claude/` tree still runs the old contract until setup re-runs after merge.
