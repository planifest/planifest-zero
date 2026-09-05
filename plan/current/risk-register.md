---
title: "Risk Register - relocate-setup-config-to-plan-state"
summary: "Technical, operational, and security risks with their mitigations."
status: "draft"
version: "0.3.0"
---
# Risk Register - relocate-setup-config-to-plan-state

**Skill:** [spec-agent](../../planifest-framework/skills/spec-agent-SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Version:** 0.3.0
**Overall Risk Level:** low

> Every entry must be specific to this feature. Do not produce generic risks.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | operational | A consumer repo with a locally modified `planifest-overrides/setup-config/{tool}.md` loses that edit on the first upgrade run, because setup deletes the old file after writing the new record. | low | low | The file is rewritten on every run anyway, so a local edit already had no lasting effect before this change. | accepted |
| R-002 | technical | The dev-time `planifest-framework/` copy in this repo keeps writing to the old path until it is refreshed from `planifest-zero/`, so this repo's own record stays at the old path for now. | certain | low | Documented in `discovery.md` and in the layout docs update. Resolves on the next framework refresh. | accepted |
| R-003 | technical | `test-0000025-req-004-setup-config-relocation.sh` asserts the old `planifest-overrides/setup-config/{tool}.md` path and fails until it is rewritten for the new path. | high | low | REQ-006 rewrites the suite for `plan/state/{tool}.md` as part of this feature, alongside new coverage for inline cleanup and refresh-setup read order. | open |
| R-004 | technical | The relocation test asserts on exact printed lines (one per removal, one per write), which could couple the test suite to specific wording and make future output changes break tests unrelated to behaviour. | medium | low | Keep printed-line assertions narrow and centralised in one test file so a wording change touches one place. | open |
| R-005 | operational | `setup.ps1` changes have no automated runner coverage: `run-tests.sh` runs only bash suites, so PowerShell parity for `Write-SetupConfigOverride` is verified manually. | medium | medium | Tracked as backlog 0000084 (PowerShell test coverage). Manual verification required before merge for this feature's PowerShell changes. | accepted |
| R-006 | operational | A consumer repo whose `plan/` folder is gitignored, absent, or unwritable causes the new write to warn and fall back to marker-only behaviour, same as today's `planifest-overrides/setup-config/` failure path. | low | low | Existing warn-and-continue behaviour in `write_setup_config_override` covers this; no new failure mode introduced. | accepted |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | The write path may need to create `plan/state/` itself. | First-run setup on a new repo warns and leaves no record until the folder exists. | open |
| A-002 | The old file's contents never need preserving, because the same run regenerates the record from its flags. | A flag set recorded only in the old file is lost on upgrade. Not possible today, since flags come from the command line on every run. | open |
| A-003 | `plan/` exists in every consumer repo before setup runs, because setup already writes `plan/.orchestrator-strict` there. | The write warns and continues, the same as an unwritable folder. | open |
