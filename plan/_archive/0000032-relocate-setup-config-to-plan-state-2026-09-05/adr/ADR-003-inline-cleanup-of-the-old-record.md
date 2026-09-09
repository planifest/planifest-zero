---
title: "ADR 003: Setup removes the old record inline"
summary: "After a successful write to plan/state/{tool}.md, setup.sh and setup.ps1 delete planifest-overrides/setup-config/{tool}.md at its exact path and remove setup-config/ if it is then empty. No migration file. Removal failure warns and continues."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Setup removes the old record inline

**Skill:** [adr-agent](../../../.claude/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Component:** planifest-zero
**Date:** 2026-09-05

## Context

Every repo that ran setup before this feature has a `planifest-overrides/setup-config/{tool}.md`. ADR-001 moves the record, so something has to deal with the old file. The framework has a migration mechanism: a pending `.md` in `planifest-zero/migrations/` that the migrator skill walks the human through at the next session start, as `migrate-archive-dirname.sh` did for the archive folder rename.

The old file differs from that case. Its path is exact, the setup script wrote it, and the same setup run regenerates its contents from the command-line flags. There is nothing in it to preserve.

## Decision

1. After `write_setup_config_override` (bash) or `Write-SetupConfigOverride` (PowerShell) succeeds, the script deletes `planifest-overrides/setup-config/{tool}.md` if it exists, and prints one line naming the removed path.
2. If `planifest-overrides/setup-config/` is then empty, the script removes the folder and prints one line. If the folder holds any other file, the folder and that file stay untouched.
3. If the write to `plan/state/` failed, the old file is left alone. Cleanup runs only after the new record exists.
4. If removal fails, the script prints one warning and continues. Setup still exits `0`. A leftover old file is harmless because nothing reads it (ADR-002).
5. When there is nothing to remove, the script prints nothing. Repeat runs are silent.
6. No migration file is written for this change.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A pending migration in `planifest-zero/migrations/` | Follows the archive-rename precedent, human confirms each removal | Asks the human to approve removing a file setup has already replaced on the same machine, and leaves the stale file in place until the next orchestrator session | Ceremony for a file with an exact path and regenerated contents |
| Leave the old file and document it as stale | No deletion in a human-owned folder | Every upgraded repo carries a stale file for ever, and `planifest-overrides/` stays polluted with the thing this feature removes | Defeats ADR-001 |
| Move the old file to the new path instead of regenerating | Preserves the old contents | The contents are regenerated from flags on the same run, and a moved file could carry a stale `writtenAt` or flags that differ from this run's | Nothing in the old file needs preserving |
| Fail setup when removal fails | Loud | Blocks a working setup for a file nothing reads | Warn-and-continue matches the existing write-failure behaviour |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-zero (`setup.sh`, `setup.ps1`) | Gains the removal step after a successful write, with the printed lines and warning |
| planifest-zero (`pipeline-reference.md`) | The claim that re-running setup never touches `planifest-overrides/` is qualified with this one removal |
| planifest-zero (tests) | New cases: old file present, folder with another file, nothing to remove, read-only folder |

## Consequences

**Positive:**
- A consumer's next setup run completes the relocation with no separate step.
- Repeat runs stay silent, so the migrated state is indistinguishable from a fresh install.

**Negative:**
- Setup deletes a file inside `planifest-overrides/`, the one folder it otherwise never modifies. The exact-path rule limits this to the file setup itself wrote.
- A test now depends on printed wording for the removal lines.

**Risks:**
- A human who hand-edited the old file before upgrading loses that edit. The file was rewritten on every run before this change, so the edit was already short-lived.

## Related ADRs

- ADR-001 - depends-on (the new location that makes the old file stale)
- ADR-002 - related-to (nothing reads the old path, so a failed removal is harmless)

## Supersedes

- None

## Superseded By

- None
