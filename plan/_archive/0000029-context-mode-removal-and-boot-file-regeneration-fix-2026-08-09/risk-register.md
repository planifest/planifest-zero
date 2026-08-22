---
title: "Risk Register - Context Mode Removal and Boot File Regeneration Fix"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - Context Mode Removal and Boot File Regeneration Fix

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Version:** 0.28.1
**Overall Risk Level:** low

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | Making `write_boot_file` always-overwrite changes the on-disk content of a gitignored file on every `setup.sh` run; a repo that had manually edited `CLAUDE.md` directly (not via `planifest-overrides/instructions/`) loses that edit silently on next run | low | low | `CLAUDE.md`/`AGENTS.md` are gitignored and documented as disposable; `append_override_instructions` re-applies all tracked override content every run, so any durable customization already survives | open |
| R-002 | technical | `setup.ps1` parity fix is written without a live Windows/PowerShell test run available in this environment (same constraint noted for prior `.ps1` changes in this repo's history, e.g. 0000020's Q-006) | medium | low | Checked statically against the `setup.sh` logic it mirrors; flagged here for a human `pwsh` verification pass, matching existing repo practice | open |
| R-003 | operational | This session already ran `setup.sh` manually (outside the pipeline) across 7 repos before this fix existed; those repos still carry the stale context-mode boot-file line until each is re-run after this feature ships | high | low | Explicitly listed in Scope > In Scope as a required follow-up action once P3 lands; not silently left inconsistent | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | All durable local customization already lives in `planifest-overrides/instructions/`, never hand-typed directly into `CLAUDE.md` | Always-regenerate would silently drop any customization not actually captured as an override | open |
