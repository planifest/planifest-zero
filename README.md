# Planifest

Planifest is a specification-first framework for Claude Code. It requires the agent to produce a complete, reviewable execution plan, validated against templates and schemas, before it generates code.

It treats the human as product owner and architect. The agent is the implementer, working within constraints the human sets.

This is the cut-down framework. Version `0.1.0` supports Claude Code alone. It supports the [Agent Skills specification](https://agentskills.io/specification).

---

## Rationale

Agile prefers iteration over heavy upfront planning. That preference is tuned to a specific bottleneck. When implementation takes weeks, a detailed plan goes stale before it ships, so small reversible steps beat big documents.

Agentic coding tools do not remove that bottleneck. They move it. Implementation is now cheap and fast, so waste shows up earlier. It arrives as plausible-but-wrong output built on unstated assumptions, rather than as a plan that aged out.

Planifest applies agile's own instinct to the new bottleneck. Do not do work that will not survive contact with reality. Three mechanisms follow:

1. **The plan is the reviewable artifact.** When an agent writes the code, the prompt and plan largely determine the output. Planifest makes the plan explicit and reviewable, so architectural choices are visible before code exists.
2. **Context is recorded per component.** Each component keeps a manifest. Each feature keeps its execution plans and ADRs. That gives an agent or a human the context to modify a component, or the specification to rebuild it.
3. **Gaps trigger questions, not guesses.** If the feature brief has gaps, the agent stops and asks rather than filling them with assumptions.

Whether the trade-off pays off depends on the work. See [Limitations](#limitations-and-non-goals).

---

## How it works

1. **The human writes a feature brief.** What to build, why, and within what constraints.
2. **The agent interrogates.** The orchestrator skill assesses the brief and asks questions until the context is complete.
3. **The agent plans.** It produces an execution plan and an Architecture Decision Record.
4. **The agent builds.** Code generation, then validation, security review, and documentation.
5. **The human reviews.** The pull request is the backstop.

Every artifact follows a template, so output stays consistent across sessions and models.

---

## Repository structure

```
repo/
├── planifest-framework/   ← The framework. Drop in, don't modify per-project.
│   ├── skills/            ← Agent instructions: orchestrator and phase skills
│   ├── templates/         ← File format templates for every artifact
│   ├── schemas/           ← JSON Schema validation definitions
│   ├── standards/         ← Code quality and design standards
│   ├── hooks/             ← Enforcement and telemetry hooks, git hooks, CI workflow
│   ├── workflows/         ← Pipeline route definitions
│   ├── scripts/           ← Deterministic tooling
│   └── tests/             ← The framework's own test suite
│
├── plan/                  ← Feature briefs, execution plans, ADRs, risk registers,
│                            and scope docs. Everything describing WHAT to build
│                            and WHY. See plan/feature-structure.md for the layout.
│
├── src/                   ← Component code, tests, config, and manifests.
│                            Each component carries a component.yml.
│
└── docs/                  ← Living documentation: component registry, architecture
                             overview, decisions index, dependency graph. Written by
                             the docs agent, read by agents and humans.
```

A typical feature produces five Phase 1 artifacts by default: execution plan, requirements, scope, risk register, and domain glossary. OpenAPI spec, cost model, SLO definitions, and operational model arrive only when their trigger condition applies. See [feature-pipeline.md](planifest-framework/workflows/feature-pipeline.md).

---

## Getting started

See [getting-started.md](planifest-framework/getting-started.md) for step-by-step setup.

Quick start:

```bash
# macOS or Linux
./planifest-framework/setup.sh claude-code

# Windows
.\planifest-framework\setup.ps1 claude-code
```

The setup script copies skills into `.claude/skills/`, adds YAML frontmatter, wires the enforcement hooks, and writes the `CLAUDE.md` boot file.

Two optional flags:

| Flag | Effect |
|------|--------|
| `--structured-telemetry-mcp` | Installs the telemetry hooks. Pair with `--backend-url` to override the default endpoint. |
| `--strict-orchestrator` | Writes `plan/.orchestrator-strict`, so the orchestrator must acknowledge each new session before work proceeds. |

---

## Key principles

**Specification before code.** The agent does not write code until the spec is complete. If the spec has gaps, it stops and asks.

**The human decides, the agent executes.** The human chooses the architecture, the stack, the data ownership, and the scope.

**Decompose big initiatives.** Split work into features small enough for one agent session, then group features into waves. That is how Planifest manages context at scale.

**Everything is traced.** Every artifact records the skill that produced it, the tool it ran in, and the model that generated it.

**The PR gate is the backstop.** A human reviews the output before it ships.

---

## The framework

| Folder | Contents |
|--------|----------|
| [skills/](planifest-framework/skills/) | The orchestrator and every phase and sub-agent skill |
| [templates/](planifest-framework/templates/) | File format templates for every pipeline artifact, each with a guide where applicable |
| [schemas/](planifest-framework/schemas/) | Shared type definitions and the domain document envelope |
| [standards/](planifest-framework/standards/) | Code quality, API design, database, deployment, infrastructure, monorepo, observability, and testing standards |
| [setup/](planifest-framework/setup/) | The Claude Code tool config, as a `.sh` and `.ps1` pair |
| [hooks/](planifest-framework/hooks/) | Enforcement and telemetry hooks, git hooks, and the CI workflow |
| [workflows/](planifest-framework/workflows/) | Route definitions: fast-path, feature-pipeline, change-pipeline, retrofit |
| [scripts/](planifest-framework/scripts/) | Consistency checks, version derivation, regression promotion |
| [tests/](planifest-framework/tests/) | Per-feature test scripts plus the promoted regression pack |
| [migrations/](planifest-framework/migrations/) | Pending and completed framework migrations, applied by the `planifest-migrator` skill |
| [skills-inbox/](planifest-framework/skills-inbox/) | Drop-in intake for a new capability skill, processed at the next Phase 0 |

---

## Hard limits

These apply regardless of model or configuration:

1. **Requirement gaps are surfaced, then resolved or explicitly deferred, before codegen begins.** Every deferral is recorded in that feature's `plan/current/scope.md`, so the claim is checkable rather than asserted.
2. **No direct schema modification.** A migration proposal is required, and the human approves it.
3. **Destructive schema operations require human approval.**
4. **Data is owned by one component.** Never write to another component's data.
5. **Code and documentation are written together.** Never one without the other.
6. **Credentials are never in the agent's context.** Capabilities only.

---

## Limitations and non-goals

Planifest trades upfront ceremony for traceability. That trade is not always worth making.

- **Overhead is real.** For small changes, prototypes, or exploratory work, the full pipeline is disproportionate. The fast-path workflow reduces this without eliminating it.
- **It depends on review discipline.** The PR gate is only a backstop if humans read the plans and the diffs. Planifest structures the review. It cannot perform it.
- **Plans do not prevent all bad output.** A complete specification reduces assumption-driven errors. It does not guarantee correct code.
- **No comparative benchmarks exist.** Nothing here measures outcomes with and without the framework. Claims about quality rest on design rationale and our own use.
- **It is not a project management method.** Planifest structures agent sessions, not teams.
- **The plan and docs parity check is a presence check.** CI confirms that some file under `plan/`, `docs/`, or a `component.yml` changed alongside `src/`. It does not verify that the file's content corresponds to the code change. Reviewers check that themselves.

---

## Status

Planifest is under active development. Template and skill formats may change between versions.

Version `0.1.0` is a deliberate reset. Feature `0000030-framework-cut-down` removed support for eight other agentic tools, deleted the vendored skill library and the context-mode integration, and cleared the accumulated plan and docs history. Everything before `0.1.0` is recoverable from git history.

## Contributing

Issues and pull requests are welcome. Agent skills and templates are the areas most likely to benefit from outside contributions.

---

## Documentation

`planifest-docs` holds the human documentation: architecture notes, research, and the roadmap. Agents do not need these. They work from the skills and templates in `planifest-framework/`. It is available as a [git repository](https://github.com/planifest/planifest-docs) and a [GitHub Pages site](https://planifest.github.io/planifest-docs/).

| Document | Purpose |
|----------|---------|
| [Master Plan](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p001-planifest-master-plan.md) | Architecture overview |
| [Product Concept](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p002-planifest-product-concept.md) | Vision and commercial model |
| [Functional Decisions](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p003-planifest-functional-decisions.md) | Decision log with rationale |
| [Pathway to Agentic Development](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p004-the-pathway-to-agentic-development.md) | Background and rationale |
| [Pipeline](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p015-planifest-pipeline.md) | Pipeline phase descriptions |
| [Roadmap](https://github.com/planifest/planifest-docs/blob/main/planifest-docs/p014-planifest-roadmap.md) | Deferred items and future features |

These docs still describe the multi-tool framework. They pre-date the 0.1.0 cut-down.

---

## Licence

[Apache License 2.0](LICENSE.txt), chosen over MIT primarily for its explicit patent grant.
