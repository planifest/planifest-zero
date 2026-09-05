# Pipeline Reference

> Deep reference for Planifest pipeline mechanics. For first-time setup, start with [getting-started.md](getting-started.md).

---

## One Route

Every change is a feature change. It runs the five-phase feature pipeline: discovery, plan, implement, validate and accept, ship. A small change is a small run: fewer requirements, shorter artifacts, the same gates. There is no separate route for trivial fixes or targeted changes.

---

## Phase Indicators

Every agent response begins with a phase prefix. You always know where you are.

| Prefix | Phase | What the agent is doing |
|--------|-------|-------------------------|
| `D:` | Discovery | Assessing the brief, asking gap questions, confirming scope, version, and adoption mode |
| `PL:` | Plan | Writing requirements, scope, glossary, risk register, and ADRs behind one confirmation gate |
| `IM:` | Implement | Generating code, tests, and documentation together |
| `VA:` | Validate and accept | Running CI checks, self-correcting, security review, human acceptance |
| `SH:` | Ship | Changelog, archive, build assessment, git tag, PR |

Standard response formats:

- Entering a phase: `PL: Starting, {one-liner}`
- Resuming: `PL: Resuming, {what was in progress, what is next}`
- Completing: `PL: Complete, {one-liner summary}`
- Blocked: `D: Blocked, {specific gap}`
- Skipped: `VA: Skipped, {reason}`

If you see a `Resuming` message at the start of a session, the orchestrator detected existing artifacts in `plan/current/` and is continuing where it left off.

---

## Skills

Twelve skills drive the pipeline.

| Skill | Role |
|-------|------|
| `planifest-orchestrator` | Owns discovery and routing. Coordinates the run end to end |
| `planifest-plan` | Plan phase: requirements, scope, risk register, glossary, ADRs |
| `planifest-implement` | Implement phase: dispatches the TDD trio per requirement and writes the documentation |
| `planifest-validate-and-accept` | Validate-and-accept phase: CI checks, security review, human acceptance gate |
| `planifest-ship` | Ship phase: changelog, archive, build assessment, tag, PR |
| `planifest-test-writer` | TDD red: writes one failing test per requirement and confirms RED |
| `planifest-implementer` | TDD green: writes the minimum code to make that test pass |
| `planifest-refactor` | TDD refactor: improves quality while all tests stay passing |
| `planifest-loop-runner` | Canonical loop mechanics: state files, stop rules, escalation format |
| `planifest-optimise-agent` | Reviews skills for superfluous content, one suggestion at a time |
| `planifest-migrator` | Applies pending framework migrations interactively |
| `planifest-refresh-setup` | Re-runs setup with the flags currently in effect |

The TDD trio (`planifest-test-writer`, `planifest-implementer`, `planifest-refactor`) is dispatched by `planifest-implement`, once per requirement.

---

## Phase Confirmation Gates

At the end of each phase, the orchestrator **stops and presents a summary** before proceeding. Before the pipeline begins (end of discovery), you are asked:

```
Do you want to review and confirm after each phase completes, or authorise a
continuous run for this session?

  [1] Check after each phase
  [2] Continuous run: proceed without phase confirmations
```

The orchestrator may skip a stop only when **both** conditions are true:

- You chose continuous run, AND
- There is genuinely nothing to check (for example, validate and accept with every check passing on the first attempt and zero security findings)

**Ship always stops before the PR.** Raising a PR is an external action. It is never auto-confirmed, even in continuous run mode.

---

## Ship Phase

Ship is the terminal phase. It runs three steps in order.

1. **Archive.** The changelog entry is written to `plan/changelog/{feature-id}-{YYYY-MM-DD}.md`, then `plan/current/` is archived to `plan/_archive/{feature-id}-{date}/` and cleared. The orchestrator sentinel is deleted last, after the archive is confirmed complete.
2. **Build assessment.** An assessment sub-agent reads the archived `build-log.md` and produces a structured efficiency report at `plan/_archive/{feature-id}-{date}/build-report.md`.
3. **Tag and PR.** The agent reads the version from `component.yml`, creates a local git tag (`v{version}`), then asks the human whether to push and raise the PR or output a PR description for manual use. If `local-git-only` is active in `planifest-overrides/instructions/`, the agent skips the prompt and outputs a PR description directly.

### Build Log

From discovery onwards, the orchestrator maintains `plan/current/build-log.md`, a working file tracking per-phase telemetry. It is created from `planifest-zero/templates/build-log.template.md` at discovery and appended at each phase boundary. If a session is interrupted and resumed, the orchestrator appends rather than overwrites.

The build log records per phase: model tier used, skills loaded, agents spawned, MCP tool calls, parallel task batch count.

### What the build assessment checks

The assessment is adversarial, not a summary. It asks:

- **Model routing**: which phases used the primary tier when cheaper-tier tasks were eligible?
- **Parallelism**: which phases ran tasks sequentially that should have been parallel?
- **Phase gates**: were human confirmation gates honoured, or did the pipeline run autonomously without authorisation?
- **Self-corrections**: how many occurred, and were they avoidable?
- **Build log integrity**: are all phases represented with populated fields?

---

## Model Tier Routing

The orchestrator consults the **Model Tier Decision Table** before spawning every subagent, then passes the resolved model explicitly.

| Task type | Tier |
|-----------|------|
| Codebase discovery (grep, find, ls) | Cheaper |
| Single-file read with no synthesis | Cheaper |
| Formatting / spelling / lint checks | Cheaper |
| Validation (lint, typecheck, test runner) | Cheaper |
| Fetching a single known reference doc | Cheaper |
| Documentation writing (no novel decisions) | Cheaper |
| Build assessment | Cheaper |
| Web research with synthesis | Primary |
| Code generation | Primary |
| Security review | Primary |
| ADR writing | Primary |
| Spec / requirements writing | Primary |
| Discovery coaching | Primary |

Tier-to-model mapping for Claude Code: primary is `claude-sonnet-4-6`, cheaper is `claude-haiku-4-5`.

---

## Enforcement Hooks

Setup wires the enforcement hooks into `.claude/settings.json` on every install. All of them are Node `.mjs` scripts under `hooks/enforcement/`.

| Hook | Trigger | What it does |
|------|---------|--------------|
| `gate-write` | PreToolUse (Write, Edit) | Blocks writes to `src/` unless `plan/current/design.md` exists and the target path matches a declared component |
| `ratchet-check` | PreToolUse (Write, Edit) | While a loop or reversal is active, blocks edits that weaken acceptance criteria or in-scope lines in `plan/current/` |
| `em-dash-guard` | PreToolUse (Write, Edit) | Rejects U+2014 in scoped prose paths |
| `check-design` | UserPromptSubmit | Injects active component scope from `design.md`, or a hard STOP when no brief or sentinel exists |
| `check-orchestrator-presence` | UserPromptSubmit | Injects a reminder banner while a pipeline is active. Hard-blocks under strict mode |
| `auto-trigger-orchestrator` | UserPromptSubmit | Loads the orchestrator skill at session start when no pipeline is active yet |
| `check-telemetry-failures` | UserPromptSubmit | Surfaces durable telemetry failure markers from `plan/.telemetry-failures/` |
| `check-telemetry-receipts` | Phase boundaries | Verifies that expected telemetry receipts exist for the phase |

A blocking hook exits 2 with a human-readable message. Every hook fails open on an unexpected error, so a broken hook never stops a session.

---

## Telemetry Hooks

Telemetry is one concern with one switch: `--structured-telemetry-mcp` at setup. When active, setup installs `hooks/telemetry/` and emission is mandatory rather than best-effort.

- `resolve-phase` interposes on the Skill tool via PreToolUse, resolves the active phase from the skill name, and re-execs `emit-phase-start`.
- A Stop hook re-execs `emit-phase-end` from a session marker file, cleared after use.
- `emit-event-receipt` records a receipt for every emitted event, checked by `check-telemetry-receipts`.
- `context-pressure` reports a context fill estimate.
- The shared `emit-event` module posts each event to the backend at `PLANIFEST_TELEMETRY_URL`, with `product_id` read from `product.yml`.

The `phase` field takes one of five values: `discovery`, `plan`, `implement`, `validate-and-accept`, `ship`. The canonical enum lives in `hooks/enforcement/phase-enum.mjs` and is mirrored in `standards/telemetry-standards.md`.

When emission fails, the hook writes a durable marker under `plan/.telemetry-failures/`. The orchestrator surfaces the marker at the next phase start and asks the human whether to block or proceed.

---

## Git Guardrails

The setup script activates Planifest's **Progressive Guardrail System**, a three-tier enforcement model that protects `main` without blocking atomic commits.

| Tier | When | What happens |
|------|------|--------------|
| **1: Advisory pre-commit** | Every local commit | Checks whether code was staged without docs. Prints a warning if so. Commit **succeeds** regardless. |
| **2: Branch pre-push** | Every `git push` | Checks the cumulative branch diff. Push **fails** if `src/` was changed with no corresponding update to `plan/`, `docs/`, or `component.yml`. |
| **3: CI/CD pipeline** | Every pull request | Same check in GitHub Actions. Blocks the merge button if the rule is violated. |

One parity check applies to every diff. There is no relaxed rule for any commit prefix.

### commit-msg hook

A fourth git hook validates every commit message against `standards/commit-standards.md`. It blocks AI attribution lines, affirmatory language, and subjects over 72 characters. It exits 1 on violation. Use `git commit --no-verify` to bypass intentionally.

### Hook file locations

| File | Purpose |
|------|---------|
| `planifest-zero/hooks/pre-commit` | Tier 1 advisory check |
| `planifest-zero/hooks/pre-push` | Tier 2 blocking check |
| `planifest-zero/hooks/commit-msg` | Commit message validation |
| `.github/workflows/planifest.yml` | Tier 3 CI check (copied to the repo on first setup) |

Hooks are wired via `git config core.hooksPath planifest-zero/hooks`, with no `.git/` directory modifications. Hooks travel with the repo and apply to every contributor who has run `setup.sh`.

### What happens on a Tier 2 violation

The push is rejected with a message naming the rule: `src/` was modified with no corresponding update under `plan/`, `docs/`, or any `component.yml`. To fix it, update `plan/` or `docs/` to reflect the `src/` change, then push again.

---

## Orchestrator Sentinel

### Lifecycle

When discovery starts, the orchestrator writes `plan/.orchestrator-active` containing the active feature-id (for example `0000002-doc-structure`). This file is the sentinel. Its presence signals that a pipeline run is in progress. It is deleted **last** during ship, after the archive is confirmed complete.

```
Discovery start     → plan/.orchestrator-active written ("pending" until feature-id confirmed)
Discovery complete  → plan/.orchestrator-active updated with confirmed feature-id
Plan to validate    → sentinel present, hooks enforce scope on every turn
Ship complete       → plan/.orchestrator-active deleted (final cleanup step)
```

### Sentinel enforcement hooks

| Hook | Trigger | What it does |
|------|---------|-------------|
| **gate-write** (PreToolUse: Write, Edit) | Every file write or edit | Blocks writes outside always-permitted paths (`plan/`, `docs/`, `planifest-zero/`) unless `plan/current/design.md` exists AND the target path matches a declared component in the design |
| **check-orchestrator-presence** (UserPromptSubmit) | Every user prompt while the sentinel is present | Injects a reminder banner so the orchestrator skill reloads after context compaction or session resume. Advisory by default, see Strict Mode below |
| **check-design** (UserPromptSubmit) | Every user prompt | If neither the sentinel nor a `feature-brief.md` is present, injects a hard STOP message before the agent can act. Prevents free-form changes outside the pipeline |

### How gate-write interacts with design.md

`gate-write` checks two conditions before allowing a write to `src/`:

1. `plan/current/design.md` must exist
2. The target file path must be under a component directory declared in the design's `## Engineering Layer → Components` section

Writes to `plan/`, `docs/`, `planifest-zero/`, and `planifest-overrides/` are always permitted. `gate-write` never blocks documentation or plan artifact writes.

### Manual recovery

If a pipeline run is interrupted and you want to start fresh:

```bash
# 1. Delete the sentinel
rm plan/.orchestrator-active

# 2. Delete the active feature brief
rm plan/current/feature-brief.md

# 3. Optionally clear the current plan artifacts
rm -rf plan/current/

# 4. Reload the orchestrator. It begins a fresh discovery.
```

Do not delete `plan/_archive/` or `plan/changelog/`. These are historical records.

---

## Strict Orchestrator Mode

By default, `check-orchestrator-presence` is advisory. It injects a reminder banner but never blocks the session. Strict mode turns this into a hard gate.

### How it works

Enable strict mode at setup time:

```bash
# macOS / Linux
./planifest-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
# Windows (PowerShell)
.\planifest-zero\setup.ps1 claude-code --strict-orchestrator
```

This writes `plan/.orchestrator-strict`. When that file is present, `check-orchestrator-presence` changes behaviour:

1. **On every new session**, it injects a hard-block banner that prevents the agent from acting until the orchestrator skill loads
2. **When the orchestrator loads**, it reads the `session_id` from the banner (injected by the hook) and writes it to `plan/.orchestrator-ack`
3. **On subsequent prompts in the same session**, the hook reads `plan/.orchestrator-ack`, sees the current session_id matches, and passes silently
4. **During ship**, the agent deletes `plan/.orchestrator-ack` so the next session starts clean

### The ack file

`plan/.orchestrator-ack` contains either:

- The `session_id` value injected by the hook banner (if available in the prompt context), or
- The current UTC timestamp in ISO 8601 format (fallback when no session_id is present)

The hook compares the stored value against the current session to determine whether the orchestrator has loaded in this session. The ack file is session-scoped, one value per pipeline session.

---

## Retrofit an Existing Project

Adoption modes let the pipeline start from a codebase that already has source code.

1. Copy `planifest-zero/` into your repo root
2. Run the setup script (see [getting-started.md](getting-started.md#3-run-the-setup-script))
3. Add a `component.yml` manifest to each existing component in `src/`, using the [component manifest template](templates/component.template.yml) and [guide](templates/component-guide.md)
4. Tell the orchestrator to use **retrofit** adoption mode:

```
Run the Planifest pipeline in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

In retrofit mode, discovery includes a codebase scan before coaching. The orchestrator scans entry points and build files, identifies candidate components, maps data ownership, discovers API contracts, notes conventions the pipeline must preserve, and flags tech debt into the risk register. It then presents a discovery summary. Many coaching questions are pre-answered by the scan.

---

## Updating the Framework

"Updating the framework" means pulling new files into `planifest-zero/` (via git pull, a submodule update, or copying from the source repo) and then re-running the setup script to propagate the changes.

### Re-run setup after update

Pass the same flags you used during initial setup. Re-running is idempotent. It overwrites generated copies, prunes retired skills, and writes the setup-flags record to `plan/state/{tool}.md`. If a pre-relocation record for the tool still exists under `planifest-overrides/`, setup removes it inline and otherwise leaves `planifest-overrides/` alone. The `planifest-refresh-setup` skill can reconstruct the flags in effect from `plan/state/{tool}.md` and re-run setup for you.

```bash
# macOS / Linux, basic
./planifest-zero/setup.sh claude-code

# macOS / Linux, with telemetry
./planifest-zero/setup.sh claude-code --structured-telemetry-mcp
```

```powershell
# Windows (PowerShell), basic
.\planifest-zero\setup.ps1 claude-code

# Windows (PowerShell), with telemetry
.\planifest-zero\setup.ps1 claude-code --structured-telemetry-mcp
```

### Check for pending migrations

After pulling a new version of `planifest-zero/`, check for pending migrations before starting a new pipeline run:

```bash
ls planifest-zero/migrations/*.md 2>/dev/null | grep -v _done
```

```powershell
Get-ChildItem planifest-zero/migrations/*.md | Where-Object { $_.FullName -notmatch '_done' }
```

If any `.md` files appear outside `_done/`, the orchestrator detects them at session start and invokes `planifest-migrator` before any pipeline work. You do not need to run migrations manually.

---

## What to Commit

| Path | Commit? | Why |
|------|:-------:|-----|
| `planifest-zero/` | Yes | Source of truth, shared with the whole team |
| `planifest-zero/hooks/` | Yes | Git hooks and CI workflow, applied by setup scripts |
| `.github/workflows/planifest.yml` | Yes | CI/CD gate, must be committed to take effect in GitHub Actions |
| `plan/` | Yes | Feature briefs, execution plans, ADRs, scope docs. Design history |
| `plan/state/` | Yes | Machine-written setup-flags record per tool, for example `plan/state/claude-code.md`. Rewritten by every setup run, but stays git-tracked |
| `src/` | Yes | Component code and manifests |
| `docs/` | Yes | Repo-wide registry and dependency graph |
| `planifest-overrides/` | Yes | Customisations, must be committed to be shared |
| `.claude/` | Optional | Generated copies, can be `.gitignore`d and regenerated by `setup.sh` |
| `CLAUDE.md` | Optional | Boot file, regenerated by setup. Commit it if you want it in the repo for contributors |
| `.claude/telemetry-enabled` | Optional | Telemetry opt-in sentinel. Commit to enable telemetry for the whole team, omit to keep it per-developer |

### When to commit plan/

Commit `plan/current/` artifacts throughout the pipeline run, not only at ship. Each phase produces artifacts (design, requirements, ADRs, execution plan) that are worth preserving in git history as they are written. On a feature branch this is low risk and provides a clear record of how the design evolved. Ship archives the completed plan to `plan/_archive/` and clears `plan/current/`, and that is a separate commit, not the first one.

### What "Optional" means

Optional paths are generated by the setup script from sources in `planifest-zero/`. You can safely `.gitignore` them and instruct contributors to run `setup.sh` after cloning. This keeps the repo lean. Alternatively, commit them so contributors get the files without running setup. Both approaches work.

`planifest-overrides/` is never optional. It contains your customisations and must be committed to be shared.

---

## Customising with planifest-overrides

`planifest-overrides/` is your customisation layer, committed to the repo and never overwritten by setup scripts.

### instructions/

Project-specific instructions appended to the `CLAUDE.md` boot file on every setup run. Idempotent: re-running setup replaces the previous block.

```
planifest-overrides/
└── instructions/
    └── 01-project-context.md
    └── 02-naming-conventions.md
```

Files are sorted alphabetically and appended between HTML comment markers.

### capability-skills/

Permanent agent skills for this project. Each skill is a directory containing a `SKILL.md` with standard frontmatter. Setup copies them into `.claude/skills/` alongside the built-in Planifest skills:

```
planifest-overrides/
└── capability-skills/
    └── my-project-skill/
        └── SKILL.md
```

### library-standards/

Override framework library preferences per language. Files here take precedence over `planifest-zero/standards/library-standards/`:

```
planifest-overrides/
└── library-standards/
    └── typescript/
        └── prefer-avoid.md    ← replaces the framework default for TypeScript
```

Agents check `planifest-overrides/library-standards/` first. Structure matches the framework default.

---

*Source of truth: `planifest-zero/`. See [getting-started.md](getting-started.md) for setup steps.*
