/**
 * Shared hook helper: the canonical Planifest phase enum.
 *
 * Extracted per req-002 / 0000028-ADR-002 (folding backlog 0000057). Three
 * hooks previously encoded the same seven phase values independently, keyed
 * three different ways, so a phase could be added to one without the others:
 *
 *   - check-telemetry-receipts.mjs  PHASE_NUMBER_TO_ENUM  (pipeline number)
 *   - resolve-phase.mjs             PHASE_SKILLS          (phase-agent skill)
 *   - emit-event-receipt.mjs        KNOWN_PHASES          (validation set)
 *
 * All three are now derived from PHASE_ENUM below, so adding a phase in one
 * key space cannot leave the others stale.
 *
 * PLACEMENT (0000028-ADR-002): hooks/enforcement/ is the always-installed
 * superset; hooks/telemetry/ installs only under --structured-telemetry-mcp.
 * check-telemetry-receipts.mjs is an enforcement hook installed on every
 * install, so this module must live beside it. Placing it under
 * hooks/telemetry/ would leave check-telemetry-receipts.mjs importing an
 * absent file on the majority case (no --structured-telemetry-mcp), which
 * fails at ESM module-load time before the hook's own try/catch runs. The
 * telemetry-side consumers import it across the sibling boundary
 * (../enforcement/phase-enum.mjs), which is safe because hooks/telemetry/ is
 * never present without hooks/enforcement/.
 *
 * Source of truth for the values themselves is
 * planifest-framework/standards/telemetry-standards.md's `phase` enum.
 */

/**
 * The canonical phase enum, in pipeline order. P0 (Assess and Coach) has no
 * enum value of its own and is deliberately absent, per telemetry-standards.md.
 */
export const PHASE_ENUM = [
  "spec",
  "adr",
  "codegen",
  "validate",
  "security",
  "docs",
  "ship",
];

/**
 * Membership set for validating an agent-supplied `phase` string before it
 * reaches path construction (emit-event-receipt.mjs, CWE-22 guard).
 */
export const KNOWN_PHASES = new Set(PHASE_ENUM);

/**
 * Pipeline number to phase enum. P1..P7 map positionally; P8 and P9 both map
 * to "ship" because the ship-agent owns all three of P7/P8/P9. P0 is absent
 * on purpose, so a lookup for it is undefined and the caller skips it.
 */
export const PHASE_NUMBER_TO_ENUM = Object.freeze(
  PHASE_ENUM.reduce(
    (acc, phase, index) => {
      acc[index + 1] = phase;
      return acc;
    },
    { 8: "ship", 9: "ship" },
  ),
);

/**
 * Phase-agent skill name to phase enum. Every phase agent is named
 * `planifest-<phase>-agent`, so the table derives from PHASE_ENUM directly.
 * Non-phase skills (planifest-test-writer, planifest-implementer,
 * planifest-refactor, any non-Planifest skill) are absent, so a lookup
 * returns undefined and the caller treats it as "not a phase transition".
 */
export const PHASE_SKILLS = Object.freeze(
  Object.fromEntries(PHASE_ENUM.map((phase) => [`planifest-${phase}-agent`, phase])),
);
