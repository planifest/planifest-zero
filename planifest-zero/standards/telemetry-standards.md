---
title: "Telemetry Standards"
version: "2.0.0"
---
# Telemetry Standards

Shared telemetry rules for all Planifest skills that emit events via `emit_event`.

---

## Unified Telemetry Signal

Telemetry is gated by a single condition: `--structured-telemetry-mcp` was passed to `setup.sh`/`setup.ps1`. This one flag is sufficient on its own to:

1. Write the `.claude/telemetry-enabled` sentinel (gates agent-driven `emit_event` calls)
2. Wire the telemetry hooks in `.claude/settings.json` with the backend URL embedded (gates hook-driven `phase_start`/`phase_end`/`context_pressure` posts)

For agent-driven `emit_event` calls specifically, there is a second, separate condition: the tool must be loaded/callable in the current session. Hook-driven emission has no equivalent "tool availability" condition: it posts directly via HTTP from the hook subprocess.

The sentinel and the hook wiring remain technically distinct mechanisms. The single flag above means they are always set together, never independently.

---

## Emission is Mandatory When Enabled: Failure is Never Silent

When the unified signal (above) is active, emission is mandatory, not best-effort. A failure to emit is never silently skipped: see "Failure Detection and Interactive Recovery" below for what happens instead. When the unified signal is genuinely absent (telemetry not enabled for this project), that is not a failure: no prompt, no marker, pipeline proceeds exactly as if telemetry didn't exist.

---

## Failure Detection and Interactive Recovery

Telemetry emission fails in two structurally different ways, handled differently:

**Hook-driven emission** (`emit-phase-start.mjs`, `emit-phase-end.mjs`, `context-pressure.mjs`) stays fire-and-forget and exit-zero (hooks must never block the session or exit non-zero, regardless of emission outcome). On failure, the hook writes a durable failure marker recording the root cause (hook name + error identity) instead of swallowing the error; the marker write itself is also best-effort. The orchestrator checks for this marker at every phase-start checkpoint; if present and not yet acknowledged this run, it surfaces the block-or-proceed question (below) once for that root cause, then clears the marker.

**Agent-driven emission** (`emit_event` calls made inline by a phase skill for `adr_decision`, `security_finding`, `self_correction`, `deviation`, `spec_gap`, `doc_gap`, `validation_failure`, `retry_limit_exceeded`) happens live in conversation. On failure (including the `emit_event` tool not being loaded when the unified signal is active), the calling skill stops immediately, states the exact error, and asks the block-or-proceed question inline in the same turn: no marker needed.

**The block-or-proceed question**, either path: *"Telemetry emission failed: {error}. Block until resolved, or proceed without telemetry for the rest of this run?"* The human's answer is recorded in `plan/current/build-log.md` and honored for the rest of the pipeline run: the same root cause is never asked about twice in one run. A genuinely different, new root cause occurring later in the same run is asked about again, independently.

---

## Build Log Telemetry Record

Every phase's `build-log.md` block includes a `Telemetry` field recording one of: `emitted` (successful), `failed-with-recorded-choice` (a failure occurred, the human answered, recorded), or `confirmed-disabled` (the unified signal was genuinely absent, not a failure). This is the self-auditing trail: a human or the ship phase's build assessment can verify, for any archived feature, that telemetry was never silently skipped.

---

## Phase Enum

The `phase_name` and `phase` fields take exactly five values, one per pipeline phase:

`discovery`, `plan`, `implement`, `validate-and-accept`, `ship`

This list is the source of truth. `hooks/enforcement/phase-enum.mjs` exports the same five values, and its consumers derive from that export rather than duplicating the list.

---

## phase_start and phase_end Ownership

`phase_start` and `phase_end` are emitted by the **orchestrator**, not phase skills. The orchestrator emits `phase_start` before invoking a skill and `phase_end` after it completes. Phase skills must not emit these events themselves.

Hooks emit `phase_start`/`phase_end` natively; the snippets below are the backup path for tools without hook support. The orchestrator alone owns `phase_skip`: phase skills never emit `phase_start`, `phase_end`, or `phase_skip`.

**`phase_start`**: emit immediately before invoking each phase skill:
```json
{ "phase_name": "discovery" | "plan" | "implement" | "validate-and-accept" | "ship" }
```

**`phase_end`**: emit immediately after the gate check for each phase:
```json
{ "phase_name": "<phase>", "status": "pass" | "fail", "duration_ms": <elapsed ms> }
```

**`phase_skip`**: emit instead of `phase_start`/`phase_end` when a phase is bypassed:
```json
{ "phase_name": "<skipped phase>", "reason": "<why>" }
```

**`spec_gap`**: when human clarification is required before proceeding (discovery):
```json
{ "question": "<the question>", "phase_name": "discovery" }
```

**`mcp_impact`**: once after the final `phase_end` of a complete pipeline run:
```json
{ "mcp_mode": "<active mode>", "avg_token_delta": <number>, "peak_fill_pct": <number> }
```

---

## Event Type Reference

14 event types. Each maps to the skill that emits it:

| Category | Event | When | Owner |
|---|---|---|---|
| Pipeline lifecycle | `phase_start` | Phase beginning | planifest-orchestrator |
| | `phase_end` | Phase completion with status/duration | planifest-orchestrator |
| | `phase_skip` | Phase bypassed with reason | planifest-orchestrator |
| Quality & validation | `spec_gap` | Unanswered question blocking progress | planifest-orchestrator (discovery) |
| | `validation_failure` | Failed check with retry tracking | planifest-validate-and-accept |
| | `self_correction` | Agent correcting its own output | planifest-validate-and-accept |
| | `deviation` | Implementation diverged from spec | planifest-implement |
| Schema & data | `migration_proposal` | Proposed destructive schema change | planifest-implement |
| Token & context | `context_pressure` | Context window fill % (hook-emitted, not agent) | hook |
| | `mcp_impact` | Token delta by MCP mode | planifest-orchestrator |
| Decisions & findings | `adr_decision` | Architectural decision recorded | planifest-plan |
| | `security_finding` | Vulnerability found (severity: low\|medium\|high\|critical) | planifest-validate-and-accept |
| | `retry_limit_exceeded` | Action hit max attempts | any phase skill |
| | `doc_gap` | Missing documentation identified | planifest-implement |

---

## Event Envelope

Every `emit_event` call must use this envelope. The `data` field carries event-specific payload (defined per-skill).

```json
{
  "schema_version": "1.0",
  "event": "<event_name>",
  "product_id": "<declared product id from product.yml's id field>",
  "agent": "<skill-name e.g. planifest-validate-and-accept>",
  "phase": "<phase e.g. validate-and-accept>",
  "tool": "<tool e.g. claude-code>",
  "model": "<active model id>",
  "mcp_mode": "none | workspace | context | workspace+context",
  "session_id": "<session id>",
  "timestamp": "<ISO 8601 UTC>",
  "data": { }
}
```

The snippets in each skill's `## Telemetry` section show the `data` field content only: the full envelope above always wraps it.

**Calling `emit_event`:** the MCP tool's top-level call argument is named `envelope`, not `event`: do not confuse this with the envelope's own internal `event` discriminator field shown above (e.g. `emit_event({ envelope: { schema_version: "1.0", event: "phase_start", ... } })`). Passing the envelope object as a flat/`event`-named argument, or as a JSON string, fails with a structural validation error rather than succeeding.

`product_id` attributes an event to the repo it was emitted from, so events from multiple projects sharing one telemetry backend don't show "unknown". It is sourced from `product.yml`'s `id` field: the declared product identity, confirmed by the human at discovery and durable across machines and clones. There is no path-based fallback: hook-driven emission (`emit-phase-start.mjs`, `emit-phase-end.mjs`, `context-pressure.mjs`) treats an absent, unparseable, or `id`-less `product.yml` as an emission failure, routed through the existing `recordTelemetryFailure()` marker mechanism (never blocking). Agent-driven inline `emit_event` calls resolve `product_id` the same way, from `product.yml`, with no fallback value, and if it cannot be resolved, stop and ask the human per the Failure Detection and Interactive Recovery rules above.

---

## Loop Events

Emitted by looping agents per `planifest-loop-runner`. Loop events are async and non-blocking: an emission failure is logged once and never stops a loop. `data` payload:

**`loop_iteration`**: after every loop iteration's RECORD step:
```json
{ "loop_id": "<loop id, e.g. discovery_completeness | verify_by_execution>", "iteration": 1, "cap": 3, "decision": "continue | done | escalate", "toggle_level": "report-only | on" }
```

The ship phase's build assessment queries these to report per-loop iteration counts and attempted-weakening surfacing.
