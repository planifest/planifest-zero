---
title: "ADR 003: The phase vocabulary lives in prose, not in a module"
summary: "hooks/enforcement/phase-enum.mjs is deleted and pipeline-reference.md states the five phase names directly. The product.yml top-level id field and the orchestrator's product-id hard stop go with it, because telemetry was their only consumer."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - The phase vocabulary lives in prose, not in a module

**Skill:** [adr-agent](../../../.claude/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Component:** planifest-zero
**Date:** 2026-09-10

## Context

Two artifacts in Zero exist to serve telemetry but do not look like telemetry, so ADR-001 does not
obviously cover them. Both need a stated decision.

**`hooks/enforcement/phase-enum.mjs`** exports four values: `PHASE_ENUM`, `KNOWN_PHASES`,
`PHASE_NUMBER_TO_ENUM`, and `PHASE_SKILLS`. It was extracted so telemetry hooks could agree on phase
names without duplicating a list. Its three importers are `emit-event-receipt.mjs`,
`resolve-phase.mjs`, and `check-telemetry-receipts.mjs`. ADR-001 deletes all three. The file lives in
`hooks/enforcement/` rather than `hooks/telemetry/` only because one of its importers did, and its
header comment is an argument about install tiers. Meanwhile `pipeline-reference.md` calls it the
canonical enum, and a test asserts its contents.

**`product.yml`'s top-level `id` field** was added by feature 0000024 so telemetry events stayed
attributable to one product across clones and machines. The orchestrator hard-stops at discovery
when the field is missing, and the prompt it shows cites telemetry as the reason. The only readers
are the telemetry hooks. The version script reads `components[].id`, which is a different field.

## Decision

1. Delete `hooks/enforcement/phase-enum.mjs`. Every one of its four exports is consumed only by files
   ADR-001 deletes.
2. `pipeline-reference.md` states the five phase names directly in prose: `discovery`, `plan`,
   `implement`, `validate-and-accept`, `ship`. It no longer names a module as their source.
3. The pipeline contract itself is unchanged. The five phases are defined by the twelve skills and
   the pipeline documentation, which is where a reader looks for them.
4. Remove the top-level `id` field from `product.yml` and from `templates/product.template.yml`.
5. Remove the orchestrator's product-id hard stop. Discovery no longer asks for the field.
6. `components[].id` stays. `scripts/product-version.mjs` reads it to resolve each component's
   manifest, and versioning is unaffected.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `phase-enum.mjs` as a machine-readable vocabulary with no importers | Something later might want it | A module nothing imports invites the next reader to wire something to it, and its whole header comment argues a telemetry concern that no longer exists | Dead code with a misleading rationale |
| Move the enum somewhere non-telemetry and keep it | Preserves a single machine-readable source | Nothing in Zero reads phase names programmatically once telemetry goes. The pipeline is executed by agents reading skills | Solves a problem no surviving code has |
| Keep the product-id hard stop with a new justification | Preserves a stable product identity for humans | The gate refuses to start work until a person answers. That is justified only when something downstream cannot proceed, and nothing now consumes the value | A hard stop with no consumer trains people to distrust the other gates |
| Keep `id` as an optional documented field, drop only the hard stop | Costs nothing, names the product for humans | Leaves a field no code reads and no process requires, which is the same dead weight one level down | The human chose to drop the field entirely |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-zero (hooks) | `phase-enum.mjs` is deleted. `read-stdin.mjs` survives, with its telemetry-tier header comment corrected. |
| planifest-zero (`pipeline-reference.md`) | States the five phase names directly instead of citing a module. |
| planifest-zero (orchestrator skill) | Discovery step 9's product-id hard stop is removed. |
| planifest-zero (`templates/product.template.yml`) and root `product.yml` | Lose the top-level `id` field. `components[]` is unchanged. |
| planifest-zero (tests) | `test-0000031-req-003-five-phases.sh` is rewritten, not deleted. Two of its five sections must survive. |

## Consequences

**Positive:**
- The five phase names live where a person reads them, and no module claims an authority nothing exercises.
- Discovery stops blocking a run to collect a value nothing consumes.

**Negative:**
- Nothing mechanically enforces that the five phase names stay consistent across the skills and the docs. A rewritten test asserting the documented list is the only check.
- A repository can now carry a `product.yml` with no product name at all, so the file identifies its components without naming the product they form.

**Risks:**
- A future feature wanting machine-readable phase names must reintroduce the list. The rewritten test at least pins the documented names, so the two cannot drift silently.

## Related ADRs

- ADR-001 - depends-on (the removal that orphans both artifacts)
- ADR-002 - related-to (both concern what the removal leaves behind)
- 0000031 ADR 001 - related-to (the five-phase contract, unchanged by this decision)
- 0000031 ADR 004 - depends-on (living docs describe the present, so prose is the right home)

## Supersedes

- 0000024's product-id decision as it applies to `planifest-zero`. Its ADR lives in git history, and telemetry attribution was its only stated purpose.

## Superseded By

- None
