---
title: "Domain Glossary - Context Mode Removal and Boot File Regeneration Fix"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - Context Mode Removal and Boot File Regeneration Fix

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Version:** 0.28.1

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Boot file | The tool-specific instruction file `setup.sh`/`setup.ps1` generates per project (`CLAUDE.md` for Claude Code, `AGENTS.md` for most other supported tools) | none | planifest-framework |
| Boot template | The shared markdown source (`templates/standard-boot.md` or `templates/cursor-boot.md`) rendered into a boot file at setup time | none | planifest-framework |
| Override instructions | Repo-local, human-authored markdown files under `planifest-overrides/instructions/`, re-appended into the boot file on every regeneration | overrides | planifest-framework |
| Context-mode | A third-party MCP plugin (not Anthropic-official) that this session disabled machine-wide after it injected a fake system-reminder instructing the agent to conceal a change from the human | none | planifest-framework |
