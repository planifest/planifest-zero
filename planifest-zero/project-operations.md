# Project Operations

> Day-to-day operations reference for Planifest projects. For first-time setup, start with [getting-started.md](getting-started.md). For detailed step-by-step coverage of every topic on this page, see [pipeline-reference.md](pipeline-reference.md).

---

## Git Guardrails

The setup script activates a **three-tier Progressive Guardrail System** that protects `main` without blocking atomic commits.

| Tier | When | Effect |
|------|------|--------|
| **1: Advisory pre-commit** | Every local commit | Warns if code was staged without docs. Commit **succeeds**. |
| **2: Branch pre-push** | Every `git push` | Fails if `src/` changed with no update to `plan/`, `docs/`, or `component.yml`. |
| **3: CI/CD pipeline** | Every pull request | Same check in GitHub Actions. Blocks the merge button on violation. |

A `commit-msg` hook also validates every commit message. It blocks AI attribution, affirmatory language, and subjects over 72 characters.

Hooks live in `planifest-zero/hooks/` and are wired via `git config core.hooksPath`. No `.git/` modifications required. The CI workflow is copied to `.github/workflows/planifest.yml` on first setup.

→ [Detailed guardrail mechanics and hook file locations](pipeline-reference.md#git-guardrails)

---

## Orchestrator Sentinel

When discovery starts, the orchestrator writes `plan/.orchestrator-active` containing the active feature-id. Hooks check for it on every turn:

| Hook | What it does |
|------|-------------|
| **gate-write** (PreToolUse) | Blocks writes outside always-permitted paths unless `plan/current/design.md` exists and the target path is a declared component |
| **check-orchestrator-presence** (UserPromptSubmit) | Injects a reminder banner on every prompt while a pipeline is active, so the orchestrator skill reloads after context compaction or session resume |
| **check-design** (UserPromptSubmit) | Injects a hard STOP message if neither the sentinel nor a `feature-brief.md` is present |
| **auto-trigger-orchestrator** (UserPromptSubmit) | Loads the orchestrator skill at the start of a session when no pipeline is active yet |

The sentinel is deleted last during ship, after the archive is confirmed complete. You never create or delete it manually.

**If a pipeline run is interrupted** and you want to start fresh: delete `plan/.orchestrator-active` and `plan/current/feature-brief.md`, then reload the orchestrator.

→ [Full sentinel lifecycle, hook internals, gate-write interaction with design.md, and manual recovery](pipeline-reference.md#orchestrator-sentinel)

---

## Strict Orchestrator Mode

By default, `check-orchestrator-presence` is advisory. It injects a reminder banner but never blocks. Enable **strict mode** for stronger enforcement:

```bash
# macOS / Linux
./planifest-zero/setup.sh claude-code --strict-orchestrator
```

```powershell
# Windows (PowerShell)
.\planifest-zero\setup.ps1 claude-code --strict-orchestrator
```

This writes `plan/.orchestrator-strict`. When present, the hook injects a **hard-block banner** on every new session until the orchestrator loads and writes a session acknowledgement to `plan/.orchestrator-ack`. Subsequent prompts in the same session pass silently. The ack file is deleted during ship so each new pipeline starts clean.

→ [Strict mode internals, ack file lifecycle, and session_id protocol](pipeline-reference.md#strict-orchestrator-mode)

---

## Customising with planifest-overrides

`planifest-overrides/` is your customisation layer. It is committed to the repo and never overwritten by setup scripts.

| Directory | Purpose |
|-----------|---------|
| `instructions/` | Project-specific instructions appended to the `CLAUDE.md` boot file on every setup run. Files sorted alphabetically and injected between HTML comment markers. |
| `capability-skills/` | Permanent agent skills installed alongside built-in Planifest skills on every setup run. Each skill is a directory containing a `SKILL.md`. |
| `library-standards/` | Override framework library preferences per language. Agents check here before the framework defaults. Structure mirrors `planifest-zero/standards/library-standards/`. |

The tracked record of setup flags per tool lives at `plan/state/{tool}.md`, not under `planifest-overrides/`. The setup script writes it, and the `planifest-refresh-setup` skill reads it.

→ [Full directory structure, file formats, and examples](pipeline-reference.md#customising-with-planifest-overrides)

---

## Updating the Framework

After pulling new files into `planifest-zero/`, re-run the setup script to propagate changes. Pass the same flags used during initial setup. Re-running is idempotent, and it prunes skills the new version has retired.

```bash
# macOS / Linux
./planifest-zero/setup.sh claude-code
./planifest-zero/setup.sh claude-code --structured-telemetry-mcp
```

```powershell
# Windows (PowerShell)
.\planifest-zero\setup.ps1 claude-code
.\planifest-zero\setup.ps1 claude-code --structured-telemetry-mcp
```

After updating, check `planifest-zero/migrations/` for any pending `.md` files. The orchestrator handles them automatically at next session start via the `planifest-migrator` skill.

→ [Full update protocol and migration handling](pipeline-reference.md#updating-the-framework)

---

## What to Commit

| Path | Commit? | Why |
|------|:-------:|-----|
| `planifest-zero/` | Yes | Source of truth, shared with the team |
| `planifest-zero/hooks/` | Yes | Git hooks and CI workflow, applied by setup scripts |
| `.github/workflows/planifest.yml` | Yes | CI/CD gate, must be committed to take effect |
| `plan/` | Yes | Feature briefs, execution plans, ADRs, scope docs. Commit throughout the pipeline run, not only at ship |
| `plan/state/` | Yes | Machine-written setup-flags record per tool, rewritten by every setup run. Git-tracked state, not a `planifest-overrides/` customisation |
| `src/` | Yes | Component code and manifests |
| `docs/` | Yes | Repo-wide registry and dependency graph |
| `planifest-overrides/` | Yes | Customisations, committed to share with the team |
| `.claude/` | Optional | Generated copies, can be `.gitignore`d and regenerated by setup |
| `CLAUDE.md` | Optional | Boot file, regenerated by setup |
| `.claude/telemetry-enabled` | Optional | Telemetry opt-in sentinel |

→ [What "Optional" means and commit message standards](pipeline-reference.md#what-to-commit)

---

## Retrofit an Existing Project

Add Planifest to a codebase that already has source code.

1. Copy `planifest-zero/` into your repo root
2. Run the setup script (see [getting-started.md, Run the setup script](getting-started.md#3-run-the-setup-script))
3. Add a `component.yml` manifest to each existing component in `src/`, using the [component manifest template](templates/component.template.yml) and [guide](templates/component-guide.md)
4. Tell the orchestrator to use **retrofit** adoption mode:

```
Run the Planifest pipeline in retrofit mode.
Feature brief: plan/current/feature-brief.md
```

In retrofit mode, discovery includes a codebase scan before coaching. The orchestrator scans entry points, maps data ownership, discovers API contracts, and surfaces tech debt, then uses those findings to reduce the coaching questions you need to answer.

→ [Retrofit discovery scan details](pipeline-reference.md#retrofit-an-existing-project)
