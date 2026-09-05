---
title: "ADR 002: Refresh-setup reads the record before the marker"
summary: "planifest-refresh-setup Step 3 reads plan/state/{tool}.md first at high confidence, validates it, and falls back to the gitignored marker then hook inference. This makes the tracked record the source of truth in practice, not only on paper."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Refresh-setup reads the record before the marker

**Skill:** [adr-agent](../../../.claude/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Component:** planifest-zero
**Date:** 2026-09-05

## Context

0000025 ADR 002 declared the tracked record authoritative over the gitignored marker and said the refresh-setup skill would gain a fast path that reads it. The skill never gained that path. Its Step 3 reads the marker, and when the marker is absent it infers flags from hook wiring. The docs in `pipeline-reference.md` and `project-operations.md` claim the skill reads the record. That claim was found false during P0 coaching.

Today the precedence rule holds only because `setup.sh` writes both files from the same command-line flags on every run. Nothing reads the record, so a record nothing reads is not a source of truth.

## Decision

1. Step 3 of `planifest-refresh-setup` reads `plan/state/{tool}.md` first. A valid record yields every flag and the backend URL at high confidence, with source `plan/state/{tool}.md`. The marker is not consulted.
2. A record is valid when its JSON block parses, holds `tool`, `flags`, `backendUrl`, and `writtenAt`, and its `tool` matches the target tool.
3. A record that is absent, unreadable, or invalid is treated as missing. Step 3 falls back to the marker, then to hook inference, exactly as today. The skill run does not stop.
4. Step 4's confirmation names the source used for each flag: the record, the marker, or hook inference.
5. Step 2's interrupted-run detection is unchanged. It keeps reading `attemptStatus` from the marker, because the record never holds attempt state.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Pure path move, correct the docs to say the skill never reads the record | Smallest change | The brief's user story wants a durable source, and the precedence rule stays a fiction | A record nothing reads is not a source of truth |
| Read the record and stop the run when it is malformed | Surfaces corruption loudly | A record truncated by an interrupted setup run would block every refresh until a human edits it, for a file the next setup run rewrites anyway | Fallback is safer, and the marker still holds the last good flags |
| Trust the record without validation | Simplest read | A truncated record read at high confidence could feed the wrong flags into the setup command | Flags are injected into a command, so the input must be validated |
| Merge record and marker when they disagree | Loses nothing | 0000025 ADR 002 already rejected merging: the record is a reviewed commit, so it wins | Consistent with the superseded decision |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-zero (`planifest-refresh-setup` skill) | Step 3 gains the record read and validation rules. Step 4 names the source. |
| planifest-zero (tests) | The refresh-setup suite gains cases for a valid, absent, malformed, and wrong-tool record |

## Consequences

**Positive:**
- A fresh clone refreshes from the committed record with no inference, and the docs' claim becomes true.
- The precedence rule from 0000025 is enforced by a reader, not only by the writer.

**Negative:**
- Step 3 gains a validation branch and three new failure cases to keep tested.
- The skill is markdown executed by an agent, so validation is an instruction rather than code. Enforcement depends on the agent following it.

**Risks:**
- An agent could skip validation and trust a malformed record. The acceptance test for the wrong-tool and invalid-JSON cases is the check.

## Related ADRs

- ADR-001 - depends-on (the record's location and format)
- ADR-003 - related-to (a leftover old record is never read, so cleanup failure is harmless)

## Supersedes

- The unimplemented "fast path" promise in 0000025 ADR 002's Affected Components table. ADR-001 records the supersession of that ADR as a whole.

## Superseded By

- None
