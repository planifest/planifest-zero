---
title: "Security Report - five-phase-planifest-zero"
summary: "Security review of the feature diff. Overall risk: low."
status: "active"
version: "0.2.0"
---
# Security Report - 0000031-five-phase-planifest-zero

**Overall risk rating:** low
**Findings:** 0 critical, 0 high, 0 medium, 1 low (fixed in-run)

## Scope

The full feature diff against `main`: the folder rename, skill rewrites, enum change, CI workflow edits, setup-script pruning, the rewritten refresh script, and the docs rewrite. New execution surfaces reviewed line by line: `prune_retired_skills()` in both setup scripts, `refresh-planifest-zero-dir.ps1`, and the CI telemetry loop.

## Findings

### LOW-001: skill pruning follows a planted symlink

`prune_retired_skills()` in `planifest-zero/setup.sh` runs `rm -rf` on each subfolder of `.claude/skills/` whose name is absent from the source set. The glob appends a trailing slash, so a symlink planted at `.claude/skills/{name}` pointing outside the tree would have its target contents deleted on the next setup run. Exploitation requires local write access to `.claude/`, which already implies broader control of the machine. The PowerShell twin has the same shape.

Resolution: fixed in this run. Both scripts now skip symlinks (and junctions on Windows) before deleting. The temp-clone execution test stays green.

## Reviewed and clear

- **Credential handling:** no credential-shaped strings enter the diff. The telemetry URL stays env-var and secret-sourced. The CI job still exits silently when the secret is unset.
- **Command injection:** the CI telemetry loop interpolates `$PHASE` from a fixed literal list, not from input. The Node payload passes the phase via `process.argv`, not string splicing.
- **Path traversal:** the pruning comparison uses `basename` output against a fixed source directory. No user-controlled path segments.
- **Refresh script:** the hardcoded foreign machine path is gone. `$PSScriptRoot` derivation removes the risk of deleting an unrelated directory tree.
- **Deleted surface:** three workflows, thirteen skills, and the CI fast-path branch are removals. The fast-path removal closes the weaker-parity-check hole flagged in review.
- **Hook changes:** the enum rewrite and heading regex change alter no privilege or input handling. All hooks keep their exit-zero, never-block contract.
