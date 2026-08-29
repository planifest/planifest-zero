#!/usr/bin/env node
/**
 * Positive-presence check for telemetry hook wiring (req-001, feature 0000027,
 * folded backlog 0000043).
 *
 * `install_telemetry_hooks()`/`merge_telemetry_hook_settings()` in setup.sh
 * (and setup.ps1) copy the telemetry hook scripts to disk and register hook
 * entries in the target tool's settings file. Copying the file to disk is not
 * proof the hook is actually wired — the exact gap this requirement exists to
 * close was: three scripts copied, only one ever referenced by a hook entry.
 *
 * This script parses the settings JSON (not a grep — a regression that
 * happens to leave the substring "context-pressure" somewhere unrelated in
 * the file must not pass) and asserts each telemetry hook is present in the
 * hook-event array its own header documents:
 *   - context-pressure.mjs  -> hooks.PostToolUse
 *   - emit-phase-start.mjs  -> hooks.PreToolUse (via resolve-phase.mjs, see
 *     hooks/telemetry/resolve-phase.mjs for the phase-argument wiring design)
 *   - emit-phase-end.mjs    -> hooks.Stop (via resolve-phase.mjs)
 *   - emit-event-receipt.mjs -> hooks.PostToolUse (req-004, ADR-001)
 *
 * Usage: node verify-telemetry-hooks.mjs <settings-file> [--with-receipt]
 * Exit code: 0 if every expected hook is present, 1 (with a human-readable
 * message on stderr) if any is missing. This is intentionally NOT fail-open —
 * unlike the runtime telemetry hooks themselves (which must never block a
 * session, ADR-005), this is a setup-time installation check: a partial-wiring
 * regression must fail loudly, per req-001's explicit acceptance criterion.
 */

import { readFileSync } from "node:fs";

const settingsFile = process.argv[2];
const withReceipt = process.argv.includes("--with-receipt");

if (!settingsFile) {
  console.error("Usage: node verify-telemetry-hooks.mjs <settings-file> [--with-receipt]");
  process.exit(1);
}

let settings;
try {
  const raw = readFileSync(settingsFile, "utf-8").replace(/^﻿/, "");
  settings = JSON.parse(raw);
} catch (err) {
  console.error(`telemetry hook presence check FAILED — could not read/parse ${settingsFile}: ${err.message}`);
  process.exit(1);
}

const hooks = settings?.hooks ?? {};

function flatCommands(entries) {
  return (entries ?? []).flatMap((entry) => (entry?.hooks ?? []).map((h) => h?.command ?? ""));
}

const postToolUse = flatCommands(hooks.PostToolUse);
const preToolUse = flatCommands(hooks.PreToolUse);
const stop = flatCommands(hooks.Stop);

function present(commands, ...substrings) {
  return commands.some((cmd) => substrings.every((s) => cmd.includes(s)));
}

const checks = [
  { label: "context-pressure.mjs (PostToolUse)", ok: present(postToolUse, "context-pressure.mjs") },
  { label: "emit-phase-start.mjs (PreToolUse, via resolve-phase.mjs)", ok: present(preToolUse, "resolve-phase.mjs", "emit-phase-start.mjs") },
  { label: "emit-phase-end.mjs (Stop, via resolve-phase.mjs)", ok: present(stop, "resolve-phase.mjs", "emit-phase-end.mjs") },
];

if (withReceipt) {
  checks.push({
    label: "emit-event-receipt.mjs (PostToolUse)",
    ok: present(postToolUse, "emit-event-receipt.mjs"),
  });
}

const missing = checks.filter((c) => !c.ok).map((c) => c.label);

if (missing.length > 0) {
  console.error("telemetry hook presence check FAILED — missing hook entries:");
  for (const m of missing) console.error(`  - ${m}`);
  process.exit(1);
}

console.log(`telemetry hook presence check passed (${checks.length}/${checks.length} hooks registered)`);
process.exit(0);
