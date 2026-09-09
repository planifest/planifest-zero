# Test Report (0000032-relocate-setup-config-to-plan-state, 2026-09-05)

**Feature:** Relocate the setup-config record to plan/state/
**Plan date:** 2026-09-05

## 1. Tests Run This Plan (P4 Results)

Every functional requirement appears here.

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000032-req-001-bash-write-to-plan-state.sh` | req-001 | pass (26 cases) |
| `test-0000032-req-002-powershell-write-to-plan-state.sh` | req-002 | pass (6 cases, static) |
| `test-0000032-req-003-inline-cleanup-of-old-record.sh` | req-003 | pass (19 cases) |
| `test-0000032-req-004-refresh-setup-reads-record-first.sh` | req-004 | pass (22 cases) |
| `test-0000032-req-005-layout-docs-updated.sh` | req-005 | pass (5 cases) |
| `test-0000025-req-004-setup-config-relocation.sh` | req-001, req-003 (rewritten for the new path) | pass (23 cases) |
| `docs/decisions-index.md` rows plus `plan/current/adr/` files | req-006 | pass (verified by inspection, no executable assertion) |

**Summary:** 101 assertions across six suites, all passing. req-006 is a documentation requirement
verified by inspection.

Full runner: 55 feature suites passed, 2 failed. Regression pack: 17 passed, 0 failed.

The two failing suites are `test-0000031-req-001-rename.sh` and
`test-0000031-req-005-telemetry-only-mcp.sh`. Both fail on `main` as well, verified against a
`git archive` export of `main`. They assert that no `planifest-framework/` folder exists, which
PR #4 reversed on purpose for this repository. Backlog 0000086 records the decision needed.
The human reviewed these failures at the P4 gate and authorised the pipeline to continue.

req-002 is covered by static assertions against `setup.ps1` source. No PowerShell suite runs
through `run-tests.sh`, so no `pwsh` process executes in CI. Backlog 0000084 covers that gap.
`planifest-zero/tests/README.md` documents the manual `pwsh` procedure.

## 2. Regression Pack State

**Total promoted tests:** 17 suites under `planifest-zero/tests/regression/`
**Passed:** 17
**Failed:** 0

The pack ran clean throughout this feature. No regression failure required triage.

`regression-manifest.json` registers 4 entries while the runner discovers 17 suites by glob.
Nothing reconciles the two. Backlog 0000084 covers that mismatch.

## 3. Newly Promoted Tests (This Feature)

None. No test file produced during P3 or P4 carried a `# REGRESSION-CANDIDATE:` tag, so P7's
regression confirmation had nothing to present. The five new suites stay in the per-feature set.
