---
title: "ADR 001: Boot Files Are Disposable Build Outputs"
summary: "write_boot_file/Write-BootFile always overwrite CLAUDE.md/AGENTS.md from the current template; all durable local customization lives in planifest-overrides/instructions/ and is re-applied on every run."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Boot Files Are Disposable Build Outputs

**Skill:** [adr-agent](../skills/adr-agent-SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Component:** planifest-framework
**Date:** 2026-08-09

## Context

`write_boot_file` (setup.sh) and its setup.ps1 counterpart skip writing when the boot file already exists. The guard was meant to protect manual edits. In practice it means a template fix never reaches an installed repo: this session's context-mode removal required hand-deleting `CLAUDE.md` in every repo (or using `refresh-delete-boot-files.sh`) before rerunning setup. The framework already has a first-class mechanism for durable local customization, `planifest-overrides/instructions/`, re-applied by `append_override_instructions` on every run, so the guard protects a workflow (hand-editing the boot file) that the framework explicitly does not support.

## Decision

Boot files are disposable build outputs, not user-owned documents. `write_boot_file`/`Write-BootFile` overwrite the boot file unconditionally on every setup run. Durable customization belongs exclusively in `planifest-overrides/instructions/`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep skip-if-exists, require refresh-delete-boot-files.sh before rerun | No behaviour change | Template fixes silently never propagate; extra manual step every refresh | The failure mode is silent staleness, the worst kind |
| Prompt the human before overwriting | Explicit consent | Breaks non-interactive/scripted setup runs; consent adds nothing when the file is generated | Boot file has no human-authored content by design |
| Content-hash check, overwrite only when template changed | Fewer writes | Complexity for zero observable benefit; overwrite is idempotent anyway | Same end state as unconditional overwrite |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | setup.sh `write_boot_file` and setup.ps1 equivalent lose the existence guard; every tool's boot file regenerates on every run |

## Consequences

**Positive:**
- Template fixes and override changes propagate on every setup run with no manual deletion step.
- `refresh-delete-boot-files.sh`/`.ps1` are no longer needed for refreshes (retained for explicit cleanup use).

**Negative:**
- Any hand-typed edit made directly to a boot file is lost on the next setup run.

**Risks:**
- A repo that violated the overrides convention loses hand-edits silently (risk-register R-001, likelihood low, impact low: the file is gitignored and documented as disposable).

## Related ADRs

- ADR-002 - related-to (the template fix that regeneration propagates)

## Supersedes

- None.

## Superseded By

- None.
