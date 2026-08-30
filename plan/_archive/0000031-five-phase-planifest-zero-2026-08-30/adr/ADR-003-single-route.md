---
title: "ADR 003: One route: the feature pipeline"
summary: "The framework drops the Change Pipeline and Fast Path routes. Every change, however small, runs the five-phase feature pipeline, and the CI fast-path exemption branch is deleted so one parity check applies to every diff."
status: "accepted"
version: "0.2.0"
---
# ADR-003 - One route: the feature pipeline

**Skill:** [adr-agent](../skills/adr-agent-SKILL.md)
**Feature:** 0000031-five-phase-planifest-zero
**Component:** planifest-zero
**Date:** 2026-08-30

## Context

The framework routed work three ways. The Feature Pipeline ran the full set of
phases. The Change Pipeline handled targeted changes to one or two components.
Fast Path covered UI copy, styling, isolated pure-function fixes, and
dependency bumps.

Three routes needed a triage decision tree, per-route gate criteria, a
change-agent skill, and three workflow docs. Fast Path also carried a CI
exemption branch that applied a weaker parity check to fast-path commits,
checking only `component.yml` or `plan/changelog/` instead of `plan/`, `docs/`,
or `component.yml`.

The human decided that everything is a feature change going forward, with no
other options.

## Decision

The framework deletes the Change Pipeline route, the Fast Path route, and the
Retrofit workflow file. Every change, however small, runs the five-phase
feature pipeline. A small change is a small run through that pipeline, not a
different route.

The retrofit codebase-scan content survives as a short subsection of the
orchestrator's discovery text. Adoption modes remain, in reduced form.

`skills/planifest-change-agent` is deleted.

The CI fast-path exemption branch is deleted, so one parity check applies to
every diff. That check requires `plan/`, `docs/`, or `component.yml` on every
change, with no weaker path. The change is mirrored into the shipped
`hooks/planifest.yml` consumer copy.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|---|---|---|---|
| Keep Fast Path for one-line fixes | Skips ceremony for trivial edits | Its gate criteria plus exemption branch cost more text than the ceremony it saved; the weaker CI check was a standing hole flagged by a previous review (backlog entry 0000082) | The maintenance cost of the shortcut exceeded the ceremony it removed |
| Keep the Change Pipeline only | One fewer route than three | Two routes still need a triage tree and two gate sets | Two routes carry most of the routing cost of three |
| Route by diff size automatically | Removes human triage | Deterministic heuristics on diff size misroute contract changes that happen to be small | Diff size does not predict the risk of a change |

## Affected Components

| Component | Impact |
|---|---|
| planifest-orchestrator | Triage decision tree removed; retrofit codebase-scan folds into discovery text as a short subsection |
| skills/planifest-change-agent | Deleted; domain-context loading pattern folds into the implement skill |
| Change Pipeline workflow doc | Deleted |
| Fast Path workflow doc | Deleted |
| Retrofit workflow doc | Deleted |
| CI parity check | Fast-path exemption branch deleted; one parity check now applies to every diff |
| hooks/planifest.yml | Shipped consumer copy updated to mirror the CI parity check change |

## Consequences

**Positive**

- One route replaces three, so the routing decision tree and the three
  per-route gate sets no longer need to exist.
- One parity check applies to every diff, closing the CI hole a previous
  review flagged against the fast-path exemption branch.
- The framework carries one workflow doc for changes instead of three.

**Negative**

- Tiny fixes now run the full five-phase pipeline instead of a lighter route.
- Deleting `planifest-change-agent` removes its standalone domain-context
  loading pattern from the skill list.

**Risks**

- Tiny fixes carry five-phase overhead. Mitigation: phases scale down, so
  discovery and plan for a one-line fix take minutes, and gates auto-pass in
  continuous mode.
- Deleting the change-agent loses its domain-context loading pattern.
  Mitigation: that pattern folds into the implement skill, so the behaviour
  survives under a different name.

## Related ADRs

- 0000031 ADR-001 (five-phase pipeline contract) - depends-on. The five phases
  defined there are what the single route runs.

## Supersedes

None.

## Superseded By

None.
