---
title: "Domain Glossary - remove-telemetry-mcp"
summary: "Definitions of domain terms used within this feature."
status: "draft"
version: "0.4.0"
---
# Domain Glossary - remove-telemetry-mcp

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000033-remove-telemetry-mcp
**Version:** 0.4.0

> The ubiquitous language for this feature. If the glossary says "Order", the code says `Order`, not "Purchase" or "Transaction". Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Telemetry hook | A Node module in `hooks/telemetry/` that emits a pipeline event to the telemetry backend. Nine modules, all deleted by this feature. | none | planifest-zero/hooks/telemetry/ |
| Enforcement hook | A Node module in `hooks/enforcement/` installed on every setup run, regardless of flags. Six survive this feature. | none | planifest-zero/hooks/enforcement/ |
| The telemetry backend | The HTTP service at `PLANIFEST_TELEMETRY_URL` that received posted events. This feature removes the only outbound call to it. | backend, backend-url | planifest-zero/hooks/telemetry/emit-event.mjs, planifest-zero/setup.sh |
| The emission gate | The `check-telemetry-receipts.mjs` enforcement hook, which cross-referenced a build-log phase's "emitted" claim against a matching receipt file before allowing the claim to stand. | receipts backstop | planifest-zero/hooks/enforcement/check-telemetry-receipts.mjs |
| The opt-in sentinel | The file `.claude/telemetry-enabled`, written by `setup.sh` when `--structured-telemetry-mcp` was passed, marking that a project had telemetry turned on. This feature deletes it wherever it survives from a prior run. | sentinel | .claude/telemetry-enabled, planifest-zero/setup.sh |
| Failure marker | A JSON file under `plan/.telemetry-failures/<slug>.json`, written when a telemetry emission failed, read by `check-telemetry-failures.mjs`. | telemetry-failure marker | planifest-zero/hooks/telemetry/record-telemetry-failure.mjs, plan/.telemetry-failures/ |
| Receipt | A JSON file under `plan/.telemetry-receipts/`, written by `emit-event-receipt.mjs` on a successful emission, read by the emission gate. | none | planifest-zero/hooks/telemetry/emit-event-receipt.mjs, plan/.telemetry-receipts/ |
| Phase enum | The ordered five-value list of pipeline phase names (`discovery`, `plan`, `implement`, `validate-and-accept`, `ship`), previously exported by `phase-enum.mjs`. This feature deletes the module and states the five names directly in `pipeline-reference.md`. | PHASE_ENUM | planifest-zero/hooks/enforcement/phase-enum.mjs, planifest-zero/pipeline-reference.md |
| Upgrade cleanup | The new setup-script behaviour, added by req-004, that strips a prior installation's telemetry wiring from an existing project on every setup run. | none | planifest-zero/setup.sh, planifest-zero/setup.ps1 |
| Shared hook module | A Node module imported by more than one hook. `read-stdin.mjs` is the shared hook module that must survive, because six surviving enforcement hooks import it. | none | planifest-zero/hooks/enforcement/read-stdin.mjs |
</content>
