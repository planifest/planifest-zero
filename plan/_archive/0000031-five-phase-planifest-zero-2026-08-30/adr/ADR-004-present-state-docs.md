---
title: "ADR 004: Living docs describe the present only"
summary: "Living documentation describes the current system only. Historical narrative moves exclusively to change records: plan/changelog/, plan/_archive/, ADR files, and git history. docs/decisions-index.md and docs/about.md carry stated exemptions."
status: "accepted"
version: "0.2.0"
---
# ADR-004 - Living docs describe the present only

**Skill:** adr-agent
**Feature:** 0000031-five-phase-planifest-zero
**Component:** planifest-zero
**Date:** 2026-08-30

## Context

Living documentation has accumulated historical narrative over time. `docs/component-registry.md` carries "Removed at 0000030" tables. Standards and skills carry "introduced in feature NNNN" asides. `docs/dependency-graph.md` carries tier-history notes.

A reader cannot tell current truth from archaeology without cross-checking every claim against its origin.

The human's rule is direct: docs reference the present. Anecdotal when-it-was-introduced information belongs only in change records.

## Decision

Living documentation describes the present system only. This covers `docs/`, README files, `standards/`, `skills/`, `templates/`, `workflows/`, and getting-started and reference docs.

Historical narrative lives exclusively in change records: `plan/changelog/`, `plan/_archive/`, ADR files themselves, and git history.

Two exemptions apply, stated explicitly:

- `docs/decisions-index.md` is by nature an index of decisions across features, so it is treated as a change record and keeps its historical entries.
- `docs/about.md` keeps its version field, which is the live version record, and a feature field that points to the change that produced that version.

Code comments may keep short req/ADR citation tags where they cite a binding decision, such as a constraint that would otherwise look arbitrary. Narrative history sentences do not belong in code comments either.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep history inline with a "History" section per doc | No separate lookup needed, context stays local | Sections grow forever and duplicate the changelog | Duplication compounds with every feature; the changelog is the single source already |
| Delete history entirely, including changelogs | Simplest documents, no historical clutter anywhere | Provenance of decisions becomes unrecoverable | Decisions must stay traceable to why they were made |
| Automatic doc generation from manifests | Docs and manifests never drift apart | Tooling cost exceeds the benefit for one component | Not justified yet at this component count |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-zero` docs | `docs/component-registry.md`, `docs/dependency-graph.md`, and other living docs lose "Removed at", "introduced in feature", and tier-history narrative. |
| `planifest-zero` standards and skills | "Introduced in feature NNNN" asides removed from prose. |
| `docs/decisions-index.md` | Exempt. Keeps its cross-feature decision history. |
| `docs/about.md` | Exempt for its version field and feature pointer field only. |

## Consequences

**Positive:**
- A reader of any living doc sees only what is true now, with no need to check when a fact was introduced.
- Provenance stays recoverable through `plan/changelog/`, `plan/_archive/`, ADRs, and git history.
- Docs shrink, since repeated "as of feature NNNN" asides are removed.

**Negative:**
- A reader who wants the history of a decision must leave the living doc and open the changelog or the relevant ADR.
- Existing docs need a one-time rewrite pass to strip accumulated narrative.

**Risks:**
- An operationally useful fact could be removed by mistake under the label of "history". Mitigated: the validate-and-accept phase audits the rewritten docs, and git history retains all removed text.
- Future contributors could reintroduce narrative out of habit. Mitigated: the implement skill's docs rules state this policy directly.

## Related ADRs

- 0000031 ADR-002 - related-to. Historical records are exempt from the rename sweep for the same reason they are exempt here: a change record must describe what was true when it was written.

## Supersedes

None.

## Superseded By

None.
