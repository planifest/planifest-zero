---
title: "ADR 001: Claude Code is the only supported tool target"
summary: "The framework drops eight tool targets, the vendored external skill library, and the context-mode integration. setup.sh and setup.ps1 accept claude-code alone, and the flag surface shrinks from five flags to three."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Claude Code is the only supported tool target

**Skill:** planifest-change-agent
**Feature:** 0000030-framework-cut-down
**Component:** planifest-framework
**Date:** 2026-08-22

## Context

The framework supported nine tool targets: Claude Code, Cursor, Windsurf, Cline, Codex, Copilot, OpenCode, Antigravity, and Roo-Code. Each carried a `.sh` and `.ps1` setup script. Six carried a hook adapter under `hooks/adapters/`. Three routed through a separate Tier 1 install path with its own registration functions.

That breadth cost more than it returned. `setup.sh` ran to 1557 lines, of which roughly a third existed to branch by tool tier. Only Claude Code was in real use.

Two other subsystems had already started to rot. `external-skills/` vendored over 400 third-party skills, installed only behind `--include-full-skill-library`. The context-mode integration shipped three PreToolUse hooks behind `--context-mode-mcp`, and commit 6a50af1 had already dropped context-mode from the boot templates, leaving the flag installing hooks nothing else referenced.

## Decision

Support Claude Code alone.

`VALID_TOOLS` becomes `claude-code`. The eight other setup scripts, the six hook adapters, and the four non-Claude ignore files are deleted. `tool-setup-reference.md` and `templates/cursor-boot.md` go with them.

The flag surface drops from five to three:

| Flag | Status |
|------|--------|
| `--structured-telemetry-mcp` | Kept |
| `--backend-url` | Kept |
| `--strict-orchestrator` | Kept |
| `--context-mode-mcp` | Removed, along with `hooks/context-mode/` and every reference |
| `--include-full-skill-library` | Removed, along with `external-skills/` and the skill-sync scripts |

The `all` pseudo-target and the `add-skill` family of subcommands go, since neither has anything left to iterate over or delegate to.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep every tool target | No migration cost for a hypothetical user of another tool | Leaves 1557 lines of setup logic and six adapters that nobody exercises | No user of another target exists. The maintenance cost is real and the benefit is not. |
| Keep the flags as no-ops | Existing invocations keep exiting 0 | A flag that silently installs nothing is exactly the defect context-mode became | Preferred a loud `Unknown flag` error to a silent no-op |
| Delete tool targets, keep external-skills | Skill library stays available for a future opt-in | 400+ vendored directories for a flag nobody passes | Recoverable from git history if it is ever wanted again |
| Keep context-mode, delete only the src component | Smaller diff | Leaves a flag whose source component no longer exists | Half a removal is worse than none |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-framework` | `setup.sh` drops from 1557 to 1104 lines and loses seven functions. `setup.ps1` drops from 1528 to 1092 and loses ten. Both tool configs lose their `HooksSrc` and `HooksDir` entries. |
| `context-mode-hooks` | Deleted. It was the source of the three hooks the removed flag installed. |
| `setup-hook-integration` | Deleted. It documented `setup.sh` and `setup.ps1`, which live in `planifest-framework/`. |

## Consequences

**Positive:**
- One install path. No tier branching, no adapter indirection, no per-tool special cases.
- The flag surface matches what the framework actually does.
- 453 lines out of `setup.sh` and 436 out of `setup.ps1`.
- The test suite no longer asserts against a Copilot adapter or an OpenCode plugin that nobody runs.

**Negative:**
- Anyone running Planifest under Cursor, Windsurf, or Cline loses their install path. Their existing `.cursor/` or `.windsurf/` trees keep working until they re-run setup, at which point setup rejects the tool name.
- The vendored skill library is gone from the working tree. Recovering it means a git checkout of a pre-0.1.0 commit.

**Risks:**
- A context-mode reference could survive somewhere the sweep missed. The full test suite passes, but grep coverage is not proof.
- `refresh-planifest-framework-dir.ps1` still hardcodes `C:\d\planifest\framework\`. It was left as-is by explicit decision and breaks on any other path.

## Related ADRs

- 0000001 ADR-001 to ADR-004 (context-mode hook design) - superseded by this decision. Their subject no longer exists.
- 0000018 ADR-001 (unified telemetry signal) - related-to. This ADR removes the flag that decision decoupled telemetry from.

## Supersedes

- 0000001-ADR-001, 0000001-ADR-002, 0000001-ADR-003, 0000001-ADR-004

## Superseded By

- None
