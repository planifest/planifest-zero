# Getting Started with Planifest

> Step-by-step instructions for humans setting up a Planifest project.
> For day-to-day operations reference, see [project-operations.md](project-operations.md). For deep pipeline mechanics, see [pipeline-reference.md](pipeline-reference.md).

---

## Prerequisites

- Claude Code
- Node (the hooks and scripts run as `node` scripts)
- A terminal with Bash (macOS/Linux) or PowerShell (Windows)

---

## New Project

### 1. Add the framework

Copy the `planifest-zero/` folder into your repository root. This folder is all you need. It contains the skills, templates, standards, hooks, and setup scripts.

### 2. Create the project structure

```
mkdir -p plan/current plan/changelog plan/backlog src docs
```

These are the core working directories:

- `plan/` holds the change in progress and its records.
  - `plan/current/` is the change in progress: `feature-brief.md`, `design.md`, `build-log.md`, and the plan artifacts.
  - `plan/_archive/` holds completed runs, filed at ship.
  - `plan/changelog/` holds one change record per feature (`{feature-id}-{YYYY-MM-DD}.md`).
  - `plan/backlog/` holds deferred items.
- `src/` holds component source code, tests, and component manifests (`component.yml`).
- `docs/` holds the living repository documentation, always current. It includes the component registry and dependency graph.
- `planifest-overrides/` holds your customisations: project instructions, capability skills, setup config, and library standards. Setup never overwrites it. See [project-operations.md, Customising](project-operations.md#customising-with-planifest-overrides).

See [feature-structure.md](../plan/feature-structure.md) for the full layout.

### 3. Run the setup script

Claude Code is the only tool target.

#### Basic setup

```bash
# macOS / Linux
chmod +x planifest-zero/setup.sh
./planifest-zero/setup.sh claude-code
```

```powershell
# Windows (PowerShell)
.\planifest-zero\setup.ps1 claude-code
```

Setup installs:

- Skill folders with YAML frontmatter into `.claude/skills/`, auto-discovered by Claude Code. Retired skills are pruned.
- Supporting files (templates, standards, schemas) bundled per skill.
- Enforcement hooks wired into `.claude/settings.json`.
- The `CLAUDE.md` boot file.
- Git hooks and the orchestrator sentinel machinery, activated automatically.

#### Option: structured telemetry

Requires [structured-telemetry-mcp](https://github.com/anthropics/structured-telemetry-mcp) to be running, then pass `--structured-telemetry-mcp`:

```bash
./planifest-zero/setup.sh claude-code --structured-telemetry-mcp
```

```powershell
.\planifest-zero\setup.ps1 claude-code --structured-telemetry-mcp
```

→ **Git guardrails and the orchestrator sentinel** are activated automatically by setup. See [project-operations.md](project-operations.md) for how they work and how to enable strict mode.

### 4. Write your first feature brief

Use the template:

```
cp planifest-zero/templates/feature-brief.template.md plan/current/feature-brief.md
```

Fill it in. The [feature brief guide](templates/feature-brief-guide.md) walks you through each section.

Every agent response begins with a phase prefix (`D:`, `PL:`, `IM:`, `VA:`, `SH:`), so you always know where you are in the pipeline. See [pipeline-reference.md, Phase indicators](pipeline-reference.md#phase-indicators) for the full table.

### 5. Start the orchestrator

Open Claude Code in the project. The auto-trigger hook loads the orchestrator skill at the start of the session. Tell it:

```
Run the Planifest pipeline.
Feature brief: plan/current/feature-brief.md
```

The orchestrator runs discovery: it assesses your brief, coaches you through any gaps, and produces a confirmed design. It then asks whether you want per-phase confirmation or a continuous run before executing the rest of the pipeline.

Every change takes this route. A small change is a small run, not a different pipeline.

---

## Next Steps

| Topic | Where to look |
|-------|---------------|
| Git guardrails and how enforcement works | [project-operations.md](project-operations.md#git-guardrails) |
| Orchestrator sentinel and strict mode | [project-operations.md](project-operations.md#orchestrator-sentinel) |
| Customising with planifest-overrides | [project-operations.md](project-operations.md#customising-with-planifest-overrides) |
| Updating the framework | [project-operations.md](project-operations.md#updating-the-framework) |
| What to commit | [project-operations.md](project-operations.md#what-to-commit) |
| Retrofit an existing project | [project-operations.md](project-operations.md#retrofit-an-existing-project) |
| Phase mechanics and confirmation gates | [pipeline-reference.md](pipeline-reference.md) |
| The 12 skills and who dispatches whom | [pipeline-reference.md, Skills](pipeline-reference.md#skills) |
