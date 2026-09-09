---
title: "Scope - relocate-setup-config-to-plan-state"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "draft"
version: "0.3.0"
---
# Scope - relocate-setup-config-to-plan-state

**Skill:** [spec-agent](../../planifest-framework/skills/spec-agent-SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Version:** 0.3.0

> All three sections must be present. If "Deferred" is empty, state "Nothing deferred."

## In Scope

- `write_setup_config_override` in `planifest-zero/setup.sh` writes the tracked setup-config record to `plan/state/{tool}.md` instead of `planifest-overrides/setup-config/{tool}.md`, creating `plan/state/` when it is absent.
- `Write-SetupConfigOverride` in `planifest-zero/setup.ps1` mirrors the same change for PowerShell.
- After a successful write, both scripts delete the old `planifest-overrides/setup-config/{tool}.md` file at its exact path and remove the `setup-config/` folder if that deletion leaves it empty. Each removal prints one line. A failed removal warns and the run continues. A repeat run against an already-migrated repo prints no removal lines.
- `planifest-refresh-setup` Step 3 reads `plan/state/{tool}.md` first, at high confidence, and validates it before use. It falls back to the marker file, then to hook inference, when the record is missing, unreadable, or malformed.
- Layout docs updated to describe `plan/state/` and to drop references to `planifest-overrides/setup-config/`: `plan/README.md`, `plan/feature-structure.md`, `planifest-zero/pipeline-reference.md` (including its "never touches `planifest-overrides/`" promise), `planifest-zero/project-operations.md`.
- A superseding ADR for 0000025 ADR 002, plus a Superseded row added to `docs/decisions-index.md`.
- Test coverage: `test-0000025-req-004-setup-config-relocation.sh` rewritten to assert the new path, plus new coverage for the inline cleanup step and for `planifest-refresh-setup`'s read order.
- Scope is limited to `planifest-zero/`, the product component. `planifest-framework/` is out of scope, per the design's Engineering Layer.

## Out of Scope

- `planifest-framework/` in this repo. It is the dev-time copy that runs this repo's own pipeline and picks up this change only on its next refresh from `planifest-zero/`.
- The gitignored `.planifest-setup-flags` marker file. Its role, format, and location are unchanged.
- A migration file for the old record. Setup cleans up the old file inline on each run instead.
- PowerShell test coverage through `run-tests.sh` (tracked as backlog 0000084).
- Changing the precedence or reconciliation rules between the tracked record and the marker. The rules of 0000025 ADR 002 carry over unchanged, only the tracked file's path moves.

## Deferred

Nothing deferred.
