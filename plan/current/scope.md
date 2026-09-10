---
title: "Scope - remove-telemetry-mcp"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "draft"
version: "0.4.0"
---
# Scope - remove-telemetry-mcp

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Wave:** not waved
**Version:** 0.4.0

> All three sections must be present. If "Deferred" is empty, state "Nothing deferred."

## In Scope

- Delete `planifest-zero/hooks/telemetry/` in full: `emit-event.mjs`, `emit-phase-start.mjs`, `emit-phase-end.mjs`, `emit-event-receipt.mjs`, `context-pressure.mjs`, `resolve-phase.mjs`, `record-telemetry-failure.mjs`, `read-product-id.mjs`, `get-flag-path.mjs`.
- Delete `planifest-zero/hooks/enforcement/check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs`.
- Delete `planifest-zero/hooks/enforcement/phase-enum.mjs`. All three of its importers are telemetry hooks that this feature also deletes.
- Delete `planifest-zero/scripts/verify-telemetry-hooks.mjs`, `planifest-zero/standards/telemetry-standards.md`, and `planifest-zero/tests/helpers/controllable-backend.mjs`.
- Delete the 15 telemetry-only test suites under `planifest-zero/tests/` and the 5 copies under `planifest-zero/tests/regression/`.
- Remove every telemetry block from `planifest-zero/setup.sh`: the `--structured-telemetry-mcp` and `--backend-url` flag defaults and argument parsing, the usage text, the three telemetry-only functions (`merge_telemetry_hook_settings`, `verify_telemetry_hooks_installed`, `install_telemetry_hooks`), the `.claude/telemetry-enabled` sentinel write, and the two telemetry entries inside `install_enforcement_hooks`.
- Remove the mirrored blocks from `planifest-zero/setup.ps1`, including its `Merge-EnforcementHookSettings` function's two telemetry entries.
- Remove the telemetry hook path variables from `planifest-zero/setup/claude-code.sh` and `planifest-zero/setup/claude-code.ps1`.
- Add upgrade cleanup to both setup scripts, run on every setup invocation: remove telemetry hook entries from the project's `.claude/settings.json`, delete `.claude/telemetry-enabled`, and delete `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` when present. Print one line per removal. Warn without failing on a removal error. Stay silent when nothing is present.
- Remove the top-level `id` field from `product.yml` and `planifest-zero/templates/product.template.yml`. Drop the orchestrator's product-id hard stop. `components[].id` stays, because the version script reads it.
- Remove the `## Telemetry` section and the `telemetry-standards.md` bundle reference from the six skills that carry them, and the `hooks: phase:` frontmatter key from all twelve skills.
- Remove the `Telemetry` row from `planifest-zero/templates/build-log.template.md` and the summary's telemetry-gap count. Remove the telemetry clause from the orchestrator's build-log Hard Limit while keeping the phase block mandatory.
- Update `planifest-zero/pipeline-reference.md` to state the five phase names directly, plus `project-operations.md`, `getting-started.md`, `tests/README.md`, `templates/standard-boot.md`, and `component.yml`.
- Edit the 19 mixed test suites under `planifest-zero/tests/` to drop their telemetry assertions while keeping every other assertion. Remove the five telemetry entries from `planifest-zero/tests/regression/regression-manifest.json`.

## Out of Scope

- `planifest-framework/` in this repository. It keeps its telemetry and runs this repository's own pipeline.
- Any replacement telemetry, extension seam, or documented hook attachment point. This feature ships nothing about telemetry.
- `planifest-zero/hooks/enforcement/read-stdin.mjs` and the six surviving enforcement hooks (`gate-write.mjs`, `check-design.mjs`, `ratchet-check.mjs`, `em-dash-guard.mjs`, `auto-trigger-orchestrator.mjs`, `check-orchestrator-presence.mjs`). Their behaviour does not change. Only telemetry wording in their comments is corrected.
- The five phase names and the pipeline contract from 0000031 ADR 001.

- `.github/workflows/planifest.yml`, this repository's own CI. Its `validate-telemetry-schema` job
  guards the telemetry of the `planifest-framework/` copy, which this feature does not touch. The
  workflow that setup ships to consumers, `planifest-zero/hooks/planifest.yml`, already carries no
  telemetry.

## Deferred

Nothing deferred.
</content>
