#!/usr/bin/env node
/**
 * Stop hook: phase_end telemetry emission.
 *
 * Fires at the end of each response turn. Reads the start timestamp from the
 * phase-start flag file to compute duration_ms (ADR-003, REQ-002).
 *
 * Usage:  node emit-phase-end.mjs <phase>
 *   e.g.  node emit-phase-end.mjs spec
 *
 * Silent on all errors (ADR-005). No retries. 3-second abort on HTTP.
 *
 * Durable failure marker (req-002, ADR-002): on emission failure this hook
 * still exits 0 and never blocks (ADR-005 unchanged) — but it now also
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

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

// readStdin lives in hooks/enforcement/, the always-installed tree, not here
// (0000028-ADR-002). hooks/telemetry/ is never present without
// hooks/enforcement/, so this cross-directory import is always resolvable.
import { readStdin } from "../enforcement/read-stdin.mjs";
import { postEvent } from "./emit-event.mjs";
import { getFlagPath } from "./get-flag-path.mjs";
import { readProductId } from "./read-product-id.mjs";
import { recordTelemetryFailure } from "./record-telemetry-failure.mjs";

const BACKEND_URL = process.env.PLANIFEST_TELEMETRY_URL;
const PHASE = process.argv[2];

// Not consolidated (req-002, deliberate): this copy is read-only where
// emit-phase-start.mjs's creates the session file, so the two cannot be
// merged without changing one of them. See plan/current/tech-debt.md.
function getSessionId(input, cwd) {
  if (process.env.PLANIFEST_SESSION_ID) return process.env.PLANIFEST_SESSION_ID;
  if (input?.session_id) return input.session_id;
  if (input?.transcript_path) {
    const m = input.transcript_path.match(/([a-f0-9-]{36})\.jsonl$/i);
    if (m) return m[1];
  }
  try {
    const sessionFile = join(cwd, ".claude", ".planifest-session");
    if (existsSync(sessionFile)) return readFileSync(sessionFile, "utf-8").trim();
  } catch { /* silent */ }
  return `pid-${process.pid}`;
}

let cwd;
let sessionId;

try {
  // Sentinel check: no telemetry URL or no phase arg = silent exit (REQ-004)
  if (!BACKEND_URL || !PHASE) process.exit(0);

  const raw = await readStdin();
  const input = JSON.parse(raw);
  cwd = input?.cwd ?? process.cwd();
  sessionId = getSessionId(input, cwd);
  const now = Date.now();

  // Read start timestamp from flag file for duration_ms (ADR-003)
  let duration_ms;
  try {
    const flagPath = getFlagPath(sessionId, PHASE);
    if (existsSync(flagPath)) {
      const startTs = new Date(readFileSync(flagPath, "utf-8").trim()).getTime();
      if (!isNaN(startTs)) duration_ms = now - startTs;
    }
  } catch { /* no flag file = omit duration */ }

  const event = {
    schema_version: "1.0",
    event: "phase_end",
    product_id: readProductId(cwd),
    session_id: sessionId,
    phase: PHASE,
    agent: `planifest-${PHASE}-agent`,
    tool: process.env.PLANIFEST_TOOL ?? "claude-code",
    model: process.env.CLAUDE_API_MODEL ?? "unknown",
    mcp_mode: "none",
    timestamp: new Date().toISOString(),
    data: {
      phase_name: PHASE,
      status: "pass",
      ...(duration_ms !== undefined ? { duration_ms } : {}),
    },
  };

  // Fire-and-forget POST with a 3 s abort (ADR-005, NFR), shared with the
  // other two emitting hooks.
  await postEvent(BACKEND_URL, event);
} catch (err) {
  // Stop hook must never block the session — silent fallback (ADR-005).
  recordTelemetryFailure("emit-phase-end", err, { cwd, phase: PHASE, sessionId });
}
