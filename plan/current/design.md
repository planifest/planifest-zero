# Design - 0000031-five-phase-planifest-zero

## Feature
- Problem: The framework's folder name, ten-phase contract, three extra routes, and 21 skills describe a product that no longer exists; every run pays context for ceremony the maintainer does not use.
- Adoption mode: standard-iterative
- Feature ID: 0000031-five-phase-planifest-zero
- Discovery: see `plan/current/discovery.md` (raw P0 findings; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the maintainer, I rename `planifest-framework/` to `planifest-zero/` with every reference updated, so that the folder matches the product.
  - US-002: As the maintainer, I remove the Change Pipeline, Fast Path, and Retrofit routes, so that every change runs the one feature pipeline.
  - US-003: As the maintainer, I collapse the ten phases into discovery, plan, implement, validate-and-accept, and ship, so that runs carry less ceremony.
  - US-004: As the maintainer, I keep setup and the overrides mechanism working unchanged in function, so that repo-level customisation survives the cut.
  - US-005: As the maintainer, I keep the telemetry MCP integration and remove every remaining trace of context-mode, so that one MCP concern remains.
  - US-006: As the maintainer, I rewrite all living docs to describe only the current state, so that history lives solely in change records.
- Acceptance criteria confirmed: 9 (see feature-brief.md)
- Constraints: 0000030 ADR-001 binds (Claude Code only); live `.claude/` untouched until setup re-runs; version 0.2.0; commit standards enforced by hook.
- Integrations: structured-telemetry MCP backend (HTTP POST, localhost:3741); GitHub Actions CI.

## Architecture Layer
- Latency target: not applicable (no runtime service; framework executes as local scripts and hooks)
- Availability target: not applicable
- Scalability target: not applicable
- Security: no auth surface. Data classification: public repository content, no PII. Hook enforcement is integrity, not security.
- Data privacy: no regulated data
- Observability: telemetry events per telemetry-standards.md; failure markers under plan/.telemetry-failures/
- Cost boundary: context cost NFR: orchestrator plus phase skill text at or below 50% of the current total line count

## Engineering Layer
- Stack: Bash + PowerShell + Node.js ESM hooks + Markdown / no frontend / no database / no ORM / no IaC / no cloud / local compute / GitHub Actions CI / Build target: local
- Components: planifest-zero (renamed from planifest-framework): standards, skills, hooks, templates, schemas, setup scripts enforcing the five-phase pipeline.
- Data ownership: planifest-zero owns plan/ artifacts, docs/, telemetry markers.
- Deployment: none. Consumers copy the folder and run setup.
- API versioning: not applicable

## Phase Contract (the deliverable)
| New phase | Absorbs | Gate |
|-----------|---------|------|
| discovery | P0 | Human confirms design |
| plan | P1 + P2 | Human confirms requirements and ADRs (one gate) |
| implement | P3 + P6 | Code, tests, and docs land together; TDD loop per requirement |
| validate-and-accept | P4 + P5 | CI green, security review, verify-by-execution, human acceptance |
| ship | P7 + P8 + P9 | Archive, build assessment, changelog, tag, PR |

Skill fates: 21 become 12 (five-phase core: orchestrator, plan, implement, validate-and-accept, ship; surviving: test-writer, implementer, refactor, loop-runner, optimise-agent, migrator, refresh-setup). Telemetry phase enum: exactly five values matching the new phase names.

## Scope
- In: full In-Scope list of feature-brief.md, including the nine folded backlog entries (0000075-0000083).
- Out: telemetry backend server changes; non-Claude tool targets; src/ beyond setup regeneration; backlog 0000084.
- Deferred: nothing deferred.

## Assumptions
- The telemetry backend tolerates unknown phase values or is updated separately - impact if wrong: emission failures surface as markers and block-or-proceed questions during the first five-phase run; nothing corrupts.
- product.yml id becomes `planifest-zero`; telemetry attribution restarts - impact if wrong: events split across two ids; recoverable by backend-side aliasing.
- This run executes under the installed ten-phase contract; the five-phase contract takes effect at next setup run - impact if wrong: none; insulation verified (zero planifest-framework refs in .claude/settings.json).

## Risks
- Missed rename reference breaks a script or test. Likelihood: high (387 refs). Impact: low; caught by the grep-sweep acceptance criterion and run-tests.sh.
- Telemetry backend rejects the five new phase names. Likelihood: medium. Impact: low; marker protocol surfaces it, run proceeds by human choice.
- Docs rewrite drops a fact still needed operationally. Likelihood: medium. Impact: medium; mitigated by present-state audit at validate-and-accept and git history.
- The build modifies the pipeline that governs the next run's resume. Likelihood: low. Impact: medium; mitigated by granular commits and the insulated installed tree.

## Dependencies
- Upstream: none.
- Downstream: the next feature run adopts the five-phase contract after setup re-runs.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 rename | planifest-codegen-agent | Mechanical sweep with test verification |
| US-002 single route | planifest-codegen-agent | File deletion plus workflow rewrite |
| US-003 five phases | planifest-codegen-agent | Skill and hook rewrite, largest unit |
| US-004 setup/overrides | planifest-codegen-agent + planifest-verify-by-execution | Behaviour must be proven by running setup |
| US-005 telemetry-only MCP | planifest-codegen-agent | Enum shrink plus trace removal |
| US-006 present-tense docs | planifest-docs-agent | Living-docs rewrite is its remit |

## Repo Instructions
- custom-001-local-git-only.md: fetch/pull/push/`gh pr create` allowed without per-use approval; main commits and PR merges are human-only; commit granularly and continuously.
- custom-002-prefer-subagent-decomposition.md: default to parallel subagent decomposition for multi-unit work; state the reason when not splitting.
- custom-003-git-up-to-date-shorthand.md: GUTD shorthand: checkout main, pull, report untracked files.

## Confirmation
Human confirmed this design before proceeding: pending // Date and Time confirmed: pending
