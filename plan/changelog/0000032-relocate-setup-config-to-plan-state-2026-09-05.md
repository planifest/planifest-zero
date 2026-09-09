# Changelog (0000032-relocate-setup-config-to-plan-state, 05 Sep 2026)

**Feature:** Relocate the setup-config record to plan/state/
**Pipeline run:** P0 to P9 completed. No phases skipped.
**PR:** https://github.com/planifest/planifest-zero/pull/5

## What Was Built

`setup.sh` and `setup.ps1` wrote the tracked record of active setup flags and backend URL to
`planifest-overrides/setup-config/{tool}.md`. That folder otherwise holds only human-authored,
review-controlled configuration. The record is machine-derived and rewritten on every run, so a
reader could not tell reviewed configuration from generated state.

The record now lives at `plan/state/{tool}.md`, beside the other machine-written pipeline state.
It stays git-tracked and reviewable in diffs, which is the property that motivated tracking it in
the first place. Four changes deliver this:

- Both setup scripts write `plan/state/{tool}.md` and create the folder when it is absent.
- After a successful write, both scripts remove the legacy record at its exact path, and remove
  `setup-config/` when that leaves it empty. Each removal prints one line. A failed removal warns
  and continues. Repeat runs stay silent.
- The `planifest-refresh-setup` skill now reads the record first, at high confidence, ahead of the
  gitignored marker and hook inference. It never read the record before, despite two docs claiming
  it did. The skill validates both the shape and the values before use.
- The layout docs describe `plan/state/` and no longer describe `planifest-overrides/setup-config/`.

## Artifacts Produced

- `discovery.md`, `design.md`, `build-log.md`, `feature-brief.md`
- `execution-plan.md`, `scope.md`, `risk-register.md`, `domain-glossary.md`
- `requirements/req-001` to `req-006` (six files)
- `adr/ADR-001` to `ADR-003` (three files)
- `security-report.md`, `recommendations.md`, `iteration-log.md`

## Decisions

- **ADR-001:** The tracked record lives at `plan/state/{tool}.md`. `planifest-overrides/` returns
  to holding only human-authored configuration. Supersedes 0000025 ADR 002.
- **ADR-002:** `planifest-refresh-setup` reads the record before the marker, validating its shape
  and its values, and falls back to the marker then hook inference on any failure.
- **ADR-003:** Setup removes the legacy record inline after a successful write, rather than through
  a pending migration file.

## Security

One medium finding was raised and fixed inside P5. The refresh-setup skill validated the record's
shape but not its values, so a hostile commit could have placed shell metacharacters in the command
the skill builds. Step 3 now constrains flags to an allowed set and `backendUrl` to the URL pattern
`setup.sh` enforces. Overall risk is Low with no open findings.

## Skipped Phases

None.
