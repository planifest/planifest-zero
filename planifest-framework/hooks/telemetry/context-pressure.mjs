#!/usr/bin/env node
/**
 * PostToolUse hook: context pressure monitor for structured telemetry.
 *
 * Emits a `context_pressure` event to the structured telemetry MCP backend
 * when estimated context fill exceeds THRESHOLD_PCT (default: 70%).
 *
 * Installed only when both --structured-telemetry-mcp and --context-mode-mcp
 * are active at setup time. See plan/current/design.md — Context Pressure Hook.
 *
 * Fill % is estimated from transcript file size. This is a proxy metric —
 * it grows proportionally with context use within a session and resets at
 * session start. It does not account for compaction events.
 *
 * Silent on all errors (NFR-001). No retries. No local fallback (NFR-002).
 *
 * Durable failure marker (req-002, ADR-002): on emission failure this hook
 * still exits 0 and never blocks (NFR-001 unchanged) — but it now also
 * writes a best-effort marker file recording the root cause, instead of
 * swallowing the error with no trace.
 *
 *   Location: {cwd}/plan/.telemetry-failures/<slug>.json
 *     (plan/, not .claude/ — durable, git-visible, survives across sessions;
 *     a sibling of plan/.orchestrator-active, deliberately outside
 *     plan/current/ so it is never swept up by ratchet-check or archived at
 *     the P7 ship step.)
 *
 *   One file per distinct root cause — the filename is derived from
 *   `${hook}::${error_type}::${slugified error message}`. A repeat of the
 *   same failure updates the existing file (last_seen, occurrences); a
 *   genuinely different failure gets its own file. Clearing a marker
 *   (after the human is asked and answers, req-003) is a plain file delete.
 *
 *   Marker JSON shape:
 *     {
 *       "hook": "emit-phase-start" | "emit-phase-end" | "context-pressure",
 *       "root_cause_key": "<hook>::<error_type>::<slugified message>",
 *       "error_type": string,    // e.g. "TypeError", "AbortError", "http_500"
 *       "error_message": string,
 *       "phase": string | null,
 *       "session_id": string | null,
 *       "first_seen": ISO 8601 timestamp,
 *       "last_seen": ISO 8601 timestamp,
 *       "occurrences": number
 *     }
 */

import { statSync } from "node:fs";

// readStdin lives in hooks/enforcement/, the always-installed tree, not here
// (0000028-ADR-002). hooks/telemetry/ is never present without
// hooks/enforcement/, so this cross-directory import is always resolvable.
import { readStdin } from "../enforcement/read-stdin.mjs";
import { postEvent } from "./emit-event.mjs";
import { readProductId } from "./read-product-id.mjs";
import { recordTelemetryFailure } from "./record-telemetry-failure.mjs";

const THRESHOLD_PCT = 70;
// Rough estimate: ~900 KB of JSONL transcript ≈ full 200K token context window.
// 70% threshold ≈ 630 KB.
const ESTIMATED_MAX_BYTES = 900_000;
const BACKEND_URL = process.env.PLANIFEST_TELEMETRY_URL ?? "http://localhost:3741";

// Not consolidated (req-002, deliberate): getSessionId has 3 genuinely
// different behaviour profiles across its 4 copies. This one uses a
// 2-priority check (transcript path, then input.session_id) with a ppid
// fallback and never creates a session file, unlike emit-phase-start.mjs's
// 4-priority create-if-absent variant. Merging them would be a behaviour
// change, not a refactor. See plan/current/tech-debt.md.
function getSessionId(input) {
  if (input.transcript_path) {
    const match = input.transcript_path.match(/([a-f0-9-]{36})\.jsonl$/i);
    if (match) return match[1];
  }
  if (input.session_id) return input.session_id;
  return `pid-${process.ppid}`;
}

let cwd;
let sessionId;

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  cwd = input?.cwd ?? process.cwd();

  if (!input.transcript_path) {
    process.exit(0);
  }

  let transcriptBytes;
  try {
    transcriptBytes = statSync(input.transcript_path).size;
  } catch {
    process.exit(0);
  }

  const context_fill_pct =
    Math.min(100, Math.round((transcriptBytes / ESTIMATED_MAX_BYTES) * 1000) / 10);

  if (context_fill_pct <= THRESHOLD_PCT) {
    process.exit(0);
  }

  sessionId = getSessionId(input);

  const event = {
    schema_version: "1.0",
    event: "context_pressure",
    product_id: readProductId(cwd),
    session_id: sessionId,
    // "monitoring" is not a valid envelope `phase` value (see telemetry-standards.md's
    // enum) — context-pressure is a session-wide check the orchestrator owns
    // (see backlog 0000012), so it maps to "orchestrator" rather than a phase of its own.
    phase: "orchestrator",
    agent: "context-pressure-hook",
    tool: "claude-code",
    model: process.env.CLAUDE_API_MODEL ?? "unknown",
    mcp_mode: "workspace+context",
    timestamp: new Date().toISOString(),
    data: {
      context_fill_pct,
      unused_sources: [],
      trigger: "threshold_exceeded",
    },
  };

  // Fire-and-forget POST with a 3 s abort, shared with the emit-phase hooks.
  await postEvent(BACKEND_URL, event);
} catch (err) {
  // PostToolUse must never block the session — silent fallback (NFR-001).
  recordTelemetryFailure("context-pressure", err, { cwd, phase: "monitoring", sessionId });
}
