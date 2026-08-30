#!/usr/bin/env node
/**
 * PreToolUse hook: phase_start telemetry emission.
 *
 * Fires on first tool use within a phase. Guards against re-emission using a
 * flag file keyed by session_id + phase (DD-001, ADR-003).
 *
 * Usage:  node emit-phase-start.mjs <phase>
 *   e.g.  node emit-phase-start.mjs spec
 *
 * Session ID fallback: reads/creates {cwd}/.claude/.planifest-session when
 * PLANIFEST_SESSION_ID is absent (R-005 mitigation, ADR-003).
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

import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { randomUUID } from "node:crypto";

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

// Not consolidated (req-002, deliberate): this is the only getSessionId copy
// that creates {cwd}/.claude/.planifest-session when absent. The other 3
// copies are read-only, and context-pressure.mjs's uses a different priority
// order entirely. Merging them would either start or stop creating the
// session file somewhere, which is a behaviour change, not a refactor.
// See plan/current/tech-debt.md.
function getSessionId(input, cwd) {
  // Priority 1: explicit env var
  if (process.env.PLANIFEST_SESSION_ID) return process.env.PLANIFEST_SESSION_ID;
  // Priority 2: hook input session_id field
  if (input?.session_id) return input.session_id;
  // Priority 3: UUID from transcript path filename
  if (input?.transcript_path) {
    const m = input.transcript_path.match(/([a-f0-9-]{36})\.jsonl$/i);
    if (m) return m[1];
  }
  // Priority 4: project-scoped session file (R-005 mitigation)
  try {
    const sessionFile = join(cwd, ".claude", ".planifest-session");
    if (existsSync(sessionFile)) return readFileSync(sessionFile, "utf-8").trim();
    const id = randomUUID();
    mkdirSync(dirname(sessionFile), { recursive: true });
    writeFileSync(sessionFile, id);
    return id;
  } catch {
    return `pid-${process.pid}`;
  }
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
  const flagPath = getFlagPath(sessionId, PHASE);

  // Deduplication guard — exit 0 if already emitted this session+phase (ADR-003)
  if (existsSync(flagPath)) process.exit(0);

  // Write flag file atomically with ISO 8601 start timestamp (used by emit-phase-end.mjs)
  const timestamp = new Date().toISOString();
  const flagDir = dirname(flagPath);
  mkdirSync(flagDir, { recursive: true });
  const tmpPath = `${flagPath}.tmp`;
  writeFileSync(tmpPath, timestamp);
  renameSync(tmpPath, flagPath);

  const event = {
    schema_version: "1.0",
    event: "phase_start",
    product_id: readProductId(cwd),
    session_id: sessionId,
    phase: PHASE,
    agent: `planifest-${PHASE}-agent`,
    tool: process.env.PLANIFEST_TOOL ?? "claude-code",
    model: process.env.CLAUDE_API_MODEL ?? "unknown",
    mcp_mode: "none",
    timestamp,
    data: { phase_name: PHASE },
  };

  // Fire-and-forget POST with a 3 s abort (ADR-005, NFR), shared with the
  // other two emitting hooks.
  await postEvent(BACKEND_URL, event);
} catch (err) {
  // PreToolUse must never block the session — silent fallback (ADR-005).
  recordTelemetryFailure("emit-phase-start", err, { cwd, phase: PHASE, sessionId });
}
