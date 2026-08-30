/**
 * Shared hook helper: path of the phase-start dedup flag file.
 *
 * Extracted per req-002 / 0000028-ADR-002 from the 2 copies in
 * emit-phase-start.mjs and emit-phase-end.mjs. Those copies were textually
 * different (one hoisted the directory into a local, the other nested the
 * join) but constructed the identical path; that path is reproduced here
 * unchanged.
 *
 * emit-phase-start.mjs writes this file with an ISO 8601 start timestamp and
 * uses its existence as the re-emission guard; emit-phase-end.mjs reads it to
 * compute duration_ms.
 *
 * Both prior copies closed over the module-level PHASE constant. The shared
 * version takes `phase` as an explicit second argument, so the two callers
 * pass their own PHASE and the produced path is byte-identical to before.
 *
 * Out of scope, deliberately (req-002): resolve-phase.mjs's endDedupFlag() is
 * a different file (`phase-end-emitted-...`) serving a different purpose (the
 * resolver's own re-exec dedup, not the underlying hook's start flag) and is
 * not merged into this helper.
 *
 * PLACEMENT: hooks/telemetry/. Both callers are telemetry hooks, and setup.sh's
 * Tier 1 telemetry glob was widened to *.mjs (req-002) so Tier 1 installs
 * receive this file alongside them.
 */

import { tmpdir } from "node:os";
import { join } from "node:path";

export function getFlagPath(sessionId, phase) {
  return join(tmpdir(), "planifest-telemetry", `phase-start-${sessionId}-${phase}`);
}
