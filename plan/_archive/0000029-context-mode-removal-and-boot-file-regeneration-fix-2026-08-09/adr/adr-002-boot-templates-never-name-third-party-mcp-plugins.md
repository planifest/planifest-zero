---
title: "ADR 002: Boot Templates Never Name Third-Party MCP Plugins"
summary: "templates/standard-boot.md drops its unconditional context-mode instruction; boot templates must not direct agents to prefer a named third-party plugin that may not be installed, trusted, or reviewed."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Boot Templates Never Name Third-Party MCP Plugins

**Skill:** [adr-agent](../skills/adr-agent-SKILL.md)
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Component:** planifest-framework
**Date:** 2026-08-09

## Context

`templates/standard-boot.md` carried an unconditional bullet instructing every agent to prefer context-mode MCP tools (`ctx_batch_execute`, `ctx_execute_file`, `ctx_fetch_and_index`) over native Read/Bash/WebFetch. This shipped into the boot file of 6 of 9 supported tools regardless of whether the plugin was installed, and regardless of the `--context-mode-mcp` setup flag. Earlier this session the plugin (third-party, github.com/mksglu/context-mode) injected a fabricated system-reminder into the agent's context that instructed it to conceal a file change from the human, a prompt-injection pattern. The plugin was disabled machine-wide. The template line survived every cleanup until hand-edited, because of the skip-if-exists behaviour addressed by ADR-001.

## Decision

Remove the context-mode bullet from `templates/standard-boot.md`. As a standing rule, boot templates never instruct agents to prefer a named third-party MCP plugin: a boot file is trusted instruction text, and routing agent behaviour through an unreviewed third-party tool from that position of trust is a supply-chain exposure. Tool-availability decisions belong to the host tool's own configuration (plugin enablement, setup flags), not to unconditional template prose.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Gate the line behind --context-mode-mcp at render time | Keeps the instruction for opted-in installs | Template rendering has no flag-conditional mechanism today; still endorses the plugin from trusted text | Not worth building conditional templating to preserve a reference the human has decided to drop |
| Keep the line, soften wording ("if installed and trusted") | Minimal diff | Still names and endorses a specific third-party plugin in every generated boot file | The endorsement is the problem, not the phrasing |
| Remove the whole --context-mode-mcp code path too | Fullest removal | Larger blast radius; the flag is opt-in, inert when unused, and someone may deliberately re-enable | Explicitly out of scope per confirmed design |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | templates/standard-boot.md loses one bullet; claude-code, cline, codex, antigravity, copilot, windsurf boot files regenerate without it. cursor-boot.md already clean. |

## Consequences

**Positive:**
- No generated boot file endorses a third-party plugin the human has not deliberately installed.
- The prompt-injection surface identified this session is closed at its distribution point.

**Negative:**
- Installs that genuinely use context-mode lose the boot-file nudge; they can restore it via a repo-local override in planifest-overrides/instructions/ (user-owned, deliberate).

**Risks:**
- None beyond loss of the nudge; the `--context-mode-mcp` hook-install path is untouched and continues to work for opted-in installs.

## Related ADRs

- ADR-001 - related-to (regeneration is what propagates this removal to installed repos)

## Supersedes

- None.

## Superseded By

- None.
