/**
 * Shared hook helper: resolve the declared product_id for a telemetry envelope.
 *
 * Extracted per req-002 / 0000028-ADR-002 from the 3 byte-identical copies in
 * context-pressure.mjs, emit-phase-start.mjs and emit-phase-end.mjs. Logic is
 * unchanged from those copies.
 *
 * PLACEMENT: hooks/telemetry/. All callers are telemetry hooks, so this module
 * only needs to exist wherever hooks/telemetry/ exists. setup.sh's Tier 1
 * telemetry glob was widened from emit-phase-*.mjs to *.mjs (req-002) so that
 * Installs receive this file alongside the two
 * emit-phase hooks that import it.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";

/**
 * Declared product_id source (0000024 req-001): product.yml's top-level `id`
 * field, resolved relative to the hook's own `cwd`. No git-derived or
 * path-shaped fallback. An absent, unparseable or `id`-less product.yml is a
 * hard failure that propagates to the caller's top-level try/catch and is
 * routed through recordTelemetryFailure(), never a silent path-shaped
 * fallback.
 */
export function readProductId(cwd) {
  const text = readFileSync(join(cwd, "product.yml"), "utf-8");
  for (const raw of text.split(/\r?\n/)) {
    const noComment = raw.replace(/#.*$/, "");
    const m = noComment.match(/^id:\s*(.*)$/);
    if (!m) continue;
    let value = m[1].trim();
    if (/^"[^"]*"$/.test(value) || /^'[^']*'$/.test(value)) {
      value = value.slice(1, -1).trim();
    } else if (/["']/.test(value)) {
      throw new Error("product.yml id field is malformed (unbalanced quoting)");
    }
    if (!value || /^(null|~)$/i.test(value)) {
      throw new Error("product.yml id field is empty");
    }
    return value;
  }
  throw new Error("product.yml has no top-level id field");
}
