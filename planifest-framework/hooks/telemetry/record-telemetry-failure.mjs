/**
 * Shared hook helper: durable telemetry-failure marker writer.
 *
 * Extracted per req-002 / 0000028-ADR-002 from the 4 copies in
 * context-pressure.mjs, emit-phase-start.mjs, emit-phase-end.mjs and
 * emit-event-receipt.mjs. Those copies differed only in comment text (an
 * NFR-001 versus ADR-005 tag reference, and 3 comment lines omitted in
 * emit-event-receipt.mjs); the executable logic was identical, and is
 * reproduced here unchanged.
 *
 * PLACEMENT: hooks/telemetry/. All 4 callers are telemetry hooks. setup.sh's
 * Tier 1 telemetry glob was widened from emit-phase-*.mjs to *.mjs (req-002)
 * so Tier 1 installs receive this file alongside its emit-phase callers.
 *
 * On emission failure the calling hook still exits 0 and never blocks
 * (NFR-001 / ADR-005 unchanged), but it also writes a best-effort marker
 * recording the root cause instead of swallowing the error with no trace.
 *
 *   Location: {cwd}/plan/.telemetry-failures/<slug>.json
 *     plan/, not .claude/: durable, git-visible, survives across sessions;
 *     a sibling of plan/.orchestrator-active, deliberately outside
 *     plan/current/ so it is never swept up by ratchet-check or archived at
 *     the P7 ship step.
 *
 *   One file per distinct root cause. The filename derives from
 *   `${hook}::${error_type}::${slugified error message}`. A repeat of the
 *   same failure updates the existing file (last_seen, occurrences); a
 *   genuinely different failure gets its own file. Clearing a marker (after
 *   the human on the loop is asked and answers) is a plain file delete.
 *
 *   Marker JSON shape:
 *     {
 *       "hook": "emit-phase-start" | "emit-phase-end" | "context-pressure"
 *               | "emit-event-receipt",
 *       "root_cause_key": "<hook>::<error_type>::<slugified message>",
 *       "error_type": string,    // e.g. "TypeError", "AbortError", "http_500"
 *       "error_message": string,
 *       "phase": string | null,
 *       "session_id": string | null,
 *       "first_seen": ISO 8601 timestamp,
 *       "last_seen": ISO 8601 timestamp,
 *       "occurrences": number
 *     }
 *
 * Never throws. A failure here is swallowed so it can never affect the
 * calling hook's exit-zero/never-block behaviour. It is not swallowed
 * silently though (req-003): if the marker write itself fails, one line
 * goes to stderr naming the hook and marker path, so a genuinely-down
 * backend combined with an unwritable plan/ still leaves a trace somewhere.
 */

import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export function recordTelemetryFailure(hookName, err, context = {}) {
  let markerPath;
  try {
    const cwd = context.cwd ?? process.cwd();
    const errorType = context.errorType ?? err?.name ?? err?.constructor?.name ?? "Error";
    const errorMessage = String(err?.message ?? err ?? "unknown error");
    const slug =
      errorMessage.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 60) ||
      "unknown";
    const rootCauseKey = `${hookName}::${errorType}::${slug}`;
    const dir = join(cwd, "plan", ".telemetry-failures");
    // Colon-free filename (Windows-safe). "::" segment separators are
    // preserved as "--"; unsafe characters within each segment collapse to a
    // single "-".
    const fileSlug = rootCauseKey
      .split("::")
      .map((seg) => seg.replace(/[^a-zA-Z0-9_-]+/g, "-").replace(/^-+|-+$/g, "") || "unknown")
      .join("--");
    markerPath = join(dir, `${fileSlug}.json`);

    mkdirSync(dir, { recursive: true });

    const now = new Date().toISOString();
    let occurrences = 1;
    let firstSeen = now;
    if (existsSync(markerPath)) {
      try {
        const prev = JSON.parse(readFileSync(markerPath, "utf-8"));
        if (typeof prev.occurrences === "number") occurrences = prev.occurrences + 1;
        if (prev.first_seen) firstSeen = prev.first_seen;
      } catch {
        // Corrupt/unreadable prior marker. Overwrite fresh below.
      }
    }

    const marker = {
      hook: hookName,
      root_cause_key: rootCauseKey,
      error_type: errorType,
      error_message: errorMessage,
      phase: context.phase ?? null,
      session_id: context.sessionId ?? null,
      first_seen: firstSeen,
      last_seen: now,
      occurrences,
    };

    const tmpMarkerPath = `${markerPath}.tmp`;
    writeFileSync(tmpMarkerPath, JSON.stringify(marker, null, 2));
    renameSync(tmpMarkerPath, markerPath);
  } catch (writeErr) {
    // Marker write is best-effort. This never rethrows (NFR-001, ADR-005),
    // but a bare swallow here means a genuinely-down backend combined with
    // an unwritable plan/ produces zero signal anywhere. Emit exactly one
    // stderr line naming the hook and marker path so there is a trace.
    // The write error's type/message may echo user-configured strings
    // verbatim, same accepted precedent as the gitignored marker files
    // (plan/.telemetry-failures/, .gitignore line 27); no credential value
    // is constructed here. Wrapped in its own try/catch so a broken stderr
    // stream (e.g. EPIPE) still cannot make this function throw.
    try {
      const failureType = writeErr?.constructor?.name ?? writeErr?.name ?? "Error";
      const failureMessage = String(writeErr?.message ?? writeErr ?? "unknown error").replace(/\s+/g, " ");
      const path = markerPath ?? "(marker path unresolved)";
      process.stderr.write(
        `record-telemetry-failure: marker write failed for hook "${hookName}" at ${path}: ${failureType}: ${failureMessage}\n`,
      );
    } catch {
      // stderr itself is unavailable. Nothing more can be done.
    }
  }
}
