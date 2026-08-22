# Design - 0000030-framework-cut-down

## Feature
- Problem: This repo carries 30 features of history, three components, nine tools' setup scripts, and 400+ vendored skills. The next product needs a cut-down framework that supports Claude Code only.
- Adoption mode: standard-iterative
- Feature ID: 0000030-framework-cut-down
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the framework maintainer, I remove every non-Claude tool target, so that setup has one supported path instead of nine.
  - US-002: As the framework maintainer, I clear the accumulated plan and docs history, so that the next product starts from an empty record rather than someone else's.
  - US-003: As the framework maintainer, I delete context-mode entirely, so that no flag installs hooks whose source component no longer exists.
- Acceptance criteria confirmed: 8 (see Scope, In)
- Constraints:
  - The 21 pipeline skills survive untouched. Trimming them is a separate, later build.
  - `.github/workflows/planifest.yml` stays exactly as it is, by explicit decision, despite referencing paths this build empties.
  - `plan/_archive/`, `plan/backlog/`, `plan/changelog/`, and `docs/` keep their folders. Only their contents go.
- Integrations: none

## Architecture Layer
- Latency target: not applicable. This build deletes files and edits shell scripts.
- Availability target: not applicable.
- Scalability target: not applicable.
- Security: no auth surface. No credentials touched. Data classification: public source.
- Data privacy: no regulated data.
- Observability: existing telemetry hooks stay wired. `--structured-telemetry-mcp` is unaffected.
- Cost boundary: not constrained.

## Engineering Layer
- Stack: no application stack. Bash and PowerShell setup scripts, Node `.mjs` hooks, Markdown artifacts. Build target: none.
- Components after this build, one:
  - `planifest-framework`: core standards, skills, hooks, and Claude Code setup scripts.
- Components removed:
  - `context-mode-hooks`: deleted. Commit 6a50af1 already dropped context-mode from the boot templates, leaving this component orphaned.
  - `setup-hook-integration`: deleted. Its `src/` docs tree duplicated what `planifest-framework/` already ships.
- Data ownership: `planifest-framework` owns `product.yml`, `docs/`, and every file under `planifest-framework/`.
- Deployment: not applicable. Consumers install via `setup.sh` or `setup.ps1`.
- API versioning: not applicable.

## Scope

### In
1. Delete `planifest-framework/external-skills/` in full.
2. Delete `src/` in full, including both components, and drop their `product.yml` entries.
3. Delete non-Claude tool support: `planifest-framework/setup/` scripts for cursor, windsurf, cline, codex, copilot, roo-code, opencode, and antigravity, both `.sh` and `.ps1`; `.cursorignore`, `.clineignore`, `.windsurfignore`, `.cursorindexingignore`; `planifest-framework/tool-setup-reference.md`; `planifest-framework/templates/cursor-boot.md`; and the non-Claude adapters under `planifest-framework/hooks/adapters/`.
4. Remove every element of context-mode: `planifest-framework/hooks/context-mode/`, the `--context-mode-mcp` flag and its branches in `setup.sh` and `setup.ps1`, `docs/context-mode.md`, the context-mode tests, and all remaining references in framework docs.
5. Empty `plan/_archive/`, `plan/backlog/` (all 23 entries discarded), `plan/changelog/`, and `docs/`. Each folder survives with a `.gitkeep`.
6. Rewrite `README.md` to describe the cut-down framework.
7. Rewrite `product.yml`: version `0.1.0`, single component, `id` unchanged.
8. Reset the version to `0.1.0` across `product.yml`, `docs/about.md`, and `planifest-framework/component.yml`.

### Out
- Trimming the 21 pipeline skills. A later build decides which phases survive.
- Changing `.github/workflows/planifest.yml`.
- Deleting `plan/feature-structure.md`, `plan/library-standards-plan.md`, or `plan/README.md`.
- Removing PowerShell. `setup.ps1`, `setup/claude-code.ps1`, and `refresh-planifest-framework-dir.ps1` all stay.
- Defining what the new product is. This build only clears the ground.

### Deferred
- Skill trim. Blocked until the human decides which pipeline phases the cut-down framework keeps.
- README content describing the new product. Blocked until the product exists.
- `refresh-planifest-framework-dir.ps1` still hardcodes `C:\d\planifest\framework\`. Left as-is by decision. Nothing breaks until someone runs it on a different path.

## Version override
The orchestrator hard-blocks a version lower than the last known version. Last known was `0.28.1`; this build writes `0.1.0`.

The human on the loop confirmed the override on 2026-08-22. Rationale: this build empties `plan/_archive/`, rewrites `docs/about.md`, and rewrites `product.yml` in the same commit series. The version history is deleted rather than contradicted, which is the reset the hard block asks for. Recorded here and in `build-log.md` so the override is checkable against an artifact.

## Assumptions
- Nothing outside this repo consumes `planifest-framework/external-skills/`. Impact if wrong: a downstream install loses its skill library and `--include-full-skill-library` becomes a no-op.
- No live install depends on the eight deleted tool targets. Impact if wrong: a Cursor or Windsurf user cannot re-run setup.
- Deleting `src/` breaks no framework test that asserts against those paths. Impact if wrong: the P4 validate step fails and needs a test sweep.

## Risks
- Context-mode removal spans roughly 20 files across `setup.sh`, `setup.ps1`, tests, and docs. Likelihood high, impact medium. A missed reference leaves a flag that installs nothing.
- `.github/workflows/planifest.yml` keeps its `plan/changelog/` fast-path branch after this build empties the folder. Likelihood certain, impact low. Accepted by explicit decision.
- The framework test suite references deleted paths. Likelihood high, impact medium. Caught at validation.
- Emptying `plan/_archive/` destroys 30 features of decision history. Likelihood certain, impact medium. Recoverable from git history only.

## Dependencies
- Upstream: none.
- Downstream: any repo that installed this framework keeps its own copy. No live consumer is known.

## Active Skills
None.

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| Scope items 1 to 3, bulk deletion | planifest-change-agent | Mechanical file removal with documentation updates, the change pipeline's core job. |
| Scope item 4, context-mode removal | planifest-change-agent | Spans setup scripts, tests, and docs. Needs the change agent's contract check before edits land. |
| Scope item 5, empty the record folders | planifest-change-agent | Deletion plus `.gitkeep` placement. |
| Scope items 6 to 8, README, product.yml, version | planifest-docs-agent | Living documentation and the product version manifest. |
| Validation after deletion | planifest-validate-agent | The framework test suite references deleted paths and needs a sweep. |

## Repo Instructions

### custom-001-local-git-only.md

Git permissions: fetch, pull, push, and `gh pr create` are pre-authorised. Work on a `feat/` branch and push to origin while committing. No git worktrees.

Two actions are human-only, with no exception: committing directly to `main`, and merging pull requests.

Report back if any remote git or GitHub command fails.

Commit granularly and continuously. Commit locally after every meaningful artifact write. Do not batch changes waiting for a phase gate.

### custom-002-prefer-subagent-decomposition.md

When a task spans multiple independent units of work, split it into parallel subagents rather than working sequentially in one context. This is a standing instruction. If a task genuinely cannot be split, state the reason rather than defaulting to sequential work silently.

### custom-003-git-up-to-date-shorthand.md

`GUTD` means git up to date: `git status` first, `git checkout main`, pull from `origin/main`, and report any untracked files. Do not force-reconcile a diverged local `main`.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 22 Aug 2026 @ 04:03 p.m. BST
