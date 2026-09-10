---
title: "ADR 001: Telemetry is not a framework concern"
summary: "planifest-zero removes its telemetry system entirely and ships no replacement and no extension seam. Observability belongs to the tool a person runs Planifest inside. planifest-framework, the dev-time copy, keeps its telemetry."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Telemetry is not a framework concern

**Skill:** [adr-agent](../../../.claude/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-remove-telemetry-mcp
**Component:** planifest-zero
**Date:** 2026-09-10

## Context

Planifest Zero carries a structured telemetry system. Nine hook modules under `hooks/telemetry/`
post pipeline events to a backend at `PLANIFEST_TELEMETRY_URL`. Two enforcement backstops check that
the events actually happened. A standards document defines the envelope and a closed event enum. A
setup flag installs the lot, a verification script confirms the install, and about 20 test suites
cover it.

Every consumer of Zero pays for that surface. It enlarges the install, adds two setup flags, adds a
standards document to every phase skill's bundle, and lengthens every test run, whether or not the
consumer ever points it at a backend. Zero's stated job is narrower: enforce the confirmed-design
pipeline. Observability of an agent session is a property of the tool running the session, not of
the specification framework the session follows.

The system also failed in practice. Feature 0000032 found that the receipt hook rejected the phase
name the standards document told agents to send, which produced five failure markers in one run and
a block-or-proceed question at the next P0. That defect went unfixed because nothing depended on
the telemetry it guarded.

## Decision

1. Remove telemetry from `planifest-zero` entirely. Delete the 34 files that exist only for it.
2. Ship no replacement. Zero emits nothing, records nothing, and posts nothing.
3. Ship no extension seam and no documented attachment point. The framework does not describe how to
   add telemetry, because that is a property of the tool, not of Zero.
4. `planifest-framework/` in this repository keeps its telemetry. It is the separate dev-time copy
   this repository runs its own pipeline against, and it is out of scope.
5. `.github/workflows/planifest.yml`, this repository's own CI, keeps its `validate-telemetry-schema`
   job. That job guards the framework copy's telemetry, which survives. The workflow setup ships to
   consumers carries no telemetry already.
6. Drop the `backendUrl` field from the setup-config record and the flags marker. Feature 0000032
   ADR 001 defined the record as holding `tool`, `flags`, `backendUrl`, and `writtenAt`. That field
   held the telemetry backend URL and nothing else, so after this decision it could only ever be
   `null`. A field that can only be null carries no information. The record now holds `tool`,
   `flags`, and `writtenAt`. The `planifest-refresh-setup` skill no longer requires the key and
   does not reject a record for its absence.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep telemetry, fix the defects | Preserves a working event stream for anyone using it | Keeps the whole surface, and the defects show nobody was using it closely enough to notice | The cost falls on every consumer and the benefit fell on none |
| Make telemetry opt-in at install and keep the code | No flag in the default path | The code, the standards document, and the tests all remain, so the surface is unchanged. It is already opt-in behind a flag | Solves nothing: the flag exists today |
| Remove the system but ship a documented extension seam | A person adding their own telemetry has a starting point | The seam is framework documentation about telemetry, which is the thing this decision says the framework does not do. It also keeps `phase-enum.mjs` alive to serve it | The human was explicit: the framework does not concern itself with telemetry |
| Move telemetry into a separate optional component pack | Preserves the work for later reuse | Creates a component with one consumer and no owner, and the pipeline would still need to know it might exist | No demand for it, and git history preserves the code |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-zero (hooks) | `hooks/telemetry/` and the two `check-telemetry-*` backstops are deleted. The six surviving enforcement hooks and `read-stdin.mjs` are untouched. |
| planifest-zero (setup) | Both setup scripts lose two flags, three functions each, and their interleaved telemetry wiring. |
| planifest-zero (skills) | Six skills lose a `## Telemetry` section and a bundled standard. All twelve lose a `hooks: phase:` key. |
| planifest-zero (docs, templates, tests) | Six docs and two templates are updated. 20 test suites are deleted and 19 edited. |
| planifest-zero (setup-config record) | The record and the flags marker lose the `backendUrl` field, narrowing the shape 0000032 ADR 001 defined. |

## Consequences

**Positive:**
- A consumer installs a framework that enforces the pipeline and does nothing else, with no flag to reason about and no outbound network call.
- Zero's outbound surface becomes nothing. The framework no longer sends anything off the machine.

**Negative:**
- Anyone relying on Zero's telemetry loses it with no migration path, and must wire their own tool-level hooks. The framework offers no guidance, by decision.
- The event vocabulary and envelope design are lost to git history. Reviving them means rebuilding from the archive rather than reading a current document.

**Risks:**
- The enforcement hook installer interleaves two telemetry entries with six surviving hooks in one array build and one de-duplication filter. A careless deletion drops a hook that must survive. ADR-002 addresses the upgrade half of this. Tests cover the install half.

## Related ADRs

- ADR-002 - depends-on (what happens to a project that already installed telemetry)
- ADR-003 - depends-on (what happens to the artifacts that existed only to serve telemetry)
- 0000030 ADR 001 - related-to (Claude Code is the only tool target)
- 0000031 ADR 004 - related-to (living docs describe the present, so the removal is not narrated in `docs/`)

## Supersedes

- The telemetry decisions of features 0000018, 0000024, 0000026, 0000027, and 0000028 as they apply to `planifest-zero`. Those ADRs live in git history. Their subject no longer exists in this component.
- 0000032 ADR 001's record shape, in one narrow respect: the `backendUrl` field is dropped. Every other part of that decision, including the record's location at `plan/state/{tool}.md` and its git-tracked status, stands unchanged.

## Superseded By

- None
