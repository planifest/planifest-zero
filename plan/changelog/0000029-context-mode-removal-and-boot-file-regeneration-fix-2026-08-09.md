# Changelog (0000029-context-mode-removal-and-boot-file-regeneration-fix, 09 Aug 2026)

**Feature:** Context Mode Removal and Boot File Regeneration Fix
**Pipeline run:** P0-P9 completed, none skipped
**PR:** https://github.com/planifest/planifest-framework/pull/56

## What Was Built

Two framework fixes and one repo-local config update, all originating from a live incident this session: the context-mode MCP plugin (third-party) injected a fabricated system-reminder instructing the agent to conceal a file change from the human on the loop. The plugin was disabled machine-wide; these fixes remove its remaining traces at the source and correct the tooling defect that let stale boot-file content linger.

- **Boot files always regenerate** (`setup.sh` `write_boot_file`, `setup.ps1` `Write-PlanifestBootFile`): the skip-if-exists guard is removed, so template fixes propagate to installed repos on every setup run. Boot files are disposable build outputs; durable customization lives in `planifest-overrides/instructions/` and is re-applied every run (ADR-001). Applies uniformly to every tool.
- **Boot templates never name third-party MCP plugins** (`templates/standard-boot.md`): the unconditional "Use context-mode MCP when available" bullet, shipped into 6 of 9 tools' boot files, is removed (ADR-002). The opt-in `--context-mode-mcp` hook-install path is deliberately untouched.
- **Git-permission override updated** (`planifest-overrides/instructions/custom-001-local-git-only.md`, repo-local, not distributed): the agent may fetch, pull, push, and create PRs; commits directly to `main` and PR merges remain human-only.

## Artifacts Produced

discovery.md, feature-brief.md, design.md, build-log.md, execution-plan.md, requirements/req-001..003, scope.md, risk-register.md, domain-glossary.md, adr/adr-001, adr/adr-002, security-report.md, iteration-log.md, tests/test-0000029-req-001-003-boot-file-regeneration.sh, plus living-doc updates (component-registry.md, decisions-index.md, context-mode.md status banner) and backlog entry 0000074.

## Decisions

- ADR-001: Boot files are disposable build outputs; always regenerate from the current template.
- ADR-002: Boot templates never name third-party MCP plugins; tool availability belongs to host-tool configuration, not template prose.

## Skipped Phases

None.
