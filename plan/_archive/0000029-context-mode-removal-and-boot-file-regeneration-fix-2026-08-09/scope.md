---
title: "Scope - Context Mode Removal and Boot File Regeneration Fix"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - Context Mode Removal and Boot File Regeneration Fix

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Version:** 0.28.1

## In Scope

- `setup.sh` and `setup.ps1`: `write_boot_file`/`Write-BootFile` always overwrites the boot file, dropping the skip-if-exists guard. Applies uniformly to every tool that calls this shared function.
- `templates/standard-boot.md`: remove the unconditional "Use context-mode MCP when available" bullet and its `ctx_*` tool references. Confirmed shared by 6 of 9 tools (claude-code, cline, codex, antigravity, copilot, windsurf).
- `planifest-overrides/instructions/custom-001-local-git-only.md`: reword to authorize agent pull, push, and PR creation; commits to `main` and PR merges remain human-only. Repo-local configuration, not a `planifest-framework` distributed-source change.
- Fold in the already-uncommitted `planifest-overrides/setup-config/claude-code.md` diff (context-mode flag already removed from the recorded flag set by an earlier ad-hoc `setup.sh` rerun this session).
- Regenerate `CLAUDE.md` in this repo, and in the other Planifest-enabled repos touched earlier this session (`planifest/telemetry-mcp`, `rapid-prototypes`, `shopify-templates`, `bug-bounty-hunter`, `_latest-planifest-framework-release`, `planifest/docs`), once the fix lands.

## Out of Scope

- Removing the `--context-mode-mcp` flag or its hook-install code path (`install_context_mode_hooks`, `block-grep.mjs`, `block-bash.mjs`, `block-webfetch.mjs`) from `setup.sh`/`setup.ps1`. The flag stays available for anyone who deliberately re-enables context-mode.
- Any change to the context-mode marketplace registration in `~/.claude/settings.json` (already handled outside the pipeline earlier this session).
- Any change to `structured-telemetry-mcp` wiring, confirmed independent of context-mode this session.
- `templates/cursor-boot.md` (already confirmed clean, no context-mode reference).
- `roo-code` and `opencode` tool setup paths (neither uses `standard-boot.md`; roo-code is deprecated, opencode has no boot-file mechanism).

## Deferred

- Nothing deferred.
