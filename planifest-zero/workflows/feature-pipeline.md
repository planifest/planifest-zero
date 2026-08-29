---
name: feature-pipeline
description: Run the Planifest pipeline from feature brief to merged PR. The single route for every change.
---

# Feature Pipeline

The single route through Planifest. Every change runs this pipeline.

## Every change is a feature change

There is one route. A small change is a small run: fewer requirements, a
shorter plan, and a quicker pass through the same five gates. It is not a
different route.

## Prerequisites

- A feature brief at `plan/current/feature-brief.md`.
- If you don't have one, use the
  [feature brief template](../templates/feature-brief.template.md).

## Phases

The pipeline has five phases. The orchestrator owns discovery and drives the
run. Each later phase is owned by its own skill, which the orchestrator
invokes in order.

| # | Phase | Owner | Produces |
|---|-------|-------|----------|
| 1 | Discovery | planifest-orchestrator | `plan/current/discovery.md`, confirmed `plan/current/design.md` |
| 2 | Plan | planifest-plan | Requirements at `plan/current/requirements/`, ADRs at `plan/current/adr/` |
| 3 | Implement | planifest-implement | Code, tests, and docs at `src/{component-id}/` |
| 4 | Validate and accept | planifest-validate-and-accept | Passing CI, security review, verified acceptance criteria |
| 5 | Ship | planifest-ship | Archive, build assessment, changelog, tag, PR |

### 1. Discovery

The orchestrator reads the brief, coaches the human through gaps one question
at a time, picks up backlog entries, locks scope, and writes the design.

**Gate: design confirmation.** The human confirms `plan/current/design.md`.
That confirmation ends discovery. No later phase starts without it.

### 2. Plan

planifest-plan produces one artifact set: the execution plan, functional
requirements, scope, risk register, glossary, and an ADR for every
significant decision.

**Gate: the plan gate.** One gate for the whole artifact set. Requirements
and ADRs are confirmed together, not separately.

### 3. Implement

planifest-implement builds the feature through a TDD loop per requirement.
Code, tests, and docs land together. Code never ships without its
documentation.

**Gate: the implement gate.** Every requirement has code, tests, and docs,
and the implementation matches the confirmed plan.

### 4. Validate and accept

planifest-validate-and-accept runs CI (lint, typecheck, test, build),
self-corrects up to 5 times, performs the security review, and verifies
acceptance criteria by running the software.

**Gate: human acceptance.** The human accepts the working feature. This gate
always stops, in every run mode.

### 5. Ship

planifest-ship archives `plan/current/` to `plan/_archive/{feature-id}/`,
files the build assessment, writes the changelog entry, tags the release,
and raises the PR.

**Gate: the ship gate.** The human confirms the shipped result and merges
the PR. This gate always stops, in every run mode.

## Run modes

The orchestrator asks for a run mode during discovery and records it in
`plan/.run-mode`.

- **Interactive** (default): the pipeline stops at every gate and waits for
  the human.
- **Continuous**: the pipeline proceeds through the plan and implement gates
  on its own self-checks, reporting rather than waiting.

Two stops hold in both modes: human acceptance and the ship gate. Continuous
mode never bypasses them. Design confirmation also always involves the
human, because the run mode is chosen at that conversation.
