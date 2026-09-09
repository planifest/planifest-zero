# Decisions Index

> Change record. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file. Update it in place.

Last updated: 0000032-relocate-setup-config-to-plan-state

---

## Note on the reset

Feature 0000030 emptied `plan/_archive/`, so the ADR files for features 0000001 through 0000029 no longer exist in the working tree. They remain in git history.

This index restarts from 0000030. Decisions from earlier features still bind where their subject survives, but the ADR text has to be read from history.

---

## All Architecture Decision Records

### Feature 0000030: framework-cut-down

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Claude Code is the only supported tool target | accepted | Drops eight tool targets, the vendored external skill library, and the context-mode integration. Supersedes 0000001 ADR-001 to ADR-004. |

### Feature 0000031: five-phase-planifest-zero

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Five-phase pipeline contract and skill consolidation | accepted | Collapses the ten-phase pipeline to five phases (discovery, plan, implement, validate and accept, ship) and 21 skills to 12. |
| ADR-002 | Folder rename and product identity | accepted | Renames `planifest-framework/` to `planifest-zero/`, sets the `product.yml` id to `planifest-zero`, and fixes the Windows refresh script to derive its own path. |
| ADR-003 | One route: the feature pipeline | accepted | Drops the Change Pipeline and Fast Path routes. Every change runs the five-phase feature pipeline, and one CI parity check applies to every diff. |
| ADR-004 | Living docs describe the present only | accepted | Moves historical narrative to change records: `plan/changelog/`, `plan/_archive/`, ADR files, and git history. This index and `docs/about.md` carry stated exemptions. |

### Feature 0000032: relocate-setup-config-to-plan-state

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The setup-config record lives in plan/state/ | accepted | Moves the tracked setup-flags record from `planifest-overrides/setup-config/{tool}.md` to `plan/state/{tool}.md`. Supersedes 0000025 ADR-002. |
| ADR-002 | Refresh-setup reads the record before the marker | accepted | `planifest-refresh-setup` Step 3 reads `plan/state/{tool}.md` first at high confidence, falling back to the gitignored marker then hook inference. |
| ADR-003 | Setup removes the old record inline | accepted | `setup.sh` and `setup.ps1` delete the pre-relocation record at its exact path after a successful write, with no separate migration file. |

---

## Superseded

| ADR | Superseded by | Reason |
|-----|---------------|--------|
| 0000001 ADR-001 to ADR-004 | 0000030 ADR-001 | The context-mode hook design they governed no longer exists. |
| 0000025 ADR-002 | 0000032 ADR-001 | The record moved from planifest-overrides/setup-config/ to plan/state/. The ADR text is in git history only. |
