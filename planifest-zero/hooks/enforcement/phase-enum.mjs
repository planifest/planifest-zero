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
 * planifest-zero/standards/telemetry-standards.md's `phase` enum.
 */

/**
 * The canonical phase enum, in pipeline order, per telemetry-standards.md.
 */
export const PHASE_ENUM = [
  "discovery",
  "plan",
  "implement",
  "validate-and-accept",
  "ship",
];

/**
 * Membership set for validating an agent-supplied `phase` string before it
 * reaches path construction (emit-event-receipt.mjs, CWE-22 guard).
 */
export const KNOWN_PHASES = new Set(PHASE_ENUM);

/**
 * Pipeline number to phase enum. Phases number 1..5 in pipeline order.
 */
export const PHASE_NUMBER_TO_ENUM = Object.freeze(
  PHASE_ENUM.reduce((acc, phase, index) => {
    acc[index + 1] = phase;
    return acc;
  }, {}),
);

/**
 * Phase skill name to phase enum. Discovery belongs to the orchestrator, so
 * loading the orchestrator marks the discovery phase. The four downstream
 * phase skills are named `planifest-<phase>`. Non-phase skills
 * (planifest-test-writer, planifest-implementer, planifest-refactor, any
 * non-Planifest skill) are absent, so a lookup returns undefined and the
 * caller treats it as "not a phase transition".
 */
export const PHASE_SKILLS = Object.freeze({
  "planifest-orchestrator": "discovery",
  ...Object.fromEntries(
    PHASE_ENUM.slice(1).map((phase) => [`planifest-${phase}`, phase]),
  ),
});
