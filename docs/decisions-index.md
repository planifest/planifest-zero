# Decisions Index

> Living document. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file; update it in place.

Last updated: 0000028-telemetry-hardening-and-enforcement-fixes

> **Note:** ADR titles for features 0000001–0000010 were inferred from filenames at bootstrap time. Human review recommended for accuracy.

---

## All Architecture Decision Records

### Feature 0000001: context-mode-enforcement-hooks

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | PreToolUse block mechanism | active | Hook scripts block tool calls by writing a deny response to stdout; exit code alone is insufficient |
| ADR-002 | Allowlist hardcoded vs configurable | active | Allowlist is hardcoded in the script; configuration adds complexity without proportional benefit |
| ADR-003 | Unconditional vs pattern-based blocking | active | Pattern-based blocking (Grep/Bash/WebFetch) rather than unconditional; lets non-search tool calls through |
| ADR-004 | Hook script ownership split | active | Each hook type (block-grep, block-bash, block-webfetch) is a separate script; no monolithic hook |

### Feature 0000003: hook-based-enforcement

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Three-tier enforcement model | active | Tier 1a (Claude Code native hooks), Tier 1b (other IDE hooks), Tier 2 (instructions only) |
| ADR-002 | Common envelope shape | active | All adapters translate to `{ session_id, cwd, tool_input, event }` before delegating to enforcement |
| ADR-003 | Flag-file deduplication | active | `.orchestrator-active` sentinel prevents duplicate orchestrator activation per session |
| ADR-004 | Two-check gate model | active | gate-write performs (1) sentinel check, (2) component-path allowlist (in order) |
| ADR-005 | Exit-zero failure mode | active | Hooks never exit non-zero on unexpected errors; session must never be blocked by a hook bug |
| ADR-006 | Copy-then-delete archive | active | Archive uses explicit copy then delete, not atomic move, to survive partial failures |
| ADR-007 | Px prefix convention | active | Every phase response begins with its phase prefix (P0:, P1:, ...) for instant human orientation |
| ADR-008 | Advisory commit-msg hook | active | commit-msg hook rejects AI attribution and >72-char subjects; exit 1 on violation |
| ADR-009 | Anthropic-first skill trust model | active | Skills in `.claude/skills/` are trusted; external skills require explicit `--include-full-skill-library` |
| ADR-010 | Plan-scoped skill lifecycle | active | Skills are loaded JIT per phase, not upfront; prevents context bloat |

### Feature 0000004: tdd-regression-test-quality

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | TDD inner loop as codegen subloop | active | codegen-agent orchestrates test-writer → implementer → refactor per requirement, not per feature |
| ADR-002 | Subagent model tier convention | active | Sub-agents declare `recommended_model: haiku`; codegen-agent retains full model for orchestration |
| ADR-003 | Regression promotion criteria | active | Tests promoted to regression pack only with human confirmation; `promote-to-regression.sh` is the mechanism |

### Feature 0000005: framework-governance

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Library standards directory tree | active | Per-language prefer/avoid lists under `planifest-framework/standards/library-standards/{lang}/` |
| ADR-002 | planifest-overrides sibling directory | active | Project-level overrides live in `planifest-overrides/` (sibling to `planifest-framework/`), never inside the framework |
| ADR-003 | Sentinel-file orchestrator enforcement | active | `plan/.orchestrator-active` sentinel gates all writes to `plan/current/` |
| ADR-004 | Repo instructions via design.md | active | Per-repo instructions (e.g. local-git-only) are embedded in `design.md` Engineering Layer |
| ADR-005 | Markdown migration files | active | Migrations are documented in `.md` files under `planifest-framework/migrations/`; applied migrations archived to `_done/` |
| ADR-006 | Two-registry capability skills | active | Capability skills exist in two registries: `planifest-framework/skills-inbox/` (framework) and `planifest-overrides/capability-skills/` (project) |

### Feature 0000006: build-assessment-phase

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Build log as markdown | active | `build-log.md` in `plan/current/` captures P3/P4 cycle details; P8 reads this file |
| ADR-002 | Model tier abstraction | active | Phase skills declare `recommended_model` in frontmatter; orchestrator respects this for sub-agent invocations |
| ADR-003 | Parallelism as skill instructions | active | Parallelism directives belong in SKILL.md, not in code; agent tooling handles scheduling |
| ADR-004 | P8 as separate phase | active | Build assessment (P8) is a distinct phase invoked by P7 (ship), not by P4 (validate) |

### Feature 0000007: agent-optimisation

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Explicit build target field | active | `design.md` Engineering Layer has a `Build target:` field; agents use it to select Docker vs host toolchain |
| ADR-002 | Telemetry guidance centralised | active | All telemetry envelope docs live in `telemetry-standards.md`; skill files reference it rather than duplicating |
| ADR-003 | Optimise-agent suggestion-only | active | planifest-optimise-agent produces suggestions only, never modifies code; human decides what to apply |
| ADR-004 | Setup manifest for managed directories | active | `.planifest-manifest` tracks installed paths for idempotent re-run cleanup |
| ADR-005 | Locale-tagged language quirks files | active | `quirks.md` files include locale tag (`en-GB`) so agents apply the correct language variant |

### Feature 0000008: context-mode-plugin-routing-rules

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Plugin as canonical source for routing rules | active | Context-mode plugin is the source of truth for which tools to block; framework hook scripts read from it |
| ADR-002 | No per-tool routing rules fallback | active | If the plugin is absent, hooks pass through silently rather than applying a hard-coded fallback list |

### Feature 0000009: framework-rail-tightening

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | External skills opt-in flag | active | `--include-full-skill-library` required to install external skills; default install is framework skills only |
| ADR-002 | Attribution.txt per skill | active | Each external skill must include `attribution.txt`; missing file is a hard skip, not a silent install |
| ADR-003 | Auto-trigger hook plus fallback | active | `UserPromptSubmit` hook auto-triggers orchestrator; non-hook tools rely on manual skill load as fallback |
| ADR-004 | Skill map in design.md | active | `design.md` Engineering Layer includes a Skill Map table: requirement → skill → rationale |
| ADR-005 | gate-write Windows path normalisation | active | gate-write uses `norm()` (normalise + forward-slash + lowercase) for all path comparisons; avoids POSIX/Win mismatch |
| ADR-006 | Pause-resume via pause.md | active | `pause.md` in `plan/current/` is always permitted by gate-write; enables session pause/resume at any phase |

### Feature 0000010: framework-quality-improvements

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Agent tool in allowedTools | active | `Agent` tool must be in `allowedTools` for multi-agent features; not assumed present by default |
| ADR-002 | Skill name field as canonical identifier | active | `name:` frontmatter field in SKILL.md is the canonical skill identifier; descriptions are secondary |
| ADR-003 | Input validation section conditional | active | OpenAPI spec section in spec-agent output is conditional on the feature including an API; omit for non-API features |

### Feature 0000011: setup-parity-and-consistency

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Hook deny response format | active | Copilot/Codex use `{ permissionDecision, permissionDecisionReason }` JSON deny; Claude Code uses exit 2 + stdout message |
| ADR-002 | Workspace hook config write strategy | active | Tool-specific hook configs (`.cursor/hooks.json`, `.codex/hooks.json`) are written by setup scripts using merge-not-overwrite |
| ADR-003 | Hook adapter architecture | active | All adapters are delegating (translate envelope → call enforcement script); no inline enforcement logic in adapters |

### Feature 0000012: docs-restructure-commit-directives

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Three-file documentation architecture | active | Framework docs split into `getting-started.md` (entry point), `pipeline-reference.md` (deep reference), `project-operations.md` (operational guide); no single monolithic file |
| ADR-002 | Formal P9 Ship phase | active | Ship is a discrete phase (P9) separate from Archive (P7); pipeline is exactly P0–P9; no phase beyond P9 |
| ADR-003 | Ship-agent orchestrates P7–P9 | active | ship-agent owns the complete close-out sequence: P7 Archive, P8 Build Assessment (sub-agent), P9 Ship |
| ADR-004 | P9 human push/PR decision protocol | active | P9 always presents a push/PR choice to the human; agent never pushes without awareness; local-git-only defaults to PR description output |
| ADR-005 | Run-mode sentinel file | active | `plan/.run-mode` written at P0 persists the run mode across session boundaries; any value other than `continuous` defaults to `interactive` |
| ADR-006 | Retroactive tags via Planifest migration | active | Historical release tags applied through a migration file, not a script; human-confirmed per tag; tags are local-only until human pushes |

### Feature 0000023: framework-pipeline-fixes

ADR files: [plan/_archive/0000023-framework-pipeline-fixes-2026-08-02/adr/](../plan/_archive/0000023-framework-pipeline-fixes-2026-08-02/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Restore continuous_run exception for P1-P3 gates | accepted | Restores the `continuous_run: true` exception to P1/P2/P3 STOP rules, matching P4-P6; root-caused the regression to commit `42ae808` (feature 0000021, a word-count trim pass), correcting backlog 0000031's "pre-existing, not introduced by 0000022" claim |

---

## Status Definitions

| Status | Meaning |
|--------|---------|
| active | Decision stands; implementation follows it |
| superseded | Replaced by a later ADR (reference provided in the ADR body) |
| amended | Core decision unchanged but conditions or scope updated |

---

### Feature 0000014: improve-adoption-mode-selection

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Four Adoption Mode Taxonomy | accepted | Replace three-mode model with four signal-driven modes: Greenfield, Standard Iterative, Retrofit, External Anchor |
| ADR-002 | Signal Conflict Priority Order | accepted | External Anchor > Standard Iterative > Retrofit > Greenfield: highest-priority signal wins when multiple signals present |
| ADR-003 | docs/about.md as Canonical Version Source | accepted | `docs/about.md` with YAML frontmatter is the single source of truth for the current project version |
| ADR-004 | Version Bump Rules by Pipeline Track | accepted | Fast Path/Change Pipeline → patch; Feature Pipeline → minor; breaking change → major; human always confirms |
| ADR-005 | Version Regression Hard Block | accepted | Orchestrator refuses versions lower than current recorded version; hard block, not a warning |
| ADR-006 | Resumable Migration with Progress File | accepted | Migrations track state in `migrations/_progress/{name}.json` so they can resume across sessions |
| ADR-007 | Derived Scope Lock Scenarios over Fixed Checklist | accepted | Orchestrator generates scenario questions specific to the feature from requirements, not a generic checklist |
| ADR-008 | One-Question-at-a-Time as Framework-Wide Instruction | accepted | Every phase skill states the one-question rule explicitly; recommend-then-confirm pattern throughout |
| ADR-009 | Incremental P0 Audit Trail Writes | accepted | Build log is appended after each coaching exchange, not batched at the end of P0 |
| ADR-010 | docs/ Lifecycle Ownership | accepted | Docs-agent (P6) owns living docs updates; ship-agent (P7) owns docs/about.md creation as a blocking step |

### Feature 0000015: pipeline-session-cleanup

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Interrupted P9 Detection Signal | accepted | Combined signal: `.orchestrator-active` present AND `plan/current/` empty uniquely identifies an interrupted P9 |
| ADR-002 | New Session Recommendation Not Block | accepted | Post-P9 advisory message recommends a new session but does not enforce it; human retains control |
| ADR-003 | Stale Run-Mode Warn-and-Clear at P0 | accepted | Stale `plan/.run-mode` at fresh P0 start is auto-cleared with a visible warning; no blocking |
| ADR-004 | Run-Mode Deletion Owned by P9 | accepted | P9 (ship-agent Step 6) deletes `plan/.run-mode`; P0 handles the recovery case only |

### Feature 0000016: pipeline-governance-and-loop-engineering

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Backlog Folder Instead of Editable Post-Archive Lifecycle | accepted | Deferred work lives in `plan/backlog/{id}-{slug}/`, surfaced at the next P0; P7 stays the lock line: bug-bounty-hunter PR #4's editable-P7–P9 design rejected |
| ADR-002 | product.yml with versionPolicy | amended by 0000026 ADR-001 | Root `product.yml` aggregates one release version across components (`max-component-version` \| `explicit` \| `external`); single-component projects keep component.yml behaviour. **Amended:** 0000026 ADR-001 changes `components[]` under `max-component-version` from a cached `{id, version}` to a `{id, path}` pointer, read live by `product-version.mjs` at derivation time: eliminates the P9 sync-drift risk the cached copy created |
| ADR-003 | Loop Toggles in planifest-overrides/loop-toggles.yml | accepted | Per-loop `off \| report-only \| on`; user-owned directory so agents cannot self-enable; absent = all off |
| ADR-004 | Single-Use Marker File for Approved Weakening | amended by 0000017 ADR-001 | Human-created `plan/current/.ratchet-approve` (path per line, consumed on use) is the only path past the ratchet; agents prohibited from writing it. **Amended:** 0000017 ADR-001 permits the agent to write the marker on explicit in-the-moment human instruction, extends the format to `path \| reason \| timestamp`, and keeps the same-changeset backstop with an explicit approver message. |
| ADR-005 | Cascade Threshold of 3 Artifacts | accepted | A reversal invalidating >3 downstream artifacts always stops for the human, regardless of run mode |
| ADR-006 | Verifiers as Fresh-Context REJECT-Default Subagents | accepted | Critic, assessor, and cross-model reviewer never share context with the maker; approval requires cited positive evidence |
| ADR-007 | Deterministic Caps, Budget, and Ratchet Enforcement | accepted | Iteration caps (3 default, P4 keeps 5), reversal budget (2/feature), and weakening blocks are enforced by hooks + control flow over git-tracked state, never skill prose alone |
| ADR-008 | Cross-Model Review Gate at End of P6, Pre-Archive | accepted | The second-model review runs while implementation is live and editable; the brief's original "before P9" placement was structurally self-contradictory and is corrected |

### Feature 0000017: ratchet-forgery-detection-and-telemetry-schema-spec

ADR files: [plan/_archive/0000017-ratchet-forgery-detection-and-telemetry-schema-spec-2026-07-26/adr/](../plan/_archive/0000017-ratchet-forgery-detection-and-telemetry-schema-spec-2026-07-26/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Ratchet-Approve: Agent Write on Explicit Instruction | accepted | Amends 0000016 ADR-004: agent may write `.ratchet-approve` only when the human states path, reason, and go-ahead in the same turn; format `path \| reason \| timestamp`; immediate dedicated commit; backstop kept with an explicit approver-facing message; consumption copied to `plan/ratchet-audit-log.md` |
| ADR-002 | Cross-Platform Hook Runtime Unification (.sh → .mjs) | accepted | The 3 context-mode hooks become `.mjs` (Node-only): removes `jq` and the Git Bash/WSL requirement entirely; missing Node surfaces a message at setup and runtime while failing open |
| ADR-003 | Scope Lock Suggested Answers via On-Demand Subagent | superseded by 0000025 ADR-003 | The orchestrator always offers "want me to suggest an answer?" at each Scope Lock question but only dispatches `planifest-scope-lock-agent` on explicit request; drafts are usage-only, consistency-checked, flagged, and never self-confirming. **Superseded:** 0000025-ADR-003 reverses the never-pre-draft, offer-then-opt-in default for the Scope Lock Challenge specifically, replacing it with default parallel drafting and batch presentation; per-item explicit accept/edit/reject and immediate build-log capture are unchanged |
| ADR-004 | Structured P0 Discovery Pass and discovery.md Lifecycle | accepted | Every adoption mode runs a structured discovery pass before coaching, writing to `plan/current/discovery.md`: fresh each run, archived at P7; partial failures noted inline, never a hard block |

### Feature 0000018: telemetry-emission-consistency

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Unify Telemetry Gating by Removing the --context-mode-mcp Coupling | accepted | Removes the `--context-mode-mcp` AND-condition from telemetry hook installation: `--structured-telemetry-mcp` alone becomes sufficient, closing the exact gap that caused 0000017's telemetry loss |
| ADR-002 | Telemetry Failure Detection and Interactive Recovery | accepted | Hook-driven emission stays fire-and-forget (ADR-005, 0000003, unchanged) but now writes a durable failure marker on error, checked by the orchestrator at phase-start checkpoints; agent-driven emission stops and asks immediately inline. Human is asked once per distinct root cause per run |
| ADR-003 | discovery.md Elevated to Hard Limit Status | accepted | discovery.md's existence-and-completeness requirement elevated to Hard Limit status, matching build-log.md's Hard Limit 8 pattern: a self-audit finding from this feature's own P0 |

### Feature 0000019: self-description-and-session-hygiene-fixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Repository self-description check is a separate script | accepted | `self-description-check.mjs` is a new, repository-scoped script wired into CI, deliberately not folded into `consistency-check.mjs`: different subject (repo self-description vs. `plan/current/`), different lifecycle (every PR vs. per-feature), different caller |
| ADR-002 | context_pressure telemetry events map to phase: "orchestrator" | accepted | Fixes an unconditional HTTP 400 (invalid `phase` enum value `"monitoring"`) discovered live during this feature's own P0; maps to `"orchestrator"` as the semantically closest existing value, consistent with context hygiene being framed as an orchestrator responsibility |

### Feature 0000020 - setup-refresh-skill

ADR files: [plan/_archive/0000020-setup-refresh-skill-2026-08-01/adr/](../plan/_archive/0000020-setup-refresh-skill-2026-08-01/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Hardcoded, non-extensible deletion allowlist | accepted, hardened in P5 | The refresh skill's deletion capability is restricted to exactly `CLAUDE.md`/`AGENTS.md`. Originally a SKILL.md-prose-only rule; a P5 security finding (no deterministic backstop, unlike gate-write.mjs for writes) led to extracting the allowlist into `refresh-delete-boot-files.sh`/`.ps1`, hardcoded in code |
| ADR-002 | Single marker file, dual purpose | accepted | `.planifest-setup-flags` serves as both the install-time flag record (written by setup.sh/setup.ps1) and the refresh skill's retry/recovery cache, not two separate files, avoiding a synchronisation problem between overlapping state |
| ADR-003 | Mandatory human confirmation gate | accepted | The refresh skill always halts for explicit confirmation before any destructive action, in every run, including all-high-confidence runs; no bypass exists |
| ADR-004 | Explicit tool selection, not auto-resolved | accepted | The target tool is always named by the human on the loop or asked for up front; multiple installed tools is normal input, not an ambiguity to guess through. Corrected mid-P0 after an early draft conflated this with a failure condition |
| ADR-005 | No automatic retry on setup failure | accepted | On a failed setup re-invocation the skill stops, investigates the likely cause, and reports; retry is always a fresh, human-initiated invocation, never automatic |

### Feature 0000024: declared-product-id-for-telemetry

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | product.yml Extended to Single-Component Projects as Declared Product ID Home | accepted | `product.yml`'s `id` field becomes the canonical declared `product_id` for telemetry across all projects, including single-component ones; extends (does not supersede) 0000016 ADR-002, whose versioning-only decision remains fully in force |

### Feature 0000025: pipeline-gate-and-config-fixes-and-ship-agent-fixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Ship-agent PR Footer Default-Off with Opt-In Toggle | accepted | The hardcoded AI-attribution footer is removed from the P9 PR description template by default (both `gh pr create` and human-push paths); restorable only via a `planifest-overrides/instructions/` opt-in file, consistent with the existing `local-git-only` override pattern |
| ADR-002 | Setup-Config Overrides Precedence | accepted | The new tracked `planifest-overrides/setup-config/{tool}.md` file is source of truth for setup flags/backend-url; the existing gitignored `.planifest-setup-flags` marker becomes a local cache reconciled to match it on setup/refresh; `.orchestrator-strict` explicitly out of scope (separate concern) |
| ADR-003 | Scope Lock Default Drafted, Batch-Presented | accepted | Scope Lock Challenge now dispatches `planifest-scope-lock-agent` for all four scenario-path questions in parallel by default and presents them together for one batch accept/edit/reject pass: supersedes 0000017-ADR-003's opt-in-per-question default; explicitly scoped against 0000014-ADR-008's one-question-at-a-time convention, which is unchanged everywhere else |

### Feature 0000026: context-hook-and-telemetry-backstop-fixes

ADR files: [plan/_archive/0000026-context-hook-and-telemetry-backstop-fixes-2026-08-08/adr/](../plan/_archive/0000026-context-hook-and-telemetry-backstop-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | product.yml components[] as Path Pointers, Not Cached Versions | accepted | Amends 0000016-ADR-002: under `versionPolicy: max-component-version`, `components[]` holds `{id, path}` pointers to each component's own `component.yml` instead of a cached `{id, version}`; `product-version.mjs` reads the live version at derivation time, closing the sync-drift gap that surfaced during this feature's own ship review |

### Feature 0000027: backlog-batch-governance-tooling-fixes

ADR files: [plan/_archive/0000027-backlog-batch-governance-tooling-fixes-2026-08-08/adr/](../plan/_archive/0000027-backlog-batch-governance-tooling-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Telemetry emit_event Receipt Backstop | accepted | Extends the `check-telemetry-failures.mjs` hook family with a new `emit-event-receipt.mjs` (PostToolUse, matched on the `emit_event` MCP tool call) writing a durable receipt per successful call, and `check-telemetry-receipts.mjs` (sibling hook) cross-referencing build-log's per-phase "Telemetry: emitted" claims against those receipts: closes the remaining half of backlog 0000044 not already covered by 0000026 |
| ADR-002 | Framework Update Policy as a New P0 Step | accepted | Adds a dedicated P0 Start Actions step (Resume Detection 1a) detecting a `planifest-framework/` dependency update and gating on human confirmation of both the update and its provenance, documented in `standards/framework-update-policy.md`: deliberately not an extension of `planifest-migrator` (different I/O shape) nor a new standalone skill (disproportionate to the mechanism's actual complexity) |
| ADR-003 | Skill-Scope Principle: Does This Skill Earn Its Place | accepted | Records the governance test (does this skill provide governance or traceability the host tool cannot) with `planifest-test-writer`/`implementer`/`refactor`/`verify-by-execution` as worked examples (three retain, one retain-marginal); referenced from the orchestrator's Capability Skills guidance for future skill additions |
| ADR-004 | Minimal Default Phase 1 Artifact Set | accepted | Names execution plan, requirements, scope, risk register, and domain glossary as the always-produced Phase 1 set; OpenAPI/Operational Model/SLO Definitions/Cost Model each gated by an explicit, checkable trigger condition: reflected identically in `feature-pipeline.md` and `planifest-spec-agent`, closing the "documentation theatre" gap from backlog 0000021 |

### Feature 0000028: telemetry-hardening-and-enforcement-fixes

ADR files: [plan/_archive/0000028-telemetry-hardening-and-enforcement-fixes-2026-08-08/adr/](../plan/_archive/0000028-telemetry-hardening-and-enforcement-fixes-2026-08-08/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Network-Level Retry Semantics for Telemetry Emission | accepted | A telemetry emission failure is retried only when it is network-level, identified by `!err.name.startsWith("http_")`; an HTTP 4xx or 5xx means a listener answered and rejected the event and is never retried. Budget: 2 retries, 3 attempts total, fixed 300ms gaps, on top of the unchanged 3s per-attempt abort. Retry exhaustion writes the durable marker exactly as before, so a genuinely-down backend still surfaces. Narrows the definition of failure rather than adding a queue, which NFR-002 forbids |
| ADR-002 | Shared Module Placement and Install Topology | accepted | Each duplicated helper becomes one module inside the existing `hooks/enforcement/` and `hooks/telemetry/` trees, never a new top-level `shared/` directory that would need its own install glob in all three `setup.sh` paths. Placement follows install condition: `enforcement/` installs unconditionally, `telemetry/` only under `--structured-telemetry-mcp`, so any helper with an enforcement caller lives in `enforcement/` and is imported cross-directory. `read-stdin.mjs` was moved to `enforcement/` mid-implementation for exactly this reason, and its copy count was 13, not the 7 first recorded. Tier 1's telemetry glob widened from `emit-phase-*.mjs` to `*.mjs` in both `setup.sh` and `setup.ps1`, a latent bug independent of the extraction. No commit may contain a caller importing a module absent from that same commit |
| ADR-003 | Em Dash Guard Attachment Point and Bypass | accepted | The guard is a `PreToolUse(Write, Edit)` hook, `hooks/enforcement/em-dash-guard.mjs`, sibling to `gate-write.mjs` rather than a modification of it, so a defect in one cannot disable the other. A git hook was rejected because the character would already be on disk by commit time. Scoped to five prefixes: `plan/current/`, `docs/`, and `planifest-framework/` skills, templates and standards. Since Claude Code offers no per-call skip flag, the bypass is an in-content sentinel comment, visible in the artifact's own diff, reusable and writable by either party, deliberately unlike `.ratchet-approve`, which guards a commitment being weakened rather than a single character of punctuation |
| ADR-004 | Self-Modification Sequencing for Hook Extraction and Reinstall | accepted | When a feature rewrites the hooks executing its own build, rewire one caller at a time: edit, commit, re-run `setup.sh` for that edit alone, then assert a real side effect (event received, marker written, process spawned), never merely that the process returned. Exit 0 is uninformative by design (NFR-001), so a hook broken mid-edit degrades to a silent no-op, and an ESM import of a missing module fails before the hook's own try/catch runs. One `setup.sh` re-run at the end was rejected because it collapses good straight to multiply-broken with no way to bisect. A separate worktree was rejected outright by repo instruction |

### Feature 0000029: context-mode-removal-and-boot-file-regeneration-fix

ADR files: [plan/_archive/0000029-context-mode-removal-and-boot-file-regeneration-fix-2026-08-09/adr/](../plan/_archive/0000029-context-mode-removal-and-boot-file-regeneration-fix-2026-08-09/adr/)

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Boot Files Are Disposable Build Outputs | accepted | `write_boot_file`/`Write-PlanifestBootFile` overwrite the boot file unconditionally on every setup run; the skip-if-exists guard protected hand-editing, a workflow the framework does not support, while silently blocking template fixes from ever reaching installed repos. Durable customization belongs exclusively in `planifest-overrides/instructions/`, re-applied every run |
| ADR-002 | Boot Templates Never Name Third-Party MCP Plugins | accepted | Removes the unconditional context-mode instruction from `templates/standard-boot.md` (shipped into 6 of 9 tools' boot files) after the plugin injected a fabricated system-reminder instructing the agent to conceal a change from the human. Standing rule: boot-file text is trusted instruction text and never endorses a named third-party plugin; tool availability belongs to host-tool configuration, not template prose. The opt-in `--context-mode-mcp` hook path is untouched |

---

*Template: decisions-index.template.md*
