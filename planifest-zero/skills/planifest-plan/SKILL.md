---
name: planifest-plan
description: Produces the plan-phase artifact set (requirements, ADRs, scope, risks, glossary) behind one human gate. Invoked by the orchestrator during the plan phase.
bundle_templates: [requirement.template.md, adr.template.md, execution-plan.template.md, scope.template.md, risk-register.template.md, domain-glossary.template.md, component.template.yml, component-guide.md, data-contract.template.md, data-contract-guide.md]
bundle_standards: [formatting-standards.md, telemetry-standards.md, agent-dispatch-standards.md]
hooks:
  phase: plan
---

# Planifest - plan

> You produce the full requirements-and-decisions artifact set for a feature behind one human gate. You work from a confirmed design and feature brief. You derive requirements. You never invent them.

**One question at a time.** When you need human input, ask one question and wait.

## Input

- Confirmed design at `plan/current/design.md`
- Feature brief at `plan/current/feature-brief.md`
- Existing domain knowledge at `plan/` (if retrofit or change)

If the adoption mode is retrofit, work from the retrofit scan recorded in `plan/current/discovery.md`. The execution plan must describe the system as it exists and what is changing, not the change in isolation.

## Artifacts

Write each artifact to disk as you complete it. Do not accumulate artifacts in memory. Each artifact follows its template in `templates/` where one exists.

**Minimal default set - always produced, regardless of feature size:**

| Artifact | Path |
|---|---|
| Execution plan | `plan/current/execution-plan.md` - NFRs plus API and data summary |
| Functional requirements | `plan/current/requirements/` - one granular file per user story |
| Scope | `plan/current/scope.md` - in, out, and deferred all stated explicitly |
| Risk register | `plan/current/risk-register.md` |
| Domain glossary | `plan/current/domain-glossary.md` |
| ADRs | `plan/current/adr/ADR-{NNN}-{title}.md` - one per significant decision |

**Conditional set - produced only when its trigger holds.** A trigger is declared in the feature brief or inferred from a stated property of the confirmed design, never from feature size or story count. Absent a trigger, omit the artifact entirely. No empty or N/A placeholder files.

| Artifact | Path | Trigger |
|---|---|---|
| OpenAPI specification | `plan/current/openapi-spec.yaml` | The feature builds or modifies an API. Omit for pure UI, daemons, and libraries |
| Operational model | `plan/current/operational-model.md` | The feature introduces or modifies a deployed runtime service |
| SLO definitions | `plan/current/slo-definitions.md` | A deployed runtime service has a latency, availability, or throughput target in the design |
| Cost model | `plan/current/cost-model.md` | New or materially changed compute, storage, or third-party spend |
| Component manifest | `src/{component-id}/component.yml` | One per component. Populate purpose, scope, risk, and contract from the requirements set. Never modify the pre-seeded `stack` section. `purpose.notResponsibleFor` is mandatory. Leave `contract.consumedBy` empty |
| Data contract | `src/{component-id}/docs/data-contract.md` | One per data-owning component |

## Requirements rules

- Derive requirements directly from user stories in the brief. Do not invent requirements not stated or implied.
- One file per story at `plan/current/requirements/{req-id}-{slug}.md`, from `templates/requirement.template.md`. No monolithic list in the execution plan.
- Non-functional requirements state specific, measurable targets. No vague qualifiers. If the design defers an NFR, note it in scope and do not fabricate a target.
- The OpenAPI spec covers every endpoint implied by the requirements. No more, no less. Use OpenAPI 3.1 with JSON Schema bodies. Produce it early, since everything downstream implements against it.
- Never invent domain language. If a concept has no clear name, flag it for the human. In a retrofit, include terms the codebase already uses.
- Every risk has a category (technical, operational, security, compliance), a likelihood, and an impact. No generic risks.
- Deferred scope items note what is blocked until they resolve.
- Documented assumptions are allowed for genuinely minor gaps. Record each in the risk register at likelihood medium. Do not assume away material ambiguity. Report it back instead.

## ADR rules

A decision needs an ADR when it meets any of these criteria:

- **Costly to reverse** - database engine, ORM, auth strategy.
- **Crosses components** - sync vs async communication, shared types, event schema.
- **Constrains future work** - deployment topology, provider lock-in, data partitioning.
- **Deviates from the declared stack** - any library or compute model not in the design.
- **Security trade-off** - session storage, token expiry, CORS configuration.
- **Data ownership assignment** - every data ownership mapping gets an ADR.

No ADR for decisions already mandated by the requirements, direct consequences of the stack declaration, or single-component implementation details. Write one ADR recording the stack choice itself, referencing the design.

- Follow `templates/adr.template.md`. Be specific. Vague ADRs are useless.
- Number sequentially from ADR-001.
- Consequences include at least one positive and one negative.
- If a decision supersedes a prior ADR, mark the prior one `Superseded by ADR-{NNN}` and reference it in the new ADR's context.

## Gate

The plan phase ends at one human gate. Before presenting the gate summary:

1. Run `node planifest-zero/scripts/consistency-check.mjs` over the artifact set.
2. Fix what it flags and re-run until clean. This mechanical check is mandatory.

Then present the artifact set summary and stop for human confirmation.

## Parallelism

Dispatch subagents per `standards/agent-dispatch-standards.md`.

| MUST parallelise | Cannot parallelise |
|---|---|
| Requirement files for independent stories | Requirements that reference each other |
| Scope, risk register, and domain glossary | Execution plan summary before requirements are drafted |
| ADRs for independent decisions | An ADR that builds on another ADR's decision |
| Component manifest drafts | Data contract and data-ownership ADRs before ownership is settled |

Out-of-scope discoveries by a dispatched subagent go straight to `plan/backlog/` per the dispatch standard's filing clause.

## Waved features

When the confirmed design groups features into waves:

- Produce artifacts for the current wave only. Later waves may change.
- Suffix wave artifacts, for example `execution-plan-wave-2.md`. Reference prior-wave manifests and contracts rather than re-specifying them.
- The glossary and risk register are cumulative. Add entries each wave and never remove prior ones. Risks remain unless explicitly mitigated.

## Telemetry

See `planifest-zero/standards/telemetry-standards.md` for the event envelope, emission conditions, and phase_start/phase_end ownership. The phase value is `plan`. Telemetry is mandatory, not best-effort, when the unified signal is active. If `emit_event` fails, ask the human whether to block until resolved or proceed without telemetry.

- `spec_gap` when the plan cannot proceed without human input: `{ "question": "<blocking question>", "phase_name": "plan" }`
- `adr_decision` after each ADR is written to disk: `{ "adr_id": "ADR-001", "title": "<decision title>", "chosen_option": "<option selected>" }`

## Commit cadence

Commit after every meaningful artifact write. Do not batch commits to the phase gate.
