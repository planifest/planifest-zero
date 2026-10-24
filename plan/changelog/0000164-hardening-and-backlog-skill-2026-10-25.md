# Changelog (0000164-hardening-and-backlog-skill, 25 Oct 2026)

**Feature:** hardening-and-backlog-skill
**Version:** 1.1.0
**PR:** pending

## What changed

`gate-write` now gates this project only, setup no longer carries telemetry cleanup, and a new skill files backlog entries in other repos. The release adds no dependency.

- req-001: `gate-write.mjs` passes a target whose real path lies outside the project's real root. Agent memory writes and writes to another repo no longer need a design.
- req-002: the hook header names `plan/backlog/` and `plan/roadmap/` as paths that pass between runs.
- req-003: the Bash test loops no longer use process substitution, which Bash 3.2 on macOS can truncate.
- req-004: setup drops the legacy telemetry cleanup in `setup.sh` and `setup.ps1`. The retired-hooks list stays as `RETIRED_HOOK_NAMES` and `$RetiredHookNames`. Hook install now drops each `settings.json` entry that runs a retired hook.
- req-005: the new skill `ravintio-file-backlog` writes one uncommitted `plan/backlog/{id}-{slug}/entry.md` in another repo. It takes the next id across `plan/backlog/`, `plan/_archive/`, and `plan/changelog/`.
- req-006: tests cover symlink cases for `gate-write`, including a link that points outside and a link that points inside.
- req-007: `CLAUDE.md`, `standard-boot.md`, `pipeline-reference.md`, and `project-operations.md` describe the real gate. A test checks the wording.
- req-008: a guard test fails on any process-substitution loop in the suites.
- req-009: the telemetry cleanup suites and their manifest entries are gone.
- req-010: the skill catalogue lists `ravintio-file-backlog`, and counts say 13 skills.

## Upgrade note

Setup no longer removes legacy telemetry wiring. A consumer that last ran a setup from before 0000033 must remove these items by hand:

- the `mcp__structured-telemetry-mcp__emit_event` matcher entries in `.claude/settings.json`
- `.claude/telemetry-enabled`
- `plan/.telemetry-failures`
- `plan/.telemetry-receipts`

Until then, the tool tries to run a missing module on every prompt in that consumer. Setup still prunes retired hook files and the `settings.json` entries that run them.

## Why

Hooks blocked legitimate writes outside the project, and the docs described the gate as narrower than it is. The telemetry cleanup ran on every setup for a case with no known live consumer. Agents also had no defined way to file a backlog entry in another repo.

Decisions:

- ADR-001: the stack stays as declared and no dependency is added.
- ADR-002: `gate-write` scopes to the project by real path. A symlink inside the project that points outside counts as outside.
- ADR-003: setup retires the telemetry cleanup and keeps the retired-hooks list. It supersedes 0000033 ADR-002.
- ADR-004: the file-backlog skill never touches the target repo's git state.

## Deviations

- Track C found that only the telemetry cleanup removed a retired hook's `settings.json` entry. Hook install now drops those entries for any retired hook. ADR-003 records it.
- The living docs gained one correction: the architecture overview no longer lists the telemetry cleanup, and says gate-write passes outside targets.

## Validation results

Pending P3.

Backlog 0000165 was filed during the run. Backlog 0000100, 0000110, and 0000159 stay open.

## Skipped phases

None
