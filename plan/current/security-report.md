---
title: "Security Report - relocate-setup-config-to-plan-state"
summary: "P5 security review of the plan/state record relocation, the inline legacy cleanup, and the refresh-setup read path."
status: "draft"
version: "0.1.0"
---
# Security Report - 0000032-relocate-setup-config-to-plan-state

**Skill:** [security-agent](../../.claude/skills/planifest-security-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Component:** planifest-zero
**Date:** 2026-09-09

> Advisory only. No code changes are made. Findings reference the branch diff against `main`.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| A malicious commit puts shell metacharacters or extra arguments in the `flags` array or `backendUrl` of `plan/state/{tool}.md`. The refresh-setup skill copies them into the `setup.sh {tool} {flags...}` command it proposes, and an inattentive human approves it. | Tampering, Elevation | Medium | Partly mitigated. `planifest-zero/skills/planifest-refresh-setup/SKILL.md` Step 4 (lines 56-62) requires an explicit affirmative and shows the exact command. `setup.sh` lines 1083-1102 and `setup.ps1` lines 22-41 reject unknown flags and non-URL backend values. Shell metacharacters run before either script sees them. Step 3 sub-step 1 (SKILL.md lines 38-43) validates structure only, not the flag set or the URL shape. Filed as backlog 0000087. |
| A crafted tool argument steers the `plan/state/{tool}.md` write or the `planifest-overrides/setup-config/{tool}.md` delete to another path (CWE-22). | Tampering | Low | Mitigated. `setup.sh` line 1154 checks the tool before `run_tool_setup`, and `setup_tool` (lines 841-848) exits 1 when `setup/{tool}.sh` is absent, before either path function runs. `setup.ps1` line 1130 uses `-contains`, an exact match. See S-002 for the weak `grep -w` check. |
| Setup deletes more than the one legacy file inside `planifest-overrides/`, a human-owned folder. | Tampering | Low | Mitigated. `remove_legacy_setup_config` (`setup.sh` lines 1013-1036) runs `rm -f` on one quoted exact path and `rmdir` only after an `ls -A` empty check. `rmdir` refuses a non-empty directory on its own. `Remove-LegacySetupConfig` (`setup.ps1` lines 1058-1085) mirrors this with `Remove-Item` on the file and a `Count -eq 0` check before removing the folder without `-Recurse`. No `rm -rf` was added on this branch. |
| The tracked record publishes something the repo should not commit. | Information Disclosure | Low | Mitigated. The record holds the tool name, flag names, a backend URL, and a timestamp (`setup.sh` lines 989-994). The URL regex on `setup.sh` line 1097 admits no userinfo, query, or fragment, so no credential can enter it. The same fields were already tracked at the old path. |
| The legacy file is removed before the new record exists, leaving no tracked record. | Repudiation | Low | Mitigated. `setup.sh` lines 1146-1148 and `setup.ps1` lines 972-974 call the removal only when the write returns success. |
| A truncated or malformed record read at high confidence feeds wrong flags into the setup command. | Tampering | Low | Mitigated. SKILL.md lines 38-43 treat a record that fails to parse, lacks a field, or names another tool as missing and fall back to the marker. Enforcement is an instruction to an agent, not code (ADR-002 Consequences). |
| Setup fails or blocks when `plan/state/` cannot be created or written. | Denial of Service | Low | Mitigated. `setup.sh` lines 975-978 and 997-1000 warn and return 1, and `setup.ps1` lines 1019-1023 warn and return `$false`. Setup continues with marker-only behaviour. |

## Findings

| ID | Severity | Category | Location | Description | Recommendation | Status |
|----|----------|----------|----------|-------------|----------------|--------|
| S-001 | medium | injection | `planifest-zero/skills/planifest-refresh-setup/SKILL.md` lines 38-43 | Step 3 validates the record's JSON shape, the four field names, and the `tool` value. It does not constrain `flags` to the two flags `setup.sh` accepts, nor `backendUrl` to the http(s) shape `setup.sh` line 1097 enforces. The record is git-tracked, so a hostile or careless commit can place arbitrary strings in the command the agent builds in sub-step 4 and later runs in Step 7. Human confirmation in Step 4 is the only barrier before the shell parses those strings. ADR-002's own rationale says "Flags are injected into a command, so the input must be validated". | Add two validation rules to Step 3 sub-step 1: each `flags` entry must be one of `--structured-telemetry-mcp` or `--strict-orchestrator`, and `backendUrl` must be `null` or match `^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._/-]*)?$`. Treat any other value as invalid and fall back. Tracked in backlog 0000087. | open |
| S-002 | informational | config | `planifest-zero/setup.sh` line 1154 | `echo "$VALID_TOOLS" \| grep -qw "$TOOL"` treats the argument as a regex with word boundaries. `claude`, `code`, `.*`, and `c.aude-code` all pass. This predates the branch. It is not exploitable today: `setup_tool` at lines 841-848 requires `setup/{tool}.sh` to exist and exits under `set -e` before `write_setup_config_override` or `remove_legacy_setup_config` run, and both functions quote `$tool` so no glob expands. | Replace the `grep -w` check with an exact comparison loop over `$VALID_TOOLS`, matching `setup.ps1` line 1130. Not filed, since the guard in `setup_tool` closes the path. | open |
| S-003 | informational | data-exposure | `plan/state/{tool}.md` | The record is committed. A consumer that sets `--backend-url` to an internal hostname publishes that hostname to everyone with repo access. The value was already tracked at the old path, and the URL regex excludes credentials. | Note in `project-operations.md` that `backendUrl` is committed and should not name a host the repo's readers may not see. Optional. | accepted |

## Dependency Audit

No dependencies were added or changed. The diff touches two shell scripts, one markdown skill, tests, and docs, and pulls in no packages.

## Secrets Management

No secrets are handled. `write_setup_config_override` (`setup.sh` lines 954-1003) writes the tool name, the flag names, `backendUrl` or `null`, and a UTC timestamp. `Write-SetupConfigOverride` (`setup.ps1` lines 989-1025) writes the same four fields. The default `backendUrl` is `http://localhost:3741`, and the parse-time regex on `setup.sh` line 1097 and `setup.ps1` line 37 rejects any URL with userinfo. No credential appeared in any file read for this review.

## Authentication & Authorisation Review

Not applicable. There is no API. Both scripts run with the invoking user's filesystem rights and add no privilege boundary.

## Input Validation Review

- `setup.sh` tool argument: checked at line 1154 with `grep -qw` (see S-002) and again by the `setup/{tool}.sh` existence test at lines 841-848. `setup.ps1` checks at line 1130 with an exact `-contains`. Both path functions build paths from the validated value only and quote it.
- `setup.sh` flags: the `case` at lines 1083-1102 rejects unknown flags and validates `--backend-url` against a strict regex. `setup.ps1` lines 22-41 do the same.
- Legacy removal: `remove_legacy_setup_config` takes only the validated tool name, tests `-e` on the exact file, uses `rm -f` without `-r`, checks the folder is empty with `ls -A`, and uses `rmdir`. `Remove-LegacySetupConfig` mirrors each step.
- Refresh-setup record: SKILL.md lines 38-43 require a fenced JSON block that parses, all four fields, and a matching `tool`. Missing: an allowlist on `flags` and a shape check on `backendUrl` (S-001). req-004's Input Validation section asks only for parse-or-reject, so the implementation matches the spec, and the spec is where the gap sits.
- Step 4 (SKILL.md lines 56-62) waits for an explicit affirmative and halts on rejection. Step 7 runs only the confirmed command.

## Network Policy

Not applicable. No ports are opened and no network call is made by the changed code. `backendUrl` is written to a file and later passed as a flag to `setup.sh`, which records it in hook config for a separate telemetry feature.

## Infrastructure as Code Review

Not applicable. The repo contains no Terraform, Pulumi, CDK, or CloudFormation files.

## Risk Register Cross-Reference

| ID | Register status | Review outcome |
|----|----------------|----------------|
| R-001 | accepted | Unchanged. Local edits to the old file are lost on upgrade as described. |
| R-002 | accepted | Unchanged. `planifest-framework/setup.sh` still writes the old path until refreshed. `planifest-overrides/setup-config/claude-code.md` is present in this repo today. |
| R-003 | open | Mitigated on this branch. `test-0000025-req-004-setup-config-relocation.sh` now asserts `plan/state/{tool}.md` (lines 6, 45, 70). The register should move this to mitigated. |
| R-004 | open | Unchanged. Printed-line assertions remain in the test suites. |
| R-005 | accepted | Unchanged. `setup.ps1` changes still have no automated runner. This review read `Remove-LegacySetupConfig` and `Write-SetupConfigOverride` by hand and found them equivalent to the bash versions. |
| R-006 | accepted | Unchanged and confirmed at `setup.sh` lines 975-978. |
| A-001 | open | Confirmed. `mkdir -p` at `setup.sh` line 975 and `New-Item -Force` at `setup.ps1` line 1017 create `plan/state/`. |
| A-002 | open | Unchanged. |
| A-003 | open | Unchanged. |

No register entry was edited. The suggested status change for R-003 is left for the owning agent.

## Summary

Overall risk rating: Medium

The rating is driven by S-001 alone. The code paths for writing and deleting are narrow, quoted, and guarded. The refresh-setup skill reads a git-tracked file and builds a shell command from it with structural validation only. Human confirmation is the sole control between a hostile commit and command execution.

Top actions before production:
1. Add the flag allowlist and `backendUrl` shape check to refresh-setup Step 3 (S-001, backlog 0000087).
2. Replace the `grep -w` tool check in `setup.sh` line 1154 with an exact match (S-002).
3. Move R-003 to mitigated in `plan/current/risk-register.md`.
