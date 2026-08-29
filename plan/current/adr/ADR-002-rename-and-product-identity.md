---
title: "ADR 002: Folder rename and product identity"
summary: "The component folder planifest-framework/ is renamed to planifest-zero/ to match the product and repository name. product.yml id becomes planifest-zero, restarting telemetry attribution. The stale Windows refresh script is renamed and fixed to derive its path rather than hardcode it."
status: "accepted"
version: "0.2.0"
---
# ADR-002 - Folder rename and product identity

**Skill:** adr-agent
**Feature:** 0000031-five-phase-planifest-zero
**Component:** planifest-zero
**Date:** 2026-08-30

## Context

The component folder is `planifest-framework/`, but the product and the repository are both `planifest-zero`. The literal `planifest-framework` appears 387 times across 93 files.

`product.yml` sets `id: "planifest-framework"`. That id feeds telemetry attribution: every emitted event carries it as `product_id`.

A stale refresh script, `refresh-planifest-framework-dir.ps1`, hardcodes a Windows path from a previous machine.

## Decision

Rename the folder to `planifest-zero/` with `git mv`, so file history follows the move. Update every live reference to the old name.

Historical records in `plan/_archive/` and `plan/changelog/` are not rewritten. They describe the past accurately, and the past used the old name.

`product.yml` id becomes `"planifest-zero"`. Telemetry attribution restarts under the new id. This is accepted knowingly. The telemetry stream started on 2026-08-22, so continuity spans six days of events. If continuity is wanted later, the backend can alias the two ids.

The refresh script is renamed to `refresh-planifest-zero-dir.ps1` and derives its path from `$PSScriptRoot` instead of a hardcoded literal.

The installed `.claude/` tree is untouched until setup re-runs. It contains no references to the source folder path.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the folder name | No rename cost, no history churn | Folder, product, and repository names disagree, which confuses every reference | The mismatch confuses more than the rename costs |
| Rename the folder, keep product id `planifest-framework` | Preserves telemetry continuity for existing events | Leaves a permanent id-to-name mismatch | Six days of events is not worth a permanent point of confusion |
| Rewrite historical records too | Every document uses the current name | Change records would describe the past using a name that did not exist then | A change record must describe what was true when it was written |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-zero` (formerly `planifest-framework`) | Folder renamed via `git mv`. All 387 live references across 93 files updated. `product.yml` id changes to `planifest-zero`. |
| `refresh-planifest-zero-dir` (formerly `refresh-planifest-framework-dir`) | Script renamed. Hardcoded Windows path replaced with a `$PSScriptRoot`-derived path. |
| `structured-telemetry` | `product_id` on every new event changes from `planifest-framework` to `planifest-zero`. Prior events keep their original id. |

## Consequences

**Positive:**
- Folder, product, and repository names agree, so a reference to any one of them is unambiguous.
- The refresh script works on any machine, not only the one it was written on.
- File history survives the rename intact, since `git mv` preserves it.

**Negative:**
- Telemetry dashboards see a new product id and a discontinuity at the rename point.
- Any external reference to the old folder path, outside this repository, breaks until updated.

**Risks:**
- A missed live reference could break a script or a test. The grep-sweep acceptance criterion plus the full test suite cover this, but grep coverage is not proof.
- Telemetry dashboards built against `product_id: planifest-framework` see a new id going forward. The event history involved is small, and this is accepted.

## Related ADRs

- 0000031 ADR-001 - related-to.

## Supersedes

None.

## Superseded By

None.
