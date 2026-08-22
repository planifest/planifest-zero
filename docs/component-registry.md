# Component Registry

**Last updated:** 0000029-context-mode-removal-and-boot-file-regeneration-fix (09 Aug 2026)
**Maintained by:** planifest-docs-agent

---

## Registry

| ID | Name | Type | Domain | Status | Summary | Docs |
|----|------|------|--------|--------|---------|------|
| `context-mode-hooks` | context-mode Enforcement Hook Scripts | component-pack | developer-tooling | active | Blocking PreToolUse hook scripts (`.mjs`, Node-only since v0.2.0: no `jq`, no Unix-shell requirement) that enforce context-mode routing rules by intercepting Grep, Bash (pattern-matched), and WebFetch tool calls. | [purpose](../src/context-mode-hooks/docs/purpose.md) |
| `setup-hook-integration` | Setup Hook Integration | component-pack | developer-tooling | active | setup.sh/ps1, skill-sync, and hook adapters (copilot, cursor, windsurf, codex): installs and configures enforcement hooks, telemetry hooks, context-mode hooks, commit standards, and external skill management into any Planifest-managed project. Now also writes a `.planifest-setup-flags` marker recording the flags used at install time (v0.4.0, 0000020). v0.5.0 (0000027): registers `emit-phase-start.mjs`/`emit-phase-end.mjs` (via a new `resolve-phase.mjs` interposer) and `emit-event-receipt.mjs` alongside `context-pressure.mjs`; fixed `cline.sh`/`cline.ps1`'s boot-file/skills-dir path collision; `--backend-url` is now validated against a plain http(s)-URL shape before it can reach shell-command interpolation. | [purpose](../src/setup-hook-integration/docs/purpose.md) |
| `planifest-framework` | Planifest Framework | component-pack | developer-tooling | active | Core standards, skills, hooks, and setup scripts enforcing the confirmed-design pipeline (v0.25.0: ship-agent PR output omits the AI-attribution footer by default and its P7 archive commit stages `plan/current/` explicitly; setup scripts additionally track active flags/backend-url in a versioned `planifest-overrides/setup-config/{tool}.md`; docs-agent routes `recommendations.md` deferred items/tech debt into `plan/backlog/` going forward and its Gate B (plus other phase-skill gates, audited) respects `continuous_run`; the Scope Lock Challenge defaults to always-drafted, batch-presented answers, superseding 0000017-ADR-003; subagent parallelism directives expanded for validate-agent, docs-agent, and agent-dispatch-standards.md). v0.27.0 (0000027): deterministic telemetry-compliance backstop (`check-telemetry-receipts.mjs`, `emit-event-receipt.mjs`); explicit P0 step + `framework-update-policy.md` for framework-dependency updates; subagent out-of-scope discoveries now instructed to file to `plan/backlog/` directly; skill-scope-principle ADR (ADR-003) referenced from the orchestrator's Capability Skills guidance; minimal default Phase 1 artifact set (ADR-004) landed in `feature-pipeline.md`/`planifest-spec-agent`/README; 7 pre-0000025 backlog items backfilled. v0.28.0 (0000028): telemetry emission retries network-level failures only (2 retries, 300ms gaps) and never an HTTP error status, in a shared `hooks/telemetry/emit-event.mjs` all three fetch-calling hooks import; six duplicated helpers extracted into shared modules across `hooks/enforcement/` (`read-stdin.mjs`, `phase-enum.mjs`) and `hooks/telemetry/` (`emit-event.mjs`, `record-telemetry-failure.mjs`, `read-product-id.mjs`, `get-flag-path.mjs`), collapsing 13 `readStdin()` copies to one and fixing a latent NFR-001 violation in 10 of them; `getSessionId()` deliberately not consolidated (3 behaviour profiles); tier 1 telemetry install glob widened to `*.mjs`; stderr fallback when the durable failure marker write itself fails; `plan/.telemetry-receipts/` gitignored; new `em-dash-guard.mjs` PreToolUse hook plus a bounded cleanup of 99 live artifacts; and a P5 fix wiring every enforcement hook through `node` rather than a bare `.mjs` path, which had been silently failing open at exit 126. v0.28.1 (0000029): boot files (CLAUDE.md/AGENTS.md) are disposable build outputs, write_boot_file/Write-PlanifestBootFile regenerate them from the current template on every run (previously skip-if-exists, so template fixes never propagated); templates/standard-boot.md no longer names any third-party MCP plugin, removing the unconditional context-mode instruction that shipped into 6 of 9 tools' boot files. | [component.yml](../planifest-framework/component.yml) |

---

## Status Key

| Status | Meaning |
|--------|---------|
| `active` | In production / installed in target environments |
| `in-progress` | Pipeline in flight |
| `deprecated` | Superseded; pending removal |
| `planned` | On roadmap; not yet in a pipeline |

---

## Notes

- This registry is updated by the docs-agent at the end of each feature pipeline.
- Each `ID` corresponds to a directory under `src/` containing a `component.yml` manifest.
- Add new components here when a new feature pipeline completes Phase 6.
