# Design - 0000164-hardening-and-backlog-skill

## Feature
- Problem: `gate-write` blocks writes outside the project, macOS suites can pass falsely, setup runs dead telemetry cleanup, and filing a backlog entry in another repo has no defined skill.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds prior runs and `docs/about.md` exists)
- Feature ID: 0000164-hardening-and-backlog-skill
- Discovery: see `plan/current/discovery.md`

## Product Layer
- User stories:
  - US-001: As an agent, I write files outside the project without a design, so that hooks gate only this project. (0000162)
  - US-002: As a maintainer, I read in `CLAUDE.md` and the hook which paths it gates, including `plan/backlog/` and `plan/roadmap/` between runs, so that docs match behaviour. (0000162)
  - US-003: As a maintainer on macOS, I get the same suite results as CI, so that a local pass is a real pass. (0000161)
  - US-004: As a consumer, I run setup without the legacy telemetry cleanup, so that setup carries no dead code. (0000095)
  - US-005: As a human, I ask the agent to file a backlog entry in another repo, and it writes one uncommitted entry folder, so that the repo's git state stays untouched. (0000163)
- Acceptance criteria confirmed: 5 (feature brief)
- Constraints:
  - The skill never commits, pushes, switches branches, or opens a PR in the target repo.
  - Retired-hook pruning (the 0000151 retired-hooks ADR (decision 7)) keeps working, from a list no longer named for telemetry.
  - The allowed set under `plan/` and `docs/` stays as it is.
- Integrations: none

## Architecture Layer
- Latency target: not applicable. `gate-write` adds no process or network call.
- Availability target: not applicable
- Scalability target: not applicable
- Security: `gate-write` compares real paths (`realpathSync`, falling back to the nearest existing parent for a new file), so a symlink inside the project cannot route a write past the checks. No auth change.
- Data privacy: no regulated data
- Observability: standard defaults
- Cost boundary: not constrained

## Engineering Layer
- Stack: Bash, PowerShell 5.1 and 7, Node.js ESM, Markdown. CI on GitHub Actions. Build target local.
- Components: `ravintio-zero`, the drop-in pipeline pack.
- Data ownership: none
- Deployment: consumers copy the pack folder and run setup
- API versioning: semantic versioning. 1.1.0 is a minor release.

## Component Paths
- `ravintio-zero/`
- `.claude/`
- `.github/`
- `scripts/`
- `CLAUDE.md`
- `README.md`
- `product.yml`

## Scope
- In:
  - `gate-write` exits 0 for a target whose real path is outside the project root. Tests cover it with and without `design.md`, and through a symlink.
  - `gate-write` names `plan/backlog/` and `plan/roadmap/` as allowed. `CLAUDE.md` and the hook comment state what the hook gates.
  - The five suites switch from `done < <(...)` to `done <<< "$(...)"` and skip empty lines. A guard test fails on the old pattern under `tests/`.
  - `setup.sh` and `setup.ps1` drop the telemetry cleanup and its call. The names stay as `RETIRED_HOOK_NAMES` and `$RetiredHookNames`. Cleanup tests go, pruning tests stay.
  - New skill `ravintio-zero/skills/ravintio-file-backlog/SKILL.md`, a catalogue row, and tests.
  - Version 1.1.0.
- Out:
  - Narrowing the `plan/` or `docs/` allowed set.
  - Backlog entries 0000100, 0000110, and 0000159.
- Deferred:
  - Nothing deferred.

## Assumptions
- No live consumer still carries pre-0000033 telemetry wiring. Impact if wrong: stale settings entries stay until the consumer removes them by hand. The changelog says so.

## Risks
- Real-path resolution differs on Windows or macOS `/private/tmp`, so an in-project write reads as outside and skips the gate. Likelihood medium, impact high. Mitigation: resolve both the project root and the target with the same call, and test on all three CI hosts.
- Removing the telemetry cleanup breaks a suite that asserts its output. Likelihood high, impact low. Mitigation: list every telemetry-mentioning suite in P1 and update or delete each one.
- The skill picks an id that a sibling session takes at the same time. Likelihood low, impact low. Mitigation: refuse to overwrite an existing folder and take the next free id.

## Dependencies
- Upstream: none
- Downstream: installed consumer repos
- Approved dependencies: none

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - gate-write-outside-project | ravintio-implement | Hook logic change needs TDD on three hosts |
| REQ-002 - gate-write-documented-scope | ravintio-implement | Allowed-list and docs change with a test |
| REQ-003 - bash32-test-loops | ravintio-implement | Mechanical edit in five suites plus a guard test |
| REQ-004 - retire-telemetry-cleanup | ravintio-implement | Setup change on two shells with test updates |
| REQ-005 - file-backlog-skill | ravintio-implement | New skill with structure tests |
| REQ-006 - gate-write-symlink-cases | ravintio-implement | Symlink and Windows path tests for the hook |
| REQ-007 - gate-write-doc-correction | ravintio-implement | Doc edits in four files |
| REQ-008 - bash32-guard-test | ravintio-implement | New guard test and full-suite check |
| REQ-009 - retire-telemetry-tests-and-docs | ravintio-implement | Suite rewrites, manifest, and changelog |
| REQ-010 - file-backlog-guardrails-and-catalogue | ravintio-implement | Catalogue row and skill-count suites |

## Repo Instructions

### custom-001-local-git-only.md

### Git Permissions
You may fetch, pull, push, and create pull requests (`gh pr create`) without asking each time. Work on a feat/ branch and push it to origin as you commit. Don't use git worktrees - ensure you are on a feat/ branch but work directly in the working directory.

Two actions are human-only, with no exception:

- Committing directly to `main`. Every change lands via a feature branch.
- Merging pull requests into `main`. The human on the loop reviews and merges.

One narrow exception: `gh pr merge --squash` for your own feature PR into `roadmap/*`, after a clean P3 and green CI. The `merge-guard` hook enforces it. See `ravintio-zero/standards/roadmap-standards.md`.

Report back if any remote git or GitHub command fails for any reason.

### Commit Granularly, Continuously
Commit locally after every meaningful artifact write — do not batch changes waiting for a phase gate, an approval checkpoint, or task completion. A single requirement doc, ADR, TDD cycle, or config fix is a commit on its own; don't hold it pending a bigger, later commit. Uncommitted work in the working directory is unrecoverable progress — commit early and often so nothing sits unsaved.

### custom-002-prefer-subagent-decomposition.md

### Prefer Subagent Decomposition for Longer Tasks
When a task within any phase is long-running or spans multiple independent units of work (multiple requirements, multiple files with no cross-references, multiple independent searches or reviews), look actively for ways to split it into multiple subagents dispatched in parallel rather than working through the units sequentially in one context. This is a standing instruction, not a per-run choice - default to decomposing before defaulting to sequential inline work. The orchestrator's Parallelism Rules and Agent Dispatch Template (and each phase skill's own dispatch checklist) define the mechanics; this override raises the bar for when decomposition is attempted in the first place. If a task genuinely cannot be split (shared mutable state, one unit depends on another's output, or it is too small to justify subagent overhead), state the reason rather than defaulting to sequential work silently.

### custom-003-git-up-to-date-shorthand.md

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

### custom-004-ship-push-and-raise-pr.md

### Ship: push and raise the PR, never merge

In the ship phase, push every change and raise the pull request yourself, without asking. Push the feature branch and the release tag, then run `gh pr create`. In the ship skill's push/PR decision, always take option [1].

Never merge the pull request into `main`, and never push or commit to `main`. Merging into `main` is human-only. The one exception is `gh pr merge --squash` for your own feature PR into `roadmap/*`, after validation finished clean and CI is green. The `merge-guard` hook enforces it. See `ravintio-zero/standards/roadmap-standards.md`.

If a push or `gh pr create` fails, report the exact error and stop. Don't retry with force or merge as a workaround.

### custom-005-delete-redundant-local-branches.md

### Delete redundant local branches

You may delete a redundant local branch at any time, without asking. A local branch is redundant when either of these is true:

- Its pull request has merged into `main`.
- `git branch -vv` shows its upstream as `gone` after `git fetch --prune`.

Squash merges leave the branch's commits off `main`, so `git branch -d` refuses them. Use `git branch -D` for a redundant branch.

Never delete the branch you're on, `main`, or a branch with commits that no pull request holds. If a branch has unpushed commits, list them for the human and keep the branch.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 24 Oct 2026 @ 11:57 p.m. BST
