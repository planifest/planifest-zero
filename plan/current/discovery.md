---
title: "Discovery - 0000164-hardening-and-backlog-skill"
summary: "Raw discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000164-hardening-and-backlog-skill

> Raw findings only. Decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 16 prior runs and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000164-hardening-and-backlog-skill` cut from `main` at `6993fbf`. `main` matches `origin/main`. |
| Skills inbox | `ravintio-zero/skills-inbox/` holds only `.gitkeep` |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `1.0.0`, from 0000160.
- `releaseSize` is absent from `product.yml`, so the budget is `medium` (8 points).
- Prior features (`plan/_archive/`): the most recent are 0000151 (hardening, token efficiency, and faster CI) and 0000160 (the RAVINTIO rebrand).
- Constraining ADRs:
  - 0000033 ADR-002: setup retracts legacy telemetry wiring on every run.
  - 0000151 ADR-007: setup prunes retired hooks by list. That list is `TELEMETRY_HOOK_MODULES` in `setup.sh` and `$TelemetryHookModules` in `setup.ps1`.
  - 0000151 ADR-002: hook block reasons go to both stderr and the JSON reason.
  - 0000037 ADR-001: the repo self-hosts. `core.hooksPath` points at `ravintio-zero/hooks`.
- Component map: one component, `ravintio-zero` (`ravintio-zero/component.yml`). No component owns data.
- Repo instructions (`ravintio-overrides/instructions/`): `custom-001` to `custom-005`.
- Pending migration `0004-ravintio-rename.md` does not apply. This repo is the pack source.
- Strict mode is on (`plan/.orchestrator-strict`).

## Backlog findings

### 0000162: gate-write outside the project

- `ravintio-zero/hooks/enforcement/gate-write.mjs` keeps an absolute path as `relTarget` when the target is outside `cwd`. Check 2 or Check 3 then blocks it.
- The installed copy sits at `.claude/hooks/enforcement/gate-write.mjs`. It is untracked and setup writes it.
- Existing tests: `ravintio-zero/tests/test-gate-write-windows.mjs` and `.sh`.

### 0000161: Bash 3.2 process substitution

- Five files under `ravintio-zero/tests/` still use `done < <(...)`, matching the entry's list.

### 0000095: telemetry cleanup

- `setup.sh` `remove_legacy_telemetry_wiring` and `setup.ps1` `Remove-LegacyTelemetryWiring` remove three things: settings entries, the `.claude/telemetry-enabled` sentinel, and the `plan/.telemetry-*` marker folders.
- The module list behind that cleanup is also the retired-hooks list from 0000151 ADR-007. Retiring the cleanup must keep or move that list.
- About 20 test files mention telemetry. The 0000033 and 0000041 suites test the cleanup directly.

### 0000163: backlog-filing skill

- Pack skills live in `ravintio-zero/skills/ravintio-*`. Setup installs them under `.claude/skills/`.
- The skills catalogue is `.claude/skills/ravintio-orchestrator/references/orchestrator-skills-catalogue.md`, installed from the pack.
- The backlog template is `ravintio-zero/templates/backlog-entry.template.md`.
