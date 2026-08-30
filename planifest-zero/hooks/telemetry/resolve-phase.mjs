#!/usr/bin/env node
/**
 * Phase resolver for emit-phase-start.mjs / emit-phase-end.mjs (req-001,
 * feature 0000027, folded backlog 0000043).
 *
 * WIRING PROBLEM (req-001 grounding): emit-phase-start.mjs (documented in its
 * own header as a PreToolUse hook) and emit-phase-end.mjs (documented as a
 * Stop hook) each require a positional `<phase>` CLI argument. A single hook
 * entry registered in .claude/settings.json is one fixed `command` string —
 * it cannot vary the argument it passes as the pipeline moves through phases
 * (spec, adr, codegen, validate, security, docs, ship) over the life of a
 * session.
 *
 * WIRING DECISION: rather than modifying either telemetry script (both stay
 * exactly as documented — a plain `<phase>` positional argument, unaware of
 * how that argument gets supplied), this resolver sits in front of both. The
 * registered hook `command` invokes THIS script instead of the real one; this
 * script infers the active phase from an observable, deterministic
 * tool-lifecycle signal — never from orchestrator prose or memory — and then
 * re-execs the real script with the phase supplied positionally, forwarding
 * the original stdin payload and environment unchanged.
 *
 * Usage:
 *   node resolve-phase.mjs start <path-to-emit-phase-start.mjs>   (PreToolUse, matcher "Skill")
 *   node resolve-phase.mjs end   <path-to-emit-phase-end.mjs>     (Stop, matcher ".*")
 *
 * --- start mode -------------------------------------------------------
 * The orchestrator invokes each pipeline phase by calling the Skill tool with
 * a phase-agent's skill name (see PHASE_SKILLS below). That Skill call is
 * itself a deterministic, hook-observable signal of a phase transition:
 *   1. Record the resolved phase to {cwd}/.claude/.planifest-active-phase
 *      (last-write-wins; read by `end` mode below).
 *   2. Re-exec emit-phase-start.mjs with the resolved phase.
 * A Skill call that doesn't match a known phase skill (planifest-test-writer,
 * planifest-implementer, planifest-refactor, a non-Planifest skill, etc.) is
 * not a phase transition — this resolver exits 0 silently, same as any other
 * hook miss (ADR-005 fail-open).
 *
 * --- end mode -----------------------------------------------------------
 * Stop fires at the end of every response turn, not only at the true end of
 * a phase — Claude Code's hook surface has no tool-lifecycle event that means
 * "this phase just completed." This resolver reads whichever phase was last
 * recorded by `start` mode and emits phase_end for it at most once per
 * (session, phase) pair, using the same tmpdir dedup-flag convention
 * emit-phase-start.mjs already uses for its own re-emission guard.
 *
 * KNOWN LIMITATION (documented deviation — see src/setup-hook-integration
 * quirks.md): for a phase that spans multiple turns, this fires on the FIRST
 * turn boundary after that phase's Skill call, not the true last one —
 * duration_ms under-reports the phase's real length for multi-turn phases.
 * Precise phase-end timing would require the orchestrator to explicitly
 * signal phase completion (a SKILL.md change, out of scope for this
 * requirement — req-001 is a hook-wiring requirement, not an orchestrator
 * behavior change). Presence of the event — what req-001/req-004 care about
 * ("no event type silently goes unemitted") — is preserved; exact duration
 * accuracy for multi-turn phases is not.
 *
 * Fail-open throughout (ADR-005): any resolution error exits 0 silently
 * without invoking the wrapped script. This is strictly additive coverage —
 * never a new way to block a turn.
 */

import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawn } from "node:child_process";

// PHASE_SKILLS maps the Skill tool's invoked skill name to the phase name used
// throughout the telemetry envelope (telemetry-standards.md's `phase` enum).
// It is derived from the shared enum (req-002, folding backlog 0000057) so it
// cannot drift from check-telemetry-receipts.mjs's PHASE_NUMBER_TO_ENUM.
//
// The module lives in hooks/enforcement/, the always-installed tree, rather
// than here (0000028-ADR-002): check-telemetry-receipts.mjs needs it and is
// installed on every install, whereas this file exists only when
// --structured-telemetry-mcp is set. hooks/telemetry/ is never present
// without hooks/enforcement/, so this cross-directory import is always
// resolvable.
import { PHASE_SKILLS } from "../enforcement/phase-enum.mjs";
import { readStdin } from "../enforcement/read-stdin.mjs";

const MODE = process.argv[2];
const TARGET_SCRIPT = process.argv[3];

// Not consolidated (req-002, deliberate): this getSessionId copy is read-only
// where emit-phase-start.mjs's creates the session file. See
// plan/current/tech-debt.md.
function getSessionId(input, cwd) {
  if (process.env.PLANIFEST_SESSION_ID) return process.env.PLANIFEST_SESSION_ID;
  if (input?.session_id) return input.session_id;
  if (input?.transcript_path) {
    const m = String(input.transcript_path).match(/([a-f0-9-]{36})\.jsonl$/i);
    if (m) return m[1];
  }
  try {
    const sessionFile = join(cwd, ".claude", ".planifest-session");
    if (existsSync(sessionFile)) return readFileSync(sessionFile, "utf-8").trim();
  } catch { /* fall through */ }
  return `pid-${process.pid}`;
}

function activePhaseFile(cwd) {
  return join(cwd, ".claude", ".planifest-active-phase");
}

function endDedupFlag(sessionId, phase) {
  return join(tmpdir(), "planifest-telemetry", `phase-end-emitted-${sessionId}-${phase}`);
}

// Extract the invoked skill name from a Skill tool's PreToolUse `tool_input`.
// Defensive about shape — Claude Code's own field name for the Skill tool's
// argument is treated as authoritative when present; `.name` is accepted as a
// fallback in case of future/alternate shapes.
function extractSkillName(input) {
  const ti = input?.tool_input ?? {};
  return ti.skill ?? ti.name ?? null;
}

// Re-invoke the real telemetry script, forwarding the original stdin payload
// and the current environment untouched. Never throws — resolves regardless
// of the child's outcome (fail-open, ADR-005).
function runTarget(phase, rawStdin) {
  return new Promise((resolve) => {
    try {
      const child = spawn(process.execPath, [TARGET_SCRIPT, phase], {
        env: process.env,
        stdio: ["pipe", "inherit", "inherit"],
      });
      child.on("error", () => resolve());
      child.on("close", () => resolve());
      child.stdin.on("error", () => { /* ignore EPIPE if child exits early */ });
      child.stdin.write(rawStdin);
      child.stdin.end();
    } catch {
      resolve();
    }
  });
}

async function runStart() {
  const raw = await readStdin();
  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    process.exit(0);
  }

  if (input?.tool_name !== "Skill") process.exit(0);

  const skillName = extractSkillName(input);
  const phase = skillName ? PHASE_SKILLS[skillName] : undefined;
  if (!phase) process.exit(0); // Not a phase-skill invocation — no transition.

  const cwd = input?.cwd ?? process.cwd();
  try {
    const phaseFile = activePhaseFile(cwd);
    mkdirSync(dirname(phaseFile), { recursive: true });
    writeFileSync(phaseFile, phase);
  } catch {
    // Best-effort — still attempt to emit phase_start even if the marker
    // write fails (ADR-005, never let bookkeeping block the real signal).
  }

  await runTarget(phase, raw);
  process.exit(0);
}

async function runEnd() {
  const raw = await readStdin();
  let input;
  try {
    input = JSON.parse(raw);
  } catch {
    process.exit(0);
  }

  const cwd = input?.cwd ?? process.cwd();
  const phaseFile = activePhaseFile(cwd);

  let phase;
  try {
    if (!existsSync(phaseFile)) process.exit(0);
    phase = readFileSync(phaseFile, "utf-8").trim();
  } catch {
    process.exit(0);
  }
  if (!phase) process.exit(0);

  const sessionId = getSessionId(input, cwd);
  const dedupFlag = endDedupFlag(sessionId, phase);
  if (existsSync(dedupFlag)) process.exit(0); // Already emitted for this (session, phase).

  try {
    mkdirSync(dirname(dedupFlag), { recursive: true });
    writeFileSync(dedupFlag, new Date().toISOString());
  } catch {
    // Best-effort — proceed to emit even if the dedup flag can't be written;
    // worst case is a duplicate emission, never a missed one (ADR-005).
  }

  await runTarget(phase, raw);

  // Clear the active-phase marker so a phase that never transitions to a
  // "next" phase (the pipeline's last phase, or an aborted session) doesn't
  // leave a stale phase recorded for the next session to misread.
  try {
    unlinkSync(phaseFile);
  } catch {
    // Non-fatal — absence is the desired end state either way.
  }

  process.exit(0);
}

try {
  if (MODE === "start" && TARGET_SCRIPT) {
    await runStart();
  } else if (MODE === "end" && TARGET_SCRIPT) {
    await runEnd();
  } else {
    process.exit(0);
  }
} catch {
  // Resolver failure must never block a turn (ADR-005) — silent fallback.
  process.exit(0);
}
