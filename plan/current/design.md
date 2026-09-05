# Design - 0000032-relocate-setup-config-to-plan-state

## Feature
- Problem: `setup.sh`/`setup.ps1` write a machine-derived, rewritten-on-every-run record of active setup flags into `planifest-overrides/`, a folder that otherwise holds only human-authored configuration. The maintainer of a Planifest-managed repo cannot tell reviewed configuration from generated state.
- Adoption mode: standard-iterative
- Feature ID: 0000032-relocate-setup-config-to-plan-state
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a maintainer, I want the active setup-flags and backend-url record stored under `plan/`, so that it is grouped with other durable pipeline state rather than under human-owned overrides.
- Acceptance criteria confirmed: 6
- Constraints:
  - The record stays git-tracked and reviewable in diffs. This feature relocates it and does not undo that.
  - The folder name reads as "state", not "config" or "overrides".
  - Only `planifest-zero/` changes. `planifest-framework/` is the dev-time copy that runs this repo's own pipeline and is refreshed from the product.
  - The gitignored `.planifest-setup-flags` marker keeps its role, format, and location.
- Integrations: none

## Architecture Layer
- Latency target: not applicable (offline shell tooling). Measurable NFR: a second `setup.sh` run against an already-migrated repo changes only the `writtenAt` field of `plan/state/claude-code.md` and prints no removal lines.
- Availability target: not applicable
- Scalability target: not applicable (one file per tool, one supported tool)
- Security: no auth. Data classification: internal, non-secret. The record holds flag names and a backend URL that were already tracked at the old path. No credentials are written.
- Data privacy: no regulated data
- Observability: setup prints one line per file written or removed, and one warning per failed write or removal. Refresh-setup reports the source and confidence of every flag as today.
- Cost boundary: not constrained

## Engineering Layer
- Stack: bash and PowerShell setup scripts, markdown skills and docs, bash test suites under `planifest-zero/tests/` run by `run-tests.sh`, GitHub Actions CI (`planifest.yml`). Build target: local.
- Components:
  - `planifest-zero` (component-pack): owns `setup.sh`, `setup.ps1`, the `planifest-refresh-setup` skill, the layout docs, and the tests.
- Data ownership:
  - `plan/state/{tool}.md` (setup-config record: tool, flags, backendUrl, writtenAt) -> written by `setup.sh`/`setup.ps1`, read by `planifest-refresh-setup`.
  - `{tool-dir}/.planifest-setup-flags` (gitignored marker) -> unchanged, written by setup and refresh-setup.
- Deployment: files inside the component pack. Consumers pick the change up on their next `setup.sh`/`setup.ps1` run, which relocates their record inline.
- API versioning: not applicable

## Scope
- In:
  - `write_setup_config_override` and `Write-SetupConfigOverride` write `plan/state/{tool}.md`, creating `plan/state/` when absent.
  - After a successful write, both scripts delete `planifest-overrides/setup-config/{tool}.md` at its exact path and remove `setup-config/` if it is then empty, printing one line per removal. A failed removal warns and continues. Repeat runs stay silent.
  - `planifest-refresh-setup` Step 3 reads `plan/state/{tool}.md` first at high confidence, validates it, and falls back to the marker then hook inference when it is missing, unreadable, or malformed.
  - Layout docs updated: `plan/README.md`, `plan/feature-structure.md`, `planifest-zero/pipeline-reference.md` (including the "never touches planifest-overrides/" promise), `planifest-zero/project-operations.md`.
  - A superseding ADR for 0000025 ADR-002 and a Superseded row in `docs/decisions-index.md`.
  - Tests: the relocation suite `test-0000025-req-004-setup-config-relocation.sh` rewritten for the new path, plus coverage for inline cleanup and the refresh-setup read order.
- Out:
  - `planifest-framework/` in this repo.
  - The marker's role, format, or location.
  - A migration file for the old record.
  - PowerShell test coverage through `run-tests.sh` (backlog 0000084).
- Deferred: nothing deferred.

## Assumptions
- The write path may create `plan/state/` itself - impact if wrong: first-run setup on a new repo warns and leaves no record until the folder exists.
- The old file's contents never need preserving because the same run regenerates the record from its flags - impact if wrong: a flag set recorded only in the old file is lost on upgrade. Not possible today, since flags come from the command line on every run.
- `plan/` exists in every consumer repo before setup runs, because setup already writes `plan/.orchestrator-strict` there - impact if wrong: the write warns and continues, same as an unwritable folder.

## Risks
- Consumer repos with a locally modified `planifest-overrides/setup-config/{tool}.md` lose that edit on upgrade. Likelihood: low (the file is rewritten on every run anyway). Impact: low.
- The dev-time `planifest-framework/` copy keeps writing to the old path until it is refreshed from `planifest-zero/`, so this repo's own record stays at the old path for now. Likelihood: certain. Impact: low, and documented in discovery.
- The relocation test asserts on exact printed lines and could couple tests to wording. Likelihood: medium. Impact: low.

## Dependencies
- Upstream: 0000030 ADR-001 (Claude Code only), 0000031 ADR-002 (product folder `planifest-zero/`), 0000031 ADR-003 (feature pipeline is the only route), 0000025 ADR-002 (git history, superseded by this feature).
- Downstream: the next refresh of `planifest-framework/` from `planifest-zero/` in this repo.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - bash-write-to-plan-state | planifest-codegen-agent | Shell change with a red-green test cycle |
| REQ-002 - powershell-write-to-plan-state | planifest-codegen-agent | Mirror of REQ-001 in `setup.ps1` |
| REQ-003 - inline-cleanup-of-old-record | planifest-codegen-agent | Shell change in both scripts with tests |
| REQ-004 - refresh-setup-reads-record-first | planifest-codegen-agent | Skill markdown change verified by the existing refresh-setup suite |
| REQ-005 - layout-docs-updated | planifest-docs-agent | Documentation with no novel decisions |
| REQ-006 - superseding-adr | planifest-adr-agent | Records the relocation decision and supersession |

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
Human confirmed this design before proceeding: no // Date and Time confirmed: pending
