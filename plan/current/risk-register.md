---
title: "Risk Register - remove-telemetry-mcp"
summary: "Technical, operational, and security risks with their mitigations."
status: "draft"
version: "0.4.0"
---
# Risk Register - remove-telemetry-mcp

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000033-remove-telemetry-mcp
**Version:** 0.4.0
**Overall Risk Level:** medium

> Every entry must be specific to this feature. Do not produce generic risks.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | `install_enforcement_hooks` in `setup.sh` and `Merge-EnforcementHookSettings` in `setup.ps1` interleave two telemetry entries with six surviving hooks in one array build and one de-duplication filter. A careless block delete drops a surviving hook. | medium | high | Edit the interleaved block line by line against the six-hook list, then run the full enforcement suite after each edit, not only at the end. |
| R-002 | operational | Nineteen mixed test suites assert on telemetry among other things. Editing them wrongly can mask a real regression instead of surfacing it. | medium | medium | Remove only the telemetry-specific assertions, run each edited suite before and after the edit, and diff the assertion count to confirm no non-telemetry assertion was dropped. |
| R-003 | operational | `tests/regression/regression-manifest.json` carries a "do not edit manually" notice, and this feature must remove five entries from it by hand. | high | low | Treat the five-entry removal as a deliberate, documented exception to the notice. Validate the file against `regression-manifest.schema.json` after editing. |
| R-004 | technical | The orchestrator's build-log Hard Limit governs both the phase block and the telemetry field in one rule. Removing the wrong half weakens a rule that must survive. | low | high | Edit only the telemetry clause, then re-read the Hard Limit afterward to confirm the phase-block requirement still reads as mandatory. |
| R-005 | operational | Two suites already fail on `main` because `planifest-framework/` exists (backlog 0000086). They will still fail after this feature and must not be mistaken for a regression this feature caused. | high | low | Record the two suite names as known-failing before starting, and confirm after the feature that no additional suite joins them. |
| R-006 | technical | `phase-enum.mjs` is deleted (req-001), but `pipeline-reference.md` and `tests/test-0000031-req-003-five-phases.sh` both treat it as the canonical five-phase source. The test also asserts on `telemetry-standards.md`, which is also deleted, alongside unrelated checks (skill-folder count, CI phase names, a skill line-count NFR) that must keep passing. | medium | medium | Rewrite the test to assert the five phase names directly, matching `pipeline-reference.md`'s new prose statement, and keep every unrelated assertion in that file intact. |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | No consumer depends on Zero's telemetry. | That consumer loses event emission with no migration path and must wire their own tool-level hooks. | open |
| A-002 | Removing a documented setup flag is a minor version bump, not a major one, because the product is pre-1.0. | The version understates the change for anyone reading tags alone. | open |
| A-003 | Every telemetry entry a prior setup run wrote into `.claude/settings.json` is identifiable by its command string. | Cleanup misses an entry and the broken reference survives. | open |
</content>
