---
title: "Domain Glossary - relocate-setup-config-to-plan-state"
summary: "Definitions of domain terms used within this feature."
status: "draft"
version: "0.3.0"
---
# Domain Glossary - relocate-setup-config-to-plan-state

**Skill:** [spec-agent](../../planifest-framework/skills/spec-agent-SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Version:** 0.3.0

> The ubiquitous language for this feature. If the glossary says "Order", the code says `Order` - not "Purchase" or "Transaction". Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| setup-config record | The tracked, git-versioned record of a tool's active setup flags, backend URL, and write timestamp, written on every setup run and read back by `planifest-refresh-setup`. This feature moves its file location from `planifest-overrides/setup-config/{tool}.md` to `plan/state/{tool}.md`. | tracked record | `planifest-zero/setup.sh` (`write_setup_config_override`), `planifest-zero/setup.ps1` (`Write-SetupConfigOverride`), `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| tracked record | Same concept as setup-config record, the name used in `planifest-refresh-setup`'s Step 3 read order. | setup-config record | `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| marker file (`.planifest-setup-flags`) | The gitignored, per-install JSON cache of the flags, backend URL, write timestamp, and attempt status used at install time. Unaffected by this feature: its role, format, and location are unchanged. | flags-used marker | `planifest-zero/setup.sh` (`write_setup_flags_marker`), `planifest-zero/setup.ps1`, `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| tool directory (`{tool-dir}`) | The per-tool install directory (for example `.claude/`) whose presence signals an existing install and that holds the marker file. | - | `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| hook inference | `planifest-refresh-setup`'s fallback method for reconstructing active flags from installed hook wiring (for example detecting `PLANIFEST_TELEMETRY_URL` in a settings file) when neither the setup-config record nor the marker file is usable. | - | `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| source and confidence | The pairing `planifest-refresh-setup` reports for each reconstructed flag: where the value came from (setup-config record, marker file, or hook inference) and how certain that origin makes the value (high or, for hook inference, still high per the signal table). | - | `planifest-zero/skills/planifest-refresh-setup/SKILL.md` |
| inline cleanup | The behaviour where `setup.sh`/`setup.ps1` delete the old `planifest-overrides/setup-config/{tool}.md` file (and its emptied folder) as part of a normal run, rather than through a separate migration file. | - | `planifest-zero/setup.sh`, `planifest-zero/setup.ps1` |
| `plan/state/` | The new folder holding durable, machine-written pipeline state, distinct from `plan/current/` (in-progress pipeline artifacts) and `planifest-overrides/` (human-owned configuration). This feature is the first to write to it. | - | `plan/README.md`, `plan/feature-structure.md`, `planifest-zero/pipeline-reference.md`, `planifest-zero/project-operations.md` |
