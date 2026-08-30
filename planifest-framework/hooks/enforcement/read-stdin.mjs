/**
 * Shared hook helper: read the JSON payload a hook receives on stdin.
 *
 * Extracted per req-002 / 0000028-ADR-002 from the 12 copies that previously
 * lived one-per-hook across hooks/enforcement/ and hooks/telemetry/.
 *
 * PLACEMENT (0000028-ADR-002): this module lives in hooks/enforcement/, not
 * hooks/telemetry/, because hooks/enforcement/ is the always-installed
 * superset. check-telemetry-receipts.mjs and check-telemetry-failures.mjs are
 * enforcement hooks installed unconditionally (setup.sh install_enforcement_
 * hooks(), and setup.sh's Tier 1 enforcement copy), whereas hooks/telemetry/
 * is installed only under --structured-telemetry-mcp. A telemetry-side
 * placement would leave those two enforcement hooks importing an absent file
 * on every install without telemetry, which fails at ESM module-load time,
 * before the hook's own top-level try/catch can run, and so breaks the
 * exit-zero-on-every-path invariant instead of degrading gracefully.
 * Telemetry hooks import this module across the sibling directory boundary
 * (../enforcement/read-stdin.mjs), which is always safe in the other
 * direction.
 *
 * DELIBERATE BEHAVIOUR CHANGE (req-002 acceptance criteria): this shared copy
 * always wires process.stdin.on("error", reject). Before extraction only
 * hooks/telemetry/context-pressure.mjs did so; the other 11 copies wired
 * "data" and "end" but no "error" handler, so a stdin stream error left the
 * returned promise unsettled forever and the hook hung rather than exiting 0.
 * That hang violates NFR-001 (a hook must never block the session). Every
 * caller awaits readStdin() inside a top-level try/catch (or, for
 * ratchet-check.mjs, main().catch(...)) that exits 0, so rejecting here
 * converts an indefinite hang into the caller's existing fail-open path. The
 * discrepancy is resolved in the safe direction on purpose, not collapsed by
 * accident.
 *
 * The BOM strip is unchanged. The prior copies expressed it as either
 * /^﻿/ or a literal U+FEFF inside the regex literal; those are the same
 * regular expression, so no caller's parsing behaviour changes.
 */

export function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf-8");
    process.stdin.on("data", (chunk) => { data += chunk; });
    process.stdin.on("end", () => resolve(data.replace(/^﻿/, "")));
    process.stdin.on("error", reject);
    process.stdin.resume();
  });
}
