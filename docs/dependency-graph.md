# Dependency Graph

## Component dependency diagram

```mermaid
graph TD
    subgraph "planifest-zero (component-pack)"
        SKILLS["skills/ (orchestrator + phase skills)"]
        STANDARDS["standards/, templates/, schemas/"]
        SETUP["setup.sh / setup.ps1"]
        GITHOOKS["git hooks\n(commit-msg, pre-commit, pre-push)"]
        ENFORCE["hooks/enforcement/\n(gate-write, check-design, ratchet-check,\nem-dash-guard, auto-trigger-orchestrator,\ncheck-orchestrator-presence,\ncheck-telemetry-failures,\ncheck-telemetry-receipts)"]
        ENFSHARED["hooks/enforcement/ shared modules\n(read-stdin.mjs, phase-enum.mjs)\nalways installed"]
        TELEM["hooks/telemetry/\n(context-pressure, emit-phase-start,\nemit-phase-end, emit-event-receipt,\nresolve-phase)"]
        TELSHARED["hooks/telemetry/ shared modules\n(emit-event, record-telemetry-failure,\nread-product-id, get-flag-path)\ninstalled only with --structured-telemetry-mcp"]
    end

    subgraph "Claude Code runtime"
        CC[Claude Code agent]
        HookRunner["Hook runner (Claude Code internal)"]
    end

    subgraph "External"
        BACKEND["Structured telemetry backend\n(PLANIFEST_TELEMETRY_URL)"]
        NODE["node (required, sole runtime)"]
    end

    SETUP -->|"installs"| SKILLS
    SETUP -->|"copies + wires"| ENFORCE
    SETUP -->|"wires via core.hooksPath"| GITHOOKS
    SETUP -->|"copies + wires under a flag"| TELEM
    SKILLS -->|"bundles at install time"| STANDARDS

    CC -->|"plans a tool call"| HookRunner
    HookRunner -->|"stdin JSON"| ENFORCE
    HookRunner -->|"stdin JSON"| TELEM
    ENFORCE -->|"stdout block or additionalContext"| HookRunner
    TELEM -->|"POST /emit"| BACKEND

    ENFORCE --> ENFSHARED
    TELEM --> TELSHARED
    TELSHARED -.->|"cross-directory import"| ENFSHARED

    ENFORCE --> NODE
    TELEM --> NODE
```

---

## Edges that matter

**`hooks/telemetry/` imports from `hooks/enforcement/`, never the reverse.** The enforcement tree installs unconditionally. The telemetry tree installs only under `--structured-telemetry-mcp`. Any helper with an enforcement caller must therefore live in the always-present tree.

**`phase-enum.mjs` is the canonical phase enum.** It holds the five phase values (discovery, plan, implement, validate-and-accept, ship) and lives in the always-installed enforcement tree. `standards/telemetry-standards.md` mirrors the same enum.

**`resolve-phase.mjs` interposes on the Skill tool.** A `PreToolUse(Skill)` hook reads `tool_input.skill`, resolves the active pipeline phase, then re-execs `emit-phase-start.mjs`. A `Stop` hook re-execs `emit-phase-end.mjs` from a session marker file, cleared after use.

**Node is the sole runtime.** Every hook is a `.mjs` file invoked as `node <script>`. There is no `jq` dependency and no bash entry point, so the hooks run identically on macOS, Linux, and Windows.
