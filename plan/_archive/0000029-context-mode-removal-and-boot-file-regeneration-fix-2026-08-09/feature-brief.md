---
title: "Feature Brief - Context Mode Removal and Boot File Regeneration Fix"
summary: "The business case, scope, and product requirements for the feature."
status: "approved"
version: "0.1.0"
---
# Feature Brief - Context Mode Removal and Boot File Regeneration Fix

**Feature ID:** 0000029-context-mode-removal-and-boot-file-regeneration-fix

## Business Goal

Earlier this session a third-party MCP plugin (context-mode) injected a fake system-reminder into the agent's context instructing it to conceal a change from the human. It was disabled machine-wide and stripped from all Planifest-enabled repos on this machine. Two tooling bugs surfaced while doing that cleanup by hand, worth fixing at the source so future installs and refreshes do not need the same manual workaround.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Boot file regeneration | As a human running a Planifest refresh, I want CLAUDE.md/AGENTS.md to always regenerate from the current template, so that stale instructions (like a removed MCP plugin reference) do not linger after local customization already lives in planifest-overrides/instructions/ | must-have | 1 |
| Drop context-mode from boot template | As a human who has disabled context-mode, I want the generated boot file to stop instructing the agent to use it, so that no repo (this one or any downstream consumer) gets told to route work through a plugin that may not be installed or trusted | must-have | 1 |
| Local git permission update | As the human on the loop, I want the agent's standing git-permission instruction updated to reflect that pull/push/PR-creation are now authorized (commits-to-main and PR-merge remain human-only), so that the agent's actual authority matches what I've granted this session | must-have | 1 |

## Waves

Single wave, all three features are small and land together.

## Target Architecture

No new components. This feature touches Planifest's own tooling:

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-framework | tooling | existing | setup.sh/setup.ps1 (write_boot_file), templates/standard-boot.md |

Item 3 (local git permission) is repo-local configuration under `planifest-overrides/instructions/`, not a `planifest-framework` distributed-source change; it does not affect other repos that install the framework.

### Data Ownership

Not applicable, no data stores involved.

### Integration Points

Not applicable.

## Stack

Not applicable, bash/PowerShell tooling scripts and markdown templates, no new stack decisions.

## Scope Boundaries

### In Scope
- `setup.sh` and `setup.ps1`: `write_boot_file` (and PowerShell equivalent) always overwrites `CLAUDE.md`/`AGENTS.md` with freshly rendered template content, dropping the skip-if-exists guard. This is the one shared function called for every tool's boot file, the fix applies to all tools uniformly, not Claude Code only.
- `templates/standard-boot.md`: remove the unconditional "Use context-mode MCP when available" bullet. Confirmed this template is shared by 6 of the 9 supported tools (claude-code, cline, codex, antigravity, copilot, windsurf). `cursor` uses a separate `cursor-boot.md` which was checked and already has no context-mode reference. `roo-code` is deprecated (no boot file) and `opencode` has no boot-file template mechanism, neither is affected either way. This fix is cross-tool, not Claude-scoped.
- `planifest-overrides/instructions/custom-001-local-git-only.md`: update to state pull, push, and PR creation are authorized for the agent; commits directly to `main` and merging PRs remain human-only.
- Fold in the already-uncommitted `planifest-overrides/setup-config/claude-code.md` change from this session's manual `setup.sh` reruns (context-mode flag already removed from the recorded flag set).
- Regenerate `CLAUDE.md` in this repo (and the other Planifest-enabled repos touched earlier this session) once the fix lands, so they stop referencing context-mode.

### Out of Scope
- Removing the `--context-mode-mcp` flag or its hook-install code path (`install_context_mode_hooks`, `block-grep.mjs`/`block-bash.mjs`/`block-webfetch.mjs`) from `setup.sh` itself. The flag stays available for anyone who re-enables context-mode deliberately; only the unconditional template line and the boot-file staleness bug are fixed.
- Any change to the context-mode marketplace registration in `~/.claude/settings.json` (already handled ad hoc earlier this session, outside the pipeline).
- Any change to `structured-telemetry-mcp` wiring (unaffected, confirmed independent this session).

### Deferred
- Nothing deferred.

## Non-Functional Requirements

Not applicable at a measurable-target level; this is an internal tooling fix. Correctness criterion: regenerating `CLAUDE.md` in a repo with the fix applied must produce a file with zero occurrences of "context-mode" and must preserve all `planifest-overrides/instructions/` content via `append_override_instructions`.

## Constraints and Assumptions

### Constraints
- Must not touch the `--context-mode-mcp` flag's existence (out of scope, see above).
- `setup.ps1` must stay in parity with `setup.sh` per existing framework convention (both scripts implement the same behavior).

### Assumptions
- `CLAUDE.md`/`AGENTS.md` are fully generated/disposable, all durable local customization already lives in `planifest-overrides/instructions/` and is re-applied by `append_override_instructions` on every regeneration. Confirmed by the human this session ("Claude files are disposable").

## Scenario Paths

**Happy path:** A human runs `setup.sh <tool>` (any of claude-code, cline, codex, antigravity, copilot, windsurf; `.ps1` equivalent on Windows) in a repo that already has a boot file (`CLAUDE.md` or `AGENTS.md` depending on tool). The boot file is regenerated from the current template (no more skip-if-exists), override instructions are re-appended, and the result contains no context-mode reference, uniformly across all six tools.

**First-run path:** A human runs `setup.sh <tool>` in a repo with no boot file yet. Behavior is unchanged from today, a fresh file is created from the template plus overrides, for any of the six applicable tools.

**Error / sad path:** `append_override_instructions` fails to find `planifest-overrides/instructions/` (directory missing). Boot file regeneration should still succeed, producing the base template content with no override section, matching existing behavior for a repo with no overrides directory.

**Cross-session continuity:** Not applicable, `setup.sh` is a one-shot, idempotent script invocation with no multi-step session state to interrupt.

## Acceptance Criteria

- [ ] Running `setup.sh <tool>` (or `setup.ps1`) a second time in a repo with an existing `CLAUDE.md` overwrites it with freshly rendered template content instead of skipping.
- [ ] `templates/standard-boot.md` no longer contains any "context-mode" or "ctx_batch_execute"/"ctx_execute_file"/"ctx_fetch_and_index" reference.
- [ ] `custom-001-local-git-only.md` states the agent may pull, push, and create PRs; commits to `main` and PR merges remain explicitly human-only.
- [ ] `planifest-overrides/setup-config/claude-code.md`'s pending diff (context-mode flag removal) is committed as part of this feature.
- [ ] `setup.ps1` carries the equivalent `write_boot_file`/`Write-BootFile` fix in parity with `setup.sh`.
