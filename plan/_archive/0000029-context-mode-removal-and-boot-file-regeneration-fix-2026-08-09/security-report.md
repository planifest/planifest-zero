---
title: "Security Report - 0000029-context-mode-removal-and-boot-file-regeneration-fix"
summary: "P5 security review of the boot-file regeneration fix, context-mode template removal, and git-permission override update."
status: "active"
version: "0.1.0"
---
# Security Report - 0000029-context-mode-removal-and-boot-file-regeneration-fix

**Skill:** planifest-security-agent
**Feature:** 0000029-context-mode-removal-and-boot-file-regeneration-fix
**Date:** 2026-08-09
**Overall risk:** Low

## Scope Reviewed

- `setup.sh` `write_boot_file` and `setup.ps1` `Write-PlanifestBootFile` (always-overwrite change)
- `templates/standard-boot.md` (context-mode bullet removal)
- `planifest-overrides/instructions/custom-001-local-git-only.md` (expanded standing git authority)
- `tests/test-0000029-req-001-003-boot-file-regeneration.sh` (new test file)
- Full feature diff secrets scan: clean, no credentials, tokens, or keys.

## Findings

### SEC-001 (Low, open): boot-file write follows symlinks

`echo "$content" > "$path"` and `Set-Content` both write through a symlink. Before this feature the skip-if-exists guard meant an existing symlinked `CLAUDE.md` was never written; now it is written every run. An actor able to plant a symlink at the boot-file path inside a repo could redirect the write to any user-writable path. Exploitability is limited: it requires prior write access to the repo (at which point the actor has easier attacks), and the written content is the framework template plus repo overrides, not attacker-supplied free text. Consistent with the framework's existing posture (`gate-write` path checks are prefix-based, not symlink-resolving). Recorded, not fixed here; candidate hardening (refuse to write when the target is a symlink) filed for backlog pickup.

### SEC-002 (Informational, positive): attack surface reduced

Removing the unconditional context-mode instruction closes a supply-chain exposure: trusted boot-file text no longer directs every agent in 6 tools toward a third-party plugin. This finding motivated the feature (see ADR-002); the change is the mitigation.

### SEC-003 (Low, accepted): expanded standing git authority

`custom-001` now grants standing authority for fetch/pull/push/PR-create instead of per-request authorization. Consequence: a prompt-injection-driven agent action could push a branch or open a PR without a fresh human grant. Bounds that keep this Low: commits to `main` and PR merges remain human-only (and should be backed by GitHub branch protection, see recommendation), a pushed branch or opened PR is visible and reversible, and force-push remains outside the granted wording. Accepted explicitly by the human on the loop this session; this report records the trade rather than reopening it.

## Recommendations (non-blocking)

1. Enable GitHub branch protection on `main` (require PR, forbid direct pushes) so the human-only rule in `custom-001` is enforced by the platform, not prose. Verify current settings.
2. Backlog candidate: `write_boot_file`/`Write-PlanifestBootFile` refuse or warn when the target exists and is a symlink (SEC-001 hardening).

## Hard Limits Check

- No credentials appeared in context during this feature (Hard Limit: confirmed).
- No schema or data-ownership surface touched.
