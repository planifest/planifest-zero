---
title: "Requirement: REQ-002 - Drop Context-Mode From Boot Template"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: REQ-002 - Drop Context-Mode From Boot Template

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Source:** US-002
**Priority:** must-have

## User Story

As a human who has disabled context-mode, I want the generated boot file to stop instructing the agent to use it, so that no repo (this one or any downstream consumer) is told to route work through a plugin that may not be installed or trusted.

## Functional Requirements
- `templates/standard-boot.md` no longer contains the "Use context-mode MCP when available" bullet or any reference to `ctx_batch_execute`, `ctx_execute_file`, `ctx_fetch_and_index`, or `ctx_search`.
- The removal does not alter any other line in `templates/standard-boot.md`.
- `templates/cursor-boot.md` is left untouched, already confirmed to have no context-mode reference.
- The `--context-mode-mcp` flag and its hook-install code path (`install_context_mode_hooks`, `block-grep.mjs`, `block-bash.mjs`, `block-webfetch.mjs`) in `setup.sh`/`setup.ps1` are explicitly out of scope for this requirement and are not touched.

## Acceptance Criteria
- [ ] `templates/standard-boot.md` contains zero occurrences of the strings "context-mode" and "ctx_batch_execute".
- [ ] Regenerating a boot file for claude-code, cline, codex, antigravity, copilot, or windsurf produces no context-mode reference.
- [ ] `setup.sh claude-code --context-mode-mcp` still installs the enforcement hooks (block-grep/block-bash/block-webfetch) exactly as before, unaffected by this requirement.

## Dependencies
- REQ-001 (boot file must actually regenerate for this line removal to reach any repo with a pre-existing boot file).
