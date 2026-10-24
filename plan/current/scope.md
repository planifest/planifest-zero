---
title: "Scope - hardening-and-backlog-skill"
summary: "Boundaries for the gate-write fix, the Bash 3.2 test loops, the telemetry cleanup retirement, and the backlog-filing skill."
status: "draft"
version: "0.1.0"
---
# Scope - hardening-and-backlog-skill

**Skill:** plan
**Feature:** 0000164-hardening-and-backlog-skill
**Version:** 1.1.0

## In Scope

- `gate-write` exits 0 for a target whose real path is outside the project root. Tests cover it with and without `design.md`, and through a symlink.
- `gate-write` names `plan/backlog/` and `plan/roadmap/` as allowed. `CLAUDE.md` and the hook comment state what the hook gates.
- The five suites switch from `done < <(...)` to `done <<< "$(...)"` and skip empty lines. A guard test fails on the old pattern under `tests/`.
- `setup.sh` and `setup.ps1` drop the telemetry cleanup and its call. The names stay as `RETIRED_HOOK_NAMES` and `$RetiredHookNames`. Cleanup tests go, pruning tests stay.
- New skill `ravintio-zero/skills/ravintio-file-backlog/SKILL.md`, a catalogue row, and tests.
- Version 1.1.0.

## Out of Scope

- Narrowing the `plan/` or `docs/` allowed set.
- Backlog entries 0000100, 0000110, and 0000159.

## Deferred

Nothing deferred.
