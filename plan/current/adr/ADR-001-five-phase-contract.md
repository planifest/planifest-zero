---
title: "ADR 001: Five-phase pipeline contract and skill consolidation"
summary: "The framework moves from a ten-phase pipeline with 21 skills to a five-phase pipeline with 12 skills, reflecting a Claude Code-only target and a single maintainer who does not need ten separate gates."
status: "accepted"
version: "0.2.0"
---
# ADR-001 - Five-phase pipeline contract and skill consolidation

**Skill:** [adr-agent](../skills/adr-agent-SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Component:** planifest-zero
**Date:** 2026-08-30

## Context

The framework ran a ten-phase pipeline: P0 assess and coach, P1 spec, P2 ADRs, P3
codegen, P4 validate, P5 security, P6 docs, P7 archive, P8 build assessment, and
P9 ship. That pipeline used 21 skills and was built when the framework targeted
nine tools.

Since feature 0000030, the framework targets Claude Code only, for one
maintainer. The per-run context cost of loading skill text across ten phases is
significant, and the gates outnumber the decisions a solo maintainer actually
makes.

## Decision

The pipeline collapses to exactly five phases:

1. **Discovery** absorbs P0.
2. **Plan** merges P1 and P2 behind one gate.
3. **Implement** merges P3 and P6, so code, tests, and docs land together, per
   the existing hard limit that code never ships without its documentation.
4. **Validate and accept** merges P4 and P5 with the human acceptance gate.
5. **Ship** merges P7, P8, and P9.

Skills drop from 21 to 12:

- **Five-phase core (rewritten):** planifest-orchestrator, planifest-plan,
  planifest-implement, planifest-validate-and-accept, planifest-ship.
- **Surviving unchanged or trimmed:** test-writer, implementer, refactor,
  loop-runner, optimise-agent, migrator, refresh-setup.
- **Retired, content merged upward:** change-agent, spec-agent, adr-agent,
  codegen-agent, security-agent, docs-agent, verify-by-execution,
  build-assessment-agent, ship-agent, design-critic, reversal-assessor,
  scope-lock-agent.

The telemetry phase enum shrinks from seven values to five, matching the new
phase names.

**Context-cost NFR:** combined skill text must sit at or below 50% of the
current line count.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Keep ten phases, trim prose only | Lowest migration effort; no gate renumbering | Ceremony remains; still ten gates for one human | Ceremony is the cost being cut, not the prose |
| Three phases (plan, build, ship) | Maximum simplification | Folds the human acceptance gate into build; loses the distinct validation stop the maintainer wants | Removes a gate the maintainer explicitly wants to keep |
| Five phases but keep all 21 skill files | No content-merge risk | File count is itself the context cost | Does not address the stated per-run cost problem |

## Affected Components

| Component | Impact |
|---|---|
| planifest-orchestrator | Rewritten for five-phase routing |
| planifest-plan (new) | Merges P1 spec-agent and P2 adr-agent |
| planifest-implement (new) | Merges P3 codegen-agent and P6 docs-agent |
| planifest-validate-and-accept (new) | Merges P4 validate-agent, P5 security-agent, and the human acceptance gate |
| planifest-ship (new) | Merges P7 archive, P8 build-assessment-agent, P9 ship-agent |
| Telemetry backend | Phase enum shrinks from seven values to five |
| test-writer, implementer, refactor, loop-runner, optimise-agent, migrator, refresh-setup | Unchanged or trimmed, no structural change |

## Consequences

**Positive**

- Combined skill text falls to at or below 50% of the current line count,
  cutting per-run context cost.
- Five gates map to five decisions a solo maintainer actually makes, instead of
  ten.
- Skill count drops from 21 to 12, reducing files to load and maintain.

**Negative**

- Nine retired skills lose their standalone identity, so history and search
  results that reference them by name go stale.
- The merge work is a one-time cost that touches every phase boundary.

**Risks**

- Merging nine skills into five can lose a binding rule during compression.
  Mitigation: a section-to-destination map is made at plan phase, before
  implement starts.
- The external telemetry backend must accept the five new enum values.
  Mitigation: CI extends to post all five phases and fails loudly if the
  backend rejects any of them.

## Related ADRs

- 0000030 ADR-001 (Claude Code only target) - related-to. This decision builds
  directly on that scope narrowing.

## Supersedes

This ADR supersedes the ten-phase orchestration decisions in aggregate. Those
decisions were established across features 0000001 through 0000029. Their ADR
files were cleared from the working tree at feature 0000030 and no longer exist
as live documents. They remain readable in git history; this ADR supersedes
them by pointer to that history rather than by pointer to a live file.

## Superseded By

None.
