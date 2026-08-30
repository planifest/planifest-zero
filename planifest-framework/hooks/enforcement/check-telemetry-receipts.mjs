#!/usr/bin/env node
/**
 * UserPromptSubmit hook: emit_event compliance backstop (req-004, feature
 * 0000027, folded backlog 0000044; ADR-001).
 *
 * Sibling of check-telemetry-failures.mjs, added rather than folding into it
 * (ADR-001's own "implementer's choice, whichever keeps the diff smallest" —
 * these two checks read different sources and have different failure shapes:
 * check-telemetry-failures.mjs reads plan/.telemetry-failures/ markers,
 * this one cross-references plan/current/build-log.md's per-phase Telemetry
 * claims against plan/.telemetry-receipts/ files written by
 * hooks/telemetry/emit-event-receipt.mjs).
 *
 * The check: for each phase block in build-log.md whose `Telemetry` field
 * reads "emitted", verify at least one receipt exists for that phase under
 * plan/.telemetry-receipts/. A block claiming "emitted" with zero matching
 * receipts is flagged — this is the exact failure mode that motivated
 * req-004: feature 0000025's P0-P2 run, where the orchestrator marked a
 * build-log field "emitted" without ever having called `emit_event`, and
 * nothing caught it until a human did.
 *
 * "failed-with-recorded-choice" and "confirmed-disabled" are the template's
 * other two Telemetry states (templates/build-log.template.md) — neither
 * claims a call happened, so neither is checked against receipts here.
 *
 * Phase-heading -> phase-enum mapping: build-log.md headings read
 * "### P<n> — {Phase Name}" (free text); the phase enum used throughout
 * telemetry-standards.md and by resolve-phase.mjs's PHASE_SKILLS table is
 * spec/adr/codegen/validate/security/docs/ship. P0 (Assess & Coach) has no
 * enum of its own (excluded from the phase_start/phase_end enum per
 * telemetry-standards.md) and is skipped; P7/P8/P9 all map to "ship" (the
 * ship-agent owns all three sub-phases).
 *
 * PHASE_NUMBER_TO_ENUM is imported from ./phase-enum.mjs (req-002, folding
 * backlog 0000057) rather than declared here, so it cannot drift from
 * resolve-phase.mjs's PHASE_SKILLS or emit-event-receipt.mjs's KNOWN_PHASES.
 *
 * Deliberately read-only and advisory, like check-telemetry-failures.mjs:
 * never blocks, never decides, only surfaces (ADR-005/ADR-001). Always
 * exits 0.
 *
 * Receives: JSON on stdin (Claude Code UserPromptSubmit hook input).
 * Outputs: JSON { additionalContext: "<string>" } on stdout, or nothing.
 */

import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

import { PHASE_NUMBER_TO_ENUM } from "./phase-enum.mjs";
import { readStdin } from "./read-stdin.mjs";

// Parse build-log.md's phase blocks: heading "### P<n> — ..." followed
// (somewhere before the next "###" heading) by a "| Telemetry | <state> |"
// table row. The template's own placeholder block ("### Px — {Phase Name}")
// never matches \d and is skipped naturally.
function parsePhaseBlocks(content) {
  const lines = content.split(/\r?\n/);
  const blocks = [];
  let current = null;

  const headingRe = /^###\s+P(\d+)\s+—/;
  const telemetryRe = /^\|\s*Telemetry\s*\|\s*([^|]+?)\s*\|/;

  for (const line of lines) {
    const headingMatch = headingRe.exec(line);
    if (headingMatch) {
      if (current) blocks.push(current);
      current = { phaseNumber: Number(headingMatch[1]), telemetry: null };
      continue;
    }
    if (current && current.telemetry === null) {
      const telemetryMatch = telemetryRe.exec(line);
      if (telemetryMatch) {
        current.telemetry = telemetryMatch[1].trim();
      }
    }
  }
  if (current) blocks.push(current);

  return blocks;
}

function receiptExistsForPhase(receiptsDir, phase) {
  let entries;
  try {
    entries = readdirSync(receiptsDir);
  } catch {
    return false;
  }
  const prefix = `${phase}-`;
  return entries.some((entry) => entry.endsWith(".marker") && entry.startsWith(prefix));
}

try {
  const raw = await readStdin();
  const input = JSON.parse(raw);
  const cwd = input?.cwd ?? process.cwd();

  const buildLogPath = join(cwd, "plan", "current", "build-log.md");
  if (!existsSync(buildLogPath)) process.exit(0);

  let content;
  try {
    content = readFileSync(buildLogPath, "utf-8");
  } catch {
    process.exit(0);
  }

  const blocks = parsePhaseBlocks(content);
  const receiptsDir = join(cwd, "plan", ".telemetry-receipts");

  const gaps = [];
  for (const block of blocks) {
    if (block.telemetry !== "emitted") continue;
    const phase = PHASE_NUMBER_TO_ENUM[block.phaseNumber];
    if (!phase) continue; // P0 (assess) has no phase_start/phase_end enum.
    if (!receiptExistsForPhase(receiptsDir, phase)) {
      gaps.push({ phaseNumber: block.phaseNumber, phase });
    }
  }

  if (gaps.length === 0) process.exit(0);

  const lines = gaps
    .map((g) => `  - P${g.phaseNumber} (phase: ${g.phase}) — build-log.md marks Telemetry "emitted" but no receipt was found under plan/.telemetry-receipts/`)
    .join("\n");

  const additionalContext =
    "[Planifest] Telemetry compliance gap detected — a build-log.md phase block claims " +
    '"Telemetry: emitted" with no corresponding emit_event receipt on disk:\n\n' +
    lines +
    "\n\nThis is the failure mode req-004 (backlog 0000044) exists to catch: a phase's " +
    "Telemetry field was marked \"emitted\" without emit_event actually having been called. " +
    "Per 0000016-ADR-007's deterministic-enforcement precedent, verify whether the agent-driven " +
    "emit_event call for this phase actually happened before trusting the build-log entry; " +
    "correct the record if it did not. This hook only surfaces the reminder — it never blocks " +
    "and never corrects the record itself.";

  process.stdout.write(JSON.stringify({ additionalContext }));
  process.exit(0);
} catch {
  // UserPromptSubmit must never block a turn — silent fallback (ADR-005).
  process.exit(0);
}
