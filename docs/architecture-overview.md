# Architecture Overview

Last updated: 0000164-hardening-and-backlog-skill

## What this repo is

This repo is RAVINTIO Zero itself. It holds one component, `ravintio-zero`, which other projects install into their working tree.

RAVINTIO Zero is not a service. It has no runtime of its own. It ships these things:

1. **Skills.** Markdown instructions that Claude Code auto-discovers from `.claude/skills/`. Thirteen skills drive the five-phase pipeline and its support work.
2. **Hooks.** Node `.mjs` scripts that Claude Code invokes synchronously at tool-call boundaries. Enforcement hooks block or annotate. Git hooks guard commits and pushes. No hook makes an outbound network call.
3. **Standards, templates, and schemas.** The reference material that skills bundle at install time.
4. **Setup scripts.** `setup.sh` and `setup.ps1` copy the above into a target project and wire `.claude/settings.json`.

The repo runs its own pipeline on the `ravintio-zero/` it ships. Git reads its hooks from `ravintio-zero/hooks` through `core.hooksPath`.

---

## Pipeline

The pipeline runs five phases, numbered P0 to P4. There is one route: every change is a feature change, and a small change is a small run. Each agent message starts with its phase prefix, then a status and a one-liner, as in `P1 Plan: Complete: 4 requirements, 2 ADRs`.

| Phase | Prefix | Owning skill |
|-------|--------|--------------|
| Discovery | `P0 Discovery:` | ravintio-orchestrator |
| Plan | `P1 Plan:` | ravintio-plan |
| Implement | `P2 Implement:` | ravintio-implement |
| Validate and accept | `P3 Validate:` | ravintio-validate-and-accept |
| Ship | `P4 Ship:` | ravintio-ship |

### Run modes

At the end of P0, the orchestrator asks how to run P1 to P4. It writes the answer, `gated` or `autonomous`, to `plan/.run-mode` and logs it. No other value is valid.

- **Gated.** The run stops for the human at the P1, P2, P3, and P4 gates. The P4 gate comes before the PR.
- **Autonomous.** The run stops at none of those gates. P3 writes its evidence to `plan/current/acceptance-evidence.md`. P4 copies it into the PR body and ends with `P4 Ship: Complete: PR #{n} ready for your review`.

On resume, a missing or unknown `plan/.run-mode` makes the orchestrator ask the question again and name the value it found.

**Exception stops.** Both modes stop and print `{prefix} Blocked: {action needed}` in these cases:

- A requirement or check still fails after 5 attempts.
- P2 needs a schema change. In a roadmap step, a change that matches a chart-approved additive row does not stop.
- The P3 security review finds an unmitigated critical or high issue.
- A push or `gh pr create` fails.
- A possible credential appears in a file the run will commit, or in the PR body.
- P1 or P2 adds a library or service that is not on the approved dependency list. The list is `design.md` "Approved dependencies" in a gated or autonomous run, and `roadmap.md` "## Dependencies" in a roadmap step.

Each stop adds a `Blocked:` line to the build log. A resumed run does not pass it until a `Resolved:` line follows.

No mode merges a PR or commits to `main`. The human merges every PR.

**Context size.** At each gate in a gated run, the orchestrator reports the context size. Past about 150,000 tokens, it recommends `/clear`.

**Ship order.** P4 creates the tag locally at Step 7. Step 8 reads the run mode, then clears the pipeline sentinels in a commit. Step 9 pushes the branch and the tag and raises the PR. Step 10 is the final gate. So the sentinels never reach `main` through the PR.

**Orchestrator references.** The orchestrator `SKILL.md` keeps the core rules and the Exception Stops table. Seven files under `skills/ravintio-orchestrator/references/` hold the rarely used sections word for word: adoption modes, discovery coaching, discovery records, mid-pipeline changes, scope lock, session commands, and the skills catalogue. The Pack Index lists each file. A line-preservation test fails if a moved line is missing.

**Model tiers.** Every Agent call passes `model`, set to `sonnet` or `haiku`. The three TDD skills set `model: haiku`. A haiku unit that fails twice retries on sonnet. A WebFetch of a full reference page goes through a sonnet or haiku subagent that returns an extract.

### Release sizing

Discovery sizes each release against a budget. The optional `releaseSize` field in `product.yml` sets it to `small`, `medium`, or `large`, and the default is `medium`. Discovery gives each candidate requirement a size class from the files it touches, then recommends a fill up to the budget.

**Park.** When the human says "park", the orchestrator shelves the feature on its branch. It writes `plan/current/park.md`, pushes the branch, and raises a `chore/park-{feature-id}` PR. That PR files a backlog entry with status `parked`. The working tree then returns to `main`. The git and `gh` steps live in the orchestrator's `scripts/park.mjs`. If a local add or commit fails on the chore branch, park unstages and deletes the entry, then returns to the feature branch. Park refuses an `--entry` that is the target path, so that cleanup never deletes the only copy. Park also refuses any symlink in the entry path. It checks each part with `lstat` and the real path against the real `plan/backlog/`, before it creates, writes, or removes anything. At a later discovery, backlog pickup offers resume or discard for a parked entry. Park and pickup never merge a PR, never commit to `main`, and never force-push.

### Roadmaps

A roadmap is a chain of feature steps that the human approves once. The standard `ravintio-zero/standards/roadmap-standards.md` holds the detail, and the orchestrator and ship skills point to it. Five stage prefixes sit beside the five phases: `R-A Chart:`, `R-B Activate:`, `R-C Run:`, `R-D Advance:`, and `R-E Delivery:`. They are stage letters, not phase numbers. The pipeline keeps exactly five phases.

- **Storage.** A draft lives in `plan/roadmap/{id}-{slug}/roadmap.md` on any branch. The one active roadmap lives in `plan/current-roadmap/roadmap.md` on the branch `roadmap/{id}-{slug}`. Roadmap ids share the backlog sequence.
- **Chart and activate.** R-A Chart runs on `main`, checks that each entry is clear enough to draft from, collects the approved dependency list, and ends with the human's single approval. That approval covers each step's predicted schema change, listed in the roadmap's `## Schema changes` table. R-B Activate cuts the roadmap branch, writes the active roadmap, and offers the driver. One roadmap is active per working tree.
- **Run.** Each step runs P0 to P4 in `autonomous` mode on a feature branch cut from the roadmap branch. P0 builds the brief from the step's backlog entries and self-confirms the design and scope lock, marked `[source: draft-accepted (roadmap)]`.
- **Advance.** At P4, the agent raises the step PR against the roadmap branch and waits for green CI. It squash-merges the PR, fetches, and tags the squash commit. Outside a roadmap, the tag still comes before the PR.
- **Delivery.** R-E Delivery archives the roadmap and raises one PR to `main` that asks for a merge commit. The human merges it.
- **Driver.** `ravintio-zero/scripts/roadmap-run.mjs` runs each step as its own `claude -p` session. A lock file at `plan/.roadmap-runner.lock` stops a second driver. The driver stops on a `Blocked:` line, a stalled `position`, or a failed `claude` call, and a restart resumes the same step. It passes `--model` (default `sonnet`) and an optional `--max-turns` to each child. A capped step that exits non-zero stops with `R-C Run: Blocked:`. Each step writes `plan/.roadmap-logs/step-{position}.log`, and the driver appends `work.kind`, `ravintio.roadmap`, and `ravintio.step` labels to the child's `OTEL_RESOURCE_ATTRIBUTES`. The label encoder is `scripts/roadmap-labels.mjs`.
- **Merge guard.** The `merge-guard` hook blocks any `gh pr merge` unless the command uses `--squash` and the PR base starts with `roadmap/`. It reads the base with `gh pr view` and blocks when it cannot read one. Merging into `main` stays human-only.

The implement phase dispatches a TDD trio per requirement: ravintio-test-writer, ravintio-implementer, and ravintio-refactor. Five support skills complete the set of thirteen: ravintio-loop-runner, ravintio-optimise-agent, ravintio-migrator, ravintio-refresh-setup, and ravintio-file-backlog.

---

## Install flow

Setup targets Claude Code only. It copies skills and hooks into `.claude/`, prunes retired skills, writes the boot file, and wires the git hooks.

```
ravintio-zero/          setup.sh claude-code          target project
├── skills/          ──────────────────────────────────▶   .claude/skills/
├── templates/       ── bundled per skill frontmatter ──▶   .claude/skills/*/assets/
├── standards/       ── bundled per skill frontmatter ──▶   .claude/skills/*/references/
├── workflows/       ──────────────────────────────────▶   .claude/commands/
├── hooks/enforcement/ ────────── always ──────────────▶   .claude/hooks/enforcement/
└── templates/standard-boot.md ───────────────────────▶   CLAUDE.md
```

Skills bundle selectively. Each `SKILL.md` declares `bundle_templates` and `bundle_standards` in its frontmatter, and setup copies only those files. A skill with no manifest gets everything.

Boot files are disposable build outputs. Every run regenerates `CLAUDE.md` from the template, then re-appends the contents of `ravintio-overrides/instructions/` between sentinel markers. Durable local customisation lives in the overrides directory, never in the boot file.

---

## Setup-config record

`setup.sh` and `setup.ps1` write the tracked record of active setup flags to `plan/state/{tool}.md`, creating the folder when it is absent. The record and the gitignored flags marker hold `tool`, `flags`, and `writtenAt`. The `ravintio-refresh-setup` skill reads and validates that record before falling back to the gitignored marker and hook inference.

---

## Enforcement model

Enforcement is deterministic where it can be, and instructional where it cannot.

**Deterministic.** A hook exits 2 with a human-readable message and Claude Code blocks the tool call. `gate-write`, `em-dash-guard`, `ratchet-check`, and `merge-guard` write the reason to stderr and stdout, so the agent sees why the call stopped. `gate-write` gates this project only. It passes a target whose real path lies outside the project's real root, and resolves symlinks first. So a link inside the project that points outside counts as outside. For an in-project target, it blocks a write that has no confirmed design or no matching declared component. `plan/`, `docs/`, and a few root files always pass. `ratchet-check` blocks weakening edits to an active loop's artifacts. `em-dash-guard` rejects U+2014 in scoped prose paths. `merge-guard` blocks a `gh pr merge` that is not a squash into a `roadmap/*` branch.

**Instructional.** Skills tell the agent what to do. The orchestrator's hard limits, the one-question-at-a-time rule, and the phase gates all rely on the agent following its instructions.

Every hook fails open on an unexpected error. Exit 0 with no output means the tool call proceeds. That is deliberate: a broken hook must never stop a session.

---

## Upgrade cleanup

Setup no longer removes legacy telemetry wiring. A consumer that last ran a setup from before 0000033 removes four items by hand:

- the `mcp__structured-telemetry-mcp__emit_event` matcher entries in `.claude/settings.json`
- `.claude/telemetry-enabled`
- `plan/.telemetry-failures/`
- `plan/.telemetry-receipts/`

Setup still prunes retired hooks. See Retired hooks under Re-run safety.

**Rename upgrade.** Version 1.0.0 renamed the pack, the overrides folder, the skills, and the marker files. If setup finds the earlier pack or overrides folder in the project root, it stops before it installs anything. It names the folder and the migration helper to run. Each run also removes the two earlier marker files when present, and skips a symlink. Skill pruning removes the earlier skill folders.

Migration 0004 and its helpers, `migrations/migrate-ravintio-rename.sh` and `.ps1`, do the upgrade. They move the overrides folder and the workflow file. Inside the workflow they rewrite the pack paths and the pack's own variables, and leave other names such as secrets. They remove the earlier markers. They never delete the earlier pack folder. They stop git tracking it and move it to `.ravintio-backup/`, which `.git/info/exclude` hides. The human deletes the backup after checking it. A conflict, an earlier backup, or a symlink at a moved path stops the helper before it moves anything. A symlinked parent folder skips only the step that writes through it, with a warning. A rerun changes nothing. After a run that changes the project, the helper moves 0004 to `migrations/_done/`.

A migration can declare an `Applies when:` condition. The orchestrator and `ravintio-migrator` skip a migration whose condition is false and leave it pending. So 0004 ships pending, and never runs in this repo.

---

## Re-run safety

Setup is safe to re-run on a project that an older release installed.

**Retired flags.** Setup accepts four flags that earlier releases removed:

- `--structured-telemetry-mcp`
- `--backend-url`
- `--context-mode-mcp`
- `--include-full-skill-library`

Each prints one warning and setup skips it. After `--backend-url`, setup also skips the next argument, unless that argument is a flag or a tool name. Setup never prints or stores that value, in either the spaced or the `=` form. Any other unknown flag still exits 1, and its error shows the flag name only. Matching is exact and case-sensitive in both scripts. The tool name also matches exactly.

PowerShell 7 splits an argument such as `--backend-url=https://x` at its first colon. `setup.ps1` skips the rest of the value too, and never prints a tool name that isn't a plain name.

**Retired hooks.** Both scripts prune a hook only if its name is on the retired list, which `setup.sh` keeps as `RETIRED_HOOK_NAMES` and `setup.ps1` as `$RetiredHookNames`. Pruning deletes the installed hook file. The hook install step also drops each `settings.json` entry that runs a retired hook, on every event. A hook that is not on the list stays.

**Write failures.** One catch around the shared `writeSettings` prints a fixed line with the relative path and exits 1. It covers the hook install and the allowed-tools write, and `setup.ps1` prints the same line.

**Atomic settings writes.** Every `settings.json` write goes to `settings.json.ravintio-tmp` in the same folder first, then replaces the target. So `settings.json` is always the old file or the new one. Setup removes a leftover temporary file before it writes, and creates the new one exclusively, so it never follows a planted link. The new file keeps the original's mode, or its ACL on Windows. Setup leaves a read-only `settings.json` unchanged. `setup.sh` writes a symlinked `settings.json` through to its real file. Other files setup writes, such as the boot file, are rewritten whole on each run.

**Leftover temporary file.** Each run removes a leftover `settings.json.ravintio-tmp` before its first settings write, even when `node` is missing. It removes a file or a link, never a folder, and never follows a link.

**Two scripts, one result.** `setup.sh` and `setup.ps1` wire the same seven hooks, in the same events, matchers, and order. A parity suite fails if they drift. `setup.ps1` runs on Windows PowerShell 5.1 and PowerShell 7. It reads and writes `settings.json` as UTF-8 with no BOM. Flags and the tool name match case in both scripts.

**Hook entry repair.** Both scripts find a RAVINTIO `PreToolUse` entry by its module name, on any matcher. So an older `Write|Edit` entry gives way to one `Write` entry and one `Edit` entry, and `gate-write` runs once per tool. If `PreToolUse` or `UserPromptSubmit` holds a value that isn't an array, setup prints a warning that names the event and the file. The warning never prints the old value, because a hook command can hold a secret. It then replaces the value with the RAVINTIO entries and exits 0. An absent or null value gets the entries with no warning.

**Per-command filter.** Both scripts filter `PreToolUse` and `UserPromptSubmit` one command at a time. Setup removes each RAVINTIO command and keeps any user command in the same entry. If an entry holds only RAVINTIO commands, setup drops it. A `hooks` value that holds one object counts as a one-item array, so setup filters it the same way. An entry with no commands stays as it was. A command counts as RAVINTIO only when it runs `<module>.mjs` at a path boundary, matched case-sensitively.

**Invalid JSON.** If `settings.json` isn't valid JSON, the hook install step prints one fixed line that names the file. The line never holds the file's contents. Setup leaves the file unchanged and exits 1, because it can't install the hooks.

**Not a settings object.** If `settings.json` is valid JSON but not a settings object, both scripts print one fixed line that names the file. That covers a top level that isn't an object, and a `hooks` value that is present and isn't an object. Setup leaves the file unchanged and exits 1. `setup.ps1` also gives this line for keys that differ only by case, because `ConvertFrom-Json` can't read them. `setup.sh` accepts those keys, because Node reads them.

**Nesting cap.** `setup.ps1` checks JSON nesting with a counter and a stack, so the check runs in linear time. Nesting deeper than 1024 levels gets the not-a-settings-object line.

**JSON depth.** `setup.ps1` writes `settings.json` with `ConvertTo-Json -Depth 100`, so a deeply nested user value survives a rewrite.

---

## Tests

A wording test greps every tracked file outside history for the retired word that once described RAVINTIO Zero. It passes only lines that match an allowlist of generic uses. A phase guard test fails on a phase number outside P0 to P4 or on a retired letter prefix. A brand guard test fails on any tracked path or line outside history that holds the earlier product name, unless an allowlist entry matches. It also fails on a stale allowlist entry.

`ravintio-zero/tests/run-tests.sh` runs every Bash and PowerShell suite. Before any suite runs, it checks every file under `tests/`. A file that is neither a suite nor on its known list fails the run, and the runner names it. Without `pwsh`, it prints how many PowerShell suites it skipped.

Set `RAVINTIO_TEST_QUIET=1` to hide PASS lines and banners. The runner then keeps every FAIL line with its detail, the failing suite name, the summary, and the exit codes. A quiet full run prints about 3 KB. Skills that run the full suite set it.

The PowerShell suites run `setup.ps1` in temporary projects. In CI, the `windows-powershell` job runs them as a two-entry matrix, one entry for Windows PowerShell 5.1 and one for PowerShell 7. The entries run in parallel and neither cancels the other. Helpers print per-case timing. The `bash-suites` job runs `run-tests.sh` on `ubuntu-latest` with `RAVINTIO_REQUIRE_PWSH=1`. So it runs every Bash suite and fails if `pwsh` is missing.

---

## Version derivation

`product.yml` holds the product-level version manifest. Under `versionPolicy: max-component-version`, `scripts/product-version.mjs` reads each listed `component.yml` live and takes the highest. Nothing caches a version, so the list only changes when a component is added or removed.

This project has one component and keeps `product.yml` anyway. Its top-level `id` gives the product a stable name for versioning and for attributing archived runs, wherever the repo is cloned. The orchestrator hard-stops at discovery when that `id` is missing.

The five phase names live in prose in `ravintio-zero/pipeline-reference.md`. No module encodes them.
