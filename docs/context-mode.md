# context-mode MCP: How It Works

> **Status (0000029, 09 Aug 2026): no longer referenced by Planifest boot templates.**
> `templates/standard-boot.md` previously instructed every agent to prefer context-mode
> tools unconditionally. That line was removed under 0000029 ADR-002 after a session in
> which the plugin injected a fabricated system-reminder instructing the agent to conceal
> a file change from the human on the loop, a prompt-injection pattern. Boot templates no
> longer name any third-party MCP plugin. The opt-in `--context-mode-mcp` setup flag and
> its enforcement hooks remain available, unchanged, for installs that deliberately enable
> the plugin. This document describes how the plugin works when so enabled; it is not an
> endorsement.

[context-mode](https://github.com/mksglu/context-mode) is an MCP plugin that protects your agent's context window from flooding. Instead of piping large outputs directly into context, the agent routes them through a sandboxed knowledge base and retrieves only what it needs.

---

## The Problem

An agent working on a large codebase can exhaust its context window quickly:

- `Grep` returns hundreds of matching lines across dozens of files
- `Bash` with `find` or `cat` dumps entire file trees or file contents
- `WebFetch` pulls full HTML pages into context

Once the context window is full, the agent loses track of earlier work, produces lower-quality output, and may start hallucinating.

---

## How context-mode Solves It

context-mode provides MCP tools that run operations in a sandbox and index the output into a local full-text search store. The agent queries the store instead of reading raw output:

| Native tool | context-mode equivalent | What happens |
|-------------|------------------------|-------------|
| `Grep` | `ctx_execute(language:"shell", code:"grep ...")` | Output indexed; agent searches the index |
| `Bash` (search/fetch) | `ctx_execute` or `ctx_fetch_and_index` | Same: output stays in sandbox |
| `WebFetch` | `ctx_fetch_and_index(url:"...")` + `ctx_search(queries:["..."])` | Page fetched, chunked, indexed; agent queries |

Only the agent's search results, typically a few hundred words, enter the context window.

---

## What `--context-mode-mcp` Installs

Running setup with `--context-mode-mcp` installs enforcement hooks for Claude Code. Routing rules are provided automatically by the context-mode plugin's system prompt when the plugin is installed; no separate file is needed.

### Enforcement hooks (Claude Code only)

For Claude Code, three `PreToolUse` hook scripts are installed to `.claude/hooks/context-mode/` and registered in `.claude/settings.json`. These fire synchronously before each tool call and block native tool use at the platform level; the agent cannot bypass them even accidentally.

| Hook | Intercepts | Redirects to |
|------|-----------|-------------|
| `block-grep.sh` | `Grep`: any use | `ctx_execute(language:"shell", code:"grep ...")` |
| `block-bash.sh` | `Bash`: commands containing `grep`, `rg`, `curl`, `wget` | `ctx_execute` or `ctx_fetch_and_index` |
| `block-webfetch.sh` | `WebFetch`: any use | `ctx_fetch_and_index` + `ctx_search` |

**Bash allowlist**: these commands are always permitted through without inspection:
`git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`

When a hook blocks a call, it returns the exact `ctx_*` invocation the agent should use instead. The agent retries immediately with the correct tool.

---

## Hook mechanics

The hooks read the tool call JSON from stdin, check whether the call should be blocked, and write a decision to stdout:

```
Claude Code
  │  (plans Grep call)
  ▼
PreToolUse hook runner
  │  (pipes tool call JSON to hook script on stdin)
  ▼
block-grep.sh
  │  (writes deny decision + redirect message to stdout)
  ▼
PreToolUse hook runner
  │  (surfaces redirect message to agent)
  ▼
Agent retries with ctx_execute(...)
  │
  ▼
context-mode sandbox (output indexed, not in context)
```

Exit 0 with empty stdout = allow. Exit 0 with JSON = deny with redirect. The hooks never exit non-zero.

---

## Prerequisites

### context-mode MCP server

Install and configure the context-mode MCP server before running setup with `--context-mode-mcp`:

```
https://github.com/mksglu/context-mode
```

### jq (recommended)

The enforcement hooks use `jq` for JSON parsing. Without it they fall back to Node.js, which adds ~250ms cold-start latency per hook call on Windows. On macOS/Linux with `jq`, hooks complete in under 50ms.

```bash
brew install jq          # macOS
scoop install jq         # Windows (scoop)
choco install jq         # Windows (choco)
sudo apt install jq      # Ubuntu / Debian
```

---

## Supported tools

| Tool | Routing rules (plugin) | Enforcement hooks |
|------|:---:|:---:|
| Claude Code | ✅ | ✅ |
| Cursor | ✅ | N/A |
| Windsurf | ✅ | N/A |
| Copilot | ✅ | N/A |
| Cline | ✅ | N/A |

Routing rules are injected by the context-mode plugin's system prompt, available to any tool that supports the plugin. Enforcement hooks are a Claude Code-specific feature (PreToolUse hooks).
