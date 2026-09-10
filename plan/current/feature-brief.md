---
title: "Feature Brief - remove-telemetry-mcp"
summary: "The business case, scope, and product requirements for the feature."
status: "confirmed"
version: "0.4.0"
---
# Feature Brief - remove-telemetry-mcp

**Feature ID:** 0000033-remove-telemetry-mcp

> Drafted by the orchestrator from the human's stated goal in conversation, then confirmed at the
> design gate. Every decision below was confirmed during P0 coaching.

## Business Goal

Planifest Zero carries a structured telemetry system: nine hook modules, two enforcement
backstops, a verification script, a standards document, a setup flag, and about 20 test suites.
It exists to post pipeline events to a backend at `PLANIFEST_TELEMETRY_URL`.

Telemetry is not a framework concern. Zero's job is to enforce the confirmed-design pipeline.
Observability belongs to the tool a person runs Zero inside, and to that person's own hooks if
their tool supports them. Carrying a telemetry system in the framework means every consumer pays
for it in install surface, setup flags, documentation, and test runtime, whether or not they ever
point it at a backend.

This feature removes telemetry from `planifest-zero` entirely. It ships no replacement and no
extension seam, because the framework does not concern itself with telemetry at all.

`planifest-framework/` keeps its telemetry. That is the separate dev-time copy this repository
runs its own pipeline against, and it is out of scope.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Remove telemetry from Zero | As a maintainer, I want no telemetry system in `planifest-zero`, so that the framework enforces the pipeline and leaves observability to the tool | must-have | 1 |

## Waves

Not applicable. One feature, one user story.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-zero | component-pack | existing | Standards, skills, hooks, templates, and setup scripts that enforce the pipeline |

### Data Ownership

No data store. `component.yml` declares `ownsData: false`.

### Integration Points

The only outbound integration is the telemetry backend, which this feature removes. No MCP server
is registered by setup: the server appears solely as a hook matcher string in `.claude/settings.json`.

## Stack

Existing bash and PowerShell tooling, Node hook modules, markdown skills and docs, bash test
suites. No new stack.

| Concern | Decision |
|---------|----------|
| Build target | local |

## Scope Boundaries

### In Scope

- Delete the 34 telemetry-only files: `hooks/telemetry/` (9 modules), the two
  `hooks/enforcement/check-telemetry-*.mjs` backstops, `scripts/verify-telemetry-hooks.mjs`,
  `standards/telemetry-standards.md`, `tests/helpers/controllable-backend.mjs`, 15 test suites,
  and 5 regression copies.
- Delete `hooks/enforcement/phase-enum.mjs`. Every one of its four exports is consumed only by
  deleted files. `pipeline-reference.md` states the five phase names directly instead.
- Remove the telemetry blocks from `setup.sh` and `setup.ps1`: the flag default, argument parsing
  for `--structured-telemetry-mcp` and `--backend-url`, usage text, the three whole telemetry
  functions, the sentinel write, and the telemetry entries inside the enforcement hook installer.
- Remove the telemetry hook paths from `setup/claude-code.sh` and `setup/claude-code.ps1`.
- Remove the top-level `id` field from `product.yml` and its template, and drop the orchestrator's
  product-id hard stop. Telemetry was its only consumer. `components[].id` is a different field and
  stays, because the version script reads it.
- Remove the `## Telemetry` section and the `telemetry-standards.md` bundle reference from the six
  skills that carry them, and the `hooks: phase:` frontmatter key from all twelve.
- Remove the `Telemetry` row from `templates/build-log.template.md` and the telemetry clause from
  the orchestrator's Hard Limit on build-log blocks. The block itself stays mandatory.
- Update the docs: `pipeline-reference.md`, `project-operations.md`, `getting-started.md`,
  `tests/README.md`, `templates/standard-boot.md`, and `component.yml`.
- Edit the 19 mixed test suites to drop their telemetry assertions while keeping the rest, and
  remove the five telemetry entries from `tests/regression/regression-manifest.json`.
- Clean up an upgraded project on every setup run: remove telemetry hook entries from the
  project's `.claude/settings.json`, delete the `.claude/telemetry-enabled` sentinel, and delete
  `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` when present. One printed line per
  removal, a warning without failing on error, and silence when there is nothing to remove.

### Out of Scope

- `planifest-framework/` in this repository. It keeps its telemetry and runs this repo's pipeline.
- Any replacement telemetry, extension seam, or documented hook attachment point. The framework
  ships nothing about telemetry.
- The two shared modules `hooks/enforcement/read-stdin.mjs` and the surviving enforcement hooks.
  Their behaviour does not change. Only telemetry wording in comments is corrected.
- The five phase names themselves. The pipeline contract from 0000031 ADR 001 is unchanged.

### Deferred

- Nothing deferred.

## Non-Functional Requirements

| Concern | Target |
|---------|--------|
| No regression | Every surviving enforcement hook installs and fires exactly as before. |
| Clean removal | A repository-wide search of `planifest-zero/` for the telemetry markers returns no matches outside deliberate history references. |

## Constraints and Assumptions

### Constraints

- The six surviving enforcement hooks must keep working: `gate-write`, `check-design`,
  `ratchet-check`, `em-dash-guard`, `auto-trigger-orchestrator`, `check-orchestrator-presence`,
  plus the `commit-msg` git hook.
- `hooks/enforcement/read-stdin.mjs` must survive. Six surviving hooks import it.
- 0000032's setup-config record work must not regress. This feature edits the same functions.

### Assumptions

- No consumer depends on Zero's telemetry. The framework is pre-1.0 and this repository is its
  only known consumer of the flag.

## Scenario Paths

**Happy path:** A maintainer runs `setup.sh` or `setup.ps1`. The install offers no telemetry flags
and writes no telemetry entries into `.claude/settings.json`. The six enforcement hooks and the
`commit-msg` git hook fire exactly as before. Nothing in the framework posts an event anywhere, and
nothing in the setup output, the skills, or the docs mentions telemetry. Anyone wanting
observability configures it at the tool level, outside anything Zero provides.

**First-run path:** A brand-new project installs with no telemetry present and nothing to
initialise. A project that previously ran setup with `--structured-telemetry-mcp` gets its
telemetry wiring removed by the same run: the settings entries, the sentinel, and the marker
directories go, each with one printed line. A second run finds nothing to remove and stays silent.

**Error / sad path:** The most likely failure is an upgraded project whose `.claude/settings.json`
still points at deleted hook modules, so the tool tries to run a missing file on every prompt. The
cleanup above prevents it. If a removal fails, setup prints one warning, leaves the entry alone,
and continues. A saved command still carrying `--structured-telemetry-mcp` or `--backend-url` is
rejected as an unknown argument, so the person sees the problem at once.

**Cross-session continuity:** No telemetry state is at risk, because none exists. A pipeline run
resumes cleanly whether its build log was started before or after the `Telemetry` row was removed,
because a blank or absent field no longer stops a run. Setup no longer pauses for a product id, so
a run that stopped at that gate does not stop there again. A setup run interrupted partway through
the settings rewrite is finished by the next run, which is idempotent.

## Acceptance Criteria

- [ ] No file under `planifest-zero/` posts to a telemetry backend, and `hooks/telemetry/` no longer exists.
- [ ] `setup.sh` and `setup.ps1` reject `--structured-telemetry-mcp` and `--backend-url` as unknown arguments, and their usage text does not mention them.
- [ ] Setup installs the six enforcement hooks and the `commit-msg` hook exactly as before, with no telemetry entries in the generated `.claude/settings.json`.
- [ ] `product.yml` has no top-level `id` field, and P0 no longer hard-stops asking for one.
- [ ] The test runner passes with no telemetry suite present, and `regression-manifest.json` carries no telemetry entry.
- [ ] `docs/` and the `planifest-zero/` docs describe a framework with no telemetry.
- [ ] Running the new setup on a project that previously enabled telemetry removes the telemetry entries from its `.claude/settings.json`, the `.claude/telemetry-enabled` sentinel, and the `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` directories, printing one line per removal. A second run prints none.
