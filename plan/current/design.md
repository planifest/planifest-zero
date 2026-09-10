# Design - 0000033-remove-telemetry-mcp

## Feature
- Problem: Planifest Zero carries a structured telemetry system across 34 dedicated files and roughly 45 more, so every consumer pays for it in install surface, setup flags, docs, and test runtime. Observability belongs to the tool, not to the framework that enforces the pipeline.
- Adoption mode: standard-iterative
- Feature ID: 0000033-remove-telemetry-mcp
- Discovery: see `plan/current/discovery.md` (raw P0 findings; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a maintainer, I want no telemetry system in `planifest-zero`, so that the framework enforces the pipeline and leaves observability to the tool.
- Acceptance criteria confirmed: 7
- Constraints:
  - The six surviving enforcement hooks and the `commit-msg` git hook must keep working unchanged.
  - `hooks/enforcement/read-stdin.mjs` must survive. Six surviving hooks import it.
  - 0000032's setup-config record work must not regress. This feature edits the same functions.
  - The five phase names survive unchanged: `discovery`, `plan`, `implement`, `validate-and-accept`, `ship`. Only the module that encoded them goes.
- Integrations: none after this feature. The telemetry backend was the only outbound integration.

## Component Paths
- planifest-zero/
- product.yml
- docs/

## Architecture Layer
- Latency target: not applicable. Measurable NFR below covers install behaviour.
- Availability target: not applicable
- Scalability target: not applicable
- Security: no auth. Removing an outbound HTTP POST to a configurable URL reduces the outbound surface to zero. No credential was ever written.
- Data privacy: no regulated data. The framework stops sending pipeline events off the machine entirely.
- Observability: none shipped, by decision. Anyone wanting it configures their own tool-level hooks.
- Cost boundary: not constrained

## Engineering Layer
- Stack: bash and PowerShell setup scripts, Node hook modules, markdown skills and docs, bash test suites run by `run-tests.sh`, GitHub Actions CI. Build target: local.
- Components:
  - `planifest-zero` (component-pack): the only component. Owns the hooks, skills, templates, standards, setup scripts, and tests.
- Data ownership: none. `component.yml` declares `ownsData: false`.
- Deployment: files inside the component pack. Consumers pick the change up on their next setup run, which also cleans up their prior telemetry wiring.
- API versioning: not applicable

## Scope
- In:
  - Delete 34 telemetry-only files: `hooks/telemetry/` (9 modules), `hooks/enforcement/check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs`, `scripts/verify-telemetry-hooks.mjs`, `standards/telemetry-standards.md`, `tests/helpers/controllable-backend.mjs`, 15 test suites, 5 regression copies.
  - Delete `hooks/enforcement/phase-enum.mjs`. All four of its exports are consumed only by deleted files.
  - Remove every telemetry block from `planifest-zero/setup.sh` and `planifest-zero/setup.ps1`: flag defaults, argument parsing for `--structured-telemetry-mcp` and `--backend-url`, usage text, three whole telemetry functions each, the sentinel write, and the telemetry entries interleaved in the enforcement hook installer.
  - Remove the telemetry hook path variables from `planifest-zero/setup/claude-code.sh` and `claude-code.ps1`.
  - Add upgrade cleanup to both setup scripts: on every run, remove telemetry hook entries from the project's `.claude/settings.json`, delete `.claude/telemetry-enabled`, and delete `plan/.telemetry-failures/` and `plan/.telemetry-receipts/` when present. One printed line per removal. A warning without failing on error. Silent when nothing is present.
  - Remove the top-level `id` field from `product.yml` and `planifest-zero/templates/product.template.yml`, and drop the orchestrator's product-id hard stop. `components[].id` stays.
  - Remove the `## Telemetry` section and the `telemetry-standards.md` bundle reference from the six skills carrying them, and the `hooks: phase:` frontmatter key from all twelve.
  - Remove the `Telemetry` row from `planifest-zero/templates/build-log.template.md` and the summary's telemetry-gap count, plus the telemetry clause in the orchestrator's build-log Hard Limit. The phase block stays mandatory.
  - Update `planifest-zero/pipeline-reference.md` (stating the five phase names directly), `project-operations.md`, `getting-started.md`, `tests/README.md`, `templates/standard-boot.md`, and `component.yml`.
  - Edit 19 mixed test suites to drop telemetry assertions while keeping the rest, and remove the five telemetry entries from `tests/regression/regression-manifest.json`.
- Out:
  - `planifest-framework/` in this repository. It keeps its telemetry and runs this repo's own pipeline.
  - `.github/workflows/planifest.yml`, this repository's own CI. Its `validate-telemetry-schema` job guards the framework copy's telemetry, which survives. The workflow setup ships to consumers, `planifest-zero/hooks/planifest.yml`, carries no telemetry and needs no change.
  - Any replacement telemetry, extension seam, or documented hook attachment point.
  - `hooks/enforcement/read-stdin.mjs` behaviour and the six surviving enforcement hooks. Only telemetry wording in comments is corrected.
  - The five phase names and the pipeline contract from 0000031 ADR 001.
- Deferred: nothing deferred.

## Assumptions
- No consumer depends on Zero's telemetry - impact if wrong: that consumer loses event emission with no migration path and must wire their own tool-level hooks.
- Removing a documented setup flag is a minor bump, not a major one, because the product is pre-1.0 and features 0000030 and 0000031 removed larger surfaces under minor bumps - impact if wrong: the version understates the change for anyone reading tags alone.
- Every telemetry entry a prior setup run wrote into `.claude/settings.json` is identifiable by its command string - impact if wrong: cleanup misses an entry and the broken reference survives.

## Risks
- The enforcement hook installer interleaves two telemetry entries with six surviving hooks in one array build and one de-duplication filter. A careless block delete drops a surviving hook. Likelihood: medium. Impact: high.
- Nineteen mixed test suites assert on telemetry among other things. Editing them wrongly can mask a real regression rather than surface it. Likelihood: medium. Impact: medium.
- `regression-manifest.json` carries a "do not edit manually" notice, and this feature must remove five entries by hand. Likelihood: certain. Impact: low.
- The orchestrator's build-log Hard Limit governs both the phase block and the telemetry field. Removing the wrong half weakens a rule that must survive. Likelihood: low. Impact: high.
- Two suites already fail on `main` because `planifest-framework/` exists (backlog 0000086). They will still fail after this feature and must not be mistaken for a regression. Likelihood: certain. Impact: low.

## Dependencies
- Upstream: 0000030 ADR 001 (Claude Code only), 0000031 ADR 001 (five-phase contract), 0000031 ADR 003 (one route, so a minor bump), 0000031 ADR 004 (living docs describe the present), 0000032 ADR 003 (the inline cleanup precedent this feature follows).
- Downstream: the next refresh of `planifest-framework/` from `planifest-zero/` in this repository, which would carry telemetry removal into the dev-time copy. Not part of this feature.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - delete-telemetry-only-files | planifest-codegen-agent | Deletion plus import-graph verification |
| REQ-002 - setup-sh-telemetry-removal | planifest-codegen-agent | Interleaved shell edits with a red-green cycle |
| REQ-003 - setup-ps1-telemetry-removal | planifest-codegen-agent | Mirror of REQ-002, verified statically |
| REQ-004 - upgrade-cleanup-of-telemetry-wiring | planifest-codegen-agent | New behaviour in both scripts with tests |
| REQ-005 - drop-product-id-gate | planifest-codegen-agent | Skill, manifest, and template edits |
| REQ-006 - skills-and-templates-detelemetried | planifest-codegen-agent | Twelve skills and two templates, assertion-tested |
| REQ-007 - docs-describe-no-telemetry | planifest-docs-agent | Documentation with no novel decisions |
| REQ-008 - test-suite-cleanup | planifest-codegen-agent | Deleting 20 suites and editing 19 without masking regressions |

## Repo Instructions

<!-- planifest-overrides/instructions/custom-001-local-git-only.md -->
### Git Permissions
You may fetch, pull, push, and create pull requests (`gh pr create`) without asking each time. Work on a feat/ branch and push it to origin as you commit. Don't use git worktrees - ensure you are on a feat/ branch but work directly in the working directory.

Two actions are human-only, with no exception:

- Committing directly to `main`. Every change lands via a feature branch.
- Merging pull requests. The human on the loop reviews and merges.

Report back if any remote git or GitHub command fails for any reason.

### Commit Granularly, Continuously
Commit locally after every meaningful artifact write — do not batch changes waiting for a phase gate, an approval checkpoint, or task completion. A single requirement doc, ADR, TDD cycle, or config fix is a commit on its own; don't hold it pending a bigger, later commit. Uncommitted work in the working directory is unrecoverable progress — commit early and often so nothing sits unsaved.

<!-- planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md -->
### Prefer Subagent Decomposition for Longer Tasks
When a task within any phase is long-running or spans multiple independent units of work (multiple requirements, multiple files with no cross-references, multiple independent searches or reviews), look actively for ways to split it into multiple subagents dispatched in parallel rather than working through the units sequentially in one context. This is a standing instruction, not a per-run choice - default to decomposing before defaulting to sequential inline work. The orchestrator's Parallelism Rules and Agent Dispatch Template (and each phase skill's own dispatch checklist) define the mechanics; this override raises the bar for when decomposition is attempted in the first place. If a task genuinely cannot be split (shared mutable state, one unit depends on another's output, or it is too small to justify subagent overhead), state the reason rather than defaulting to sequential work silently.

<!-- planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md -->
# Shorthand: GUTD

**When the human sends "GUTD", treat it as shorthand for "git up to date": check out `main`, pull the latest, and check for any untracked files.**

## Rule

On receiving the literal token `GUTD` (case-insensitive):

1. `git status` first — per standard safety practice, stash or flag anything uncommitted before switching branches.
2. `git checkout main`.
3. Pull the latest from `origin/main`. If local `main` has diverged (local-only commits not on `origin/main`), do not silently force-reconcile — investigate what those commits are first, same as any other unexpected local state, and prefer a reversible step (e.g. a backup branch) over discarding them.
4. Report any untracked files in the working tree (`git status --porcelain` `??` entries) — list them for the human rather than silently ignoring or cleaning them.

## Why

Established 2026-08-02 as a shorthand for a routine sync check the human runs often. Folds in the untracked-files check by default, since a prior "checkout main and pull latest" request surfaced local `main` commits that had diverged from `origin/main` (a stray, unfinished P0 pipeline run started directly on `main`) — worth surfacing untracked/stray state every time, not just when asked.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 10 Sep 2026 @ 07:40 a.m. BST
