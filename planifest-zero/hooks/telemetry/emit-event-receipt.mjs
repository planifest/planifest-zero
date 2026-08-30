#!/usr/bin/env node
/**
 * PostToolUse hook: emit_event receipt writer (req-004, feature 0000027,
 * folded backlog 0000044; ADR-001).
 *
 * Matched (in .claude/settings.json) on the `emit_event` MCP tool call
 * (`mcp__structured-telemetry-mcp__emit_event`). On a successful call, writes
 * a durable local receipt file recording that the call actually happened —
 * closing the failure mode that motivated req-004: feature 0000025's P0-P2
 * run, where the orchestrator marked a build-log `Telemetry` field "emitted"
 * without ever having called `emit_event`, and nothing caught it until a
 * human did.
 *
 * Receipt location: {cwd}/plan/.telemetry-receipts/{phase}-{event_type}-{ts}.marker
 *   (plan/, not .claude/ — durable, git-visible, survives across sessions,
 *   consistent with plan/.telemetry-failures/'s placement rationale).
 *   `{ts}` is the emission timestamp with `:` replaced by `-` — ISO 8601
 *   timestamps contain colons, which are invalid in Windows filenames; every
 *   other marker-writing hook in this family already sanitizes for the same
 *   reason (see recordTelemetryFailure()'s fileSlug conversion in
 *   emit-phase-start.mjs et al.).
 *
 * check-telemetry-receipts.mjs (hooks/enforcement/, sibling to
 * check-telemetry-failures.mjs) cross-references these receipts against
 * build-log.md's per-phase `Telemetry: emitted` claims.
 *
 * Per ADR-001's own risk note: if this hook's own emission/parsing fails
 * (e.g. the MCP tool's argument shape changes), that failure routes through
 * the existing plan/.telemetry-failures/ marker mechanism, exactly like
 * every other telemetry hook in this repo — never a distinct, incompatible
 * failure-reporting path.
 *
 * Always exits 0 — a PostToolUse hook must never block a turn (ADR-005).
 */

import { mkdirSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// readStdin and the phase enum live in hooks/enforcement/, the always-installed
// tree, not here (0000028-ADR-002). hooks/telemetry/ is never present without
// hooks/enforcement/, so these cross-directory imports are always resolvable.
import { KNOWN_PHASES } from "../enforcement/phase-enum.mjs";
import { readStdin } from "../enforcement/read-stdin.mjs";
import { recordTelemetryFailure } from "./record-telemetry-failure.mjs";

// Closed sets from telemetry-standards.md — the envelope's `phase`/`event`
// fields are agent-supplied tool-call arguments, not validated by the MCP
// tool itself before this hook sees them. Constructing a file path from an
// unvalidated string (e.g. "../../../etc/whatever") is a path-traversal risk
// (CWE-22) even via node:path's `join`, which does not sandbox `..` segments.
// Found and fixed during this feature's own P5 security review.
// KNOWN_PHASES is imported from the shared phase enum (req-002, folding
// backlog 0000057) so this guard cannot fall out of step with
// check-telemetry-receipts.mjs or resolve-phase.mjs.
const KNOWN_EVENT_TYPES = new Set([
  "phase_start", "phase_end", "phase_skip",
  "spec_gap", "validation_failure", "self_correction", "deviation",
  "migration_proposal", "context_pressure", "mcp_impact",
  "adr_decision", "security_finding", "retry_limit_exceeded", "doc_gap",
]);

function isToolCallError(toolResponse) {
  if (!toolResponse || typeof toolResponse !== "object") return false;
  return toolResponse.is_error === true || toolResponse.isError === true;
}

let cwd;

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  cwd = input?.cwd ?? process.cwd();

  if (isToolCallError(input?.tool_response)) {
    // The emit_event call itself failed — there is nothing to receipt. This
    // is exactly the "orchestrator claimed emitted, call didn't happen"
    // shape req-004 exists to catch; leave no receipt so
    // check-telemetry-receipts.mjs flags the gap on its own.
    process.exit(0);
  }

  const envelope = input?.tool_input?.envelope;
  const eventType = envelope?.event;
  const phase = envelope?.phase;

  if (!envelope || !eventType || !phase) {
    // Malformed/unexpected tool_input shape (e.g. the MCP tool's argument
    // contract changed) — record as a failure per ADR-001's own risk note,
    // rather than silently writing nothing with no trace at all.
    throw new Error("emit_event tool_input missing envelope.event or envelope.phase");
  }

  if (!KNOWN_PHASES.has(phase) || !KNOWN_EVENT_TYPES.has(eventType)) {
    // Reject anything outside the closed sets before it reaches path
    // construction — never build a filename from an unvalidated string.
    throw new Error(`emit_event envelope has unrecognised phase="${phase}" or event="${eventType}"`);
  }

  const receiptDir = join(cwd, "plan", ".telemetry-receipts");
  mkdirSync(receiptDir, { recursive: true });

  const timestamp = new Date().toISOString();
  const safeTimestamp = timestamp.replace(/:/g, "-");
  const receiptPath = join(receiptDir, `${phase}-${eventType}-${safeTimestamp}.marker`);

  const receipt = {
    phase,
    event_type: eventType,
    timestamp,
    schema_version: envelope?.schema_version ?? null,
    product_id: envelope?.product_id ?? null,
  };

  const tmpPath = `${receiptPath}.tmp`;
  writeFileSync(tmpPath, JSON.stringify(receipt, null, 2));
  renameSync(tmpPath, receiptPath);
} catch (err) {
  // PostToolUse must never block the session — silent fallback (ADR-005).
  recordTelemetryFailure("emit-event-receipt", err, { cwd });
}
