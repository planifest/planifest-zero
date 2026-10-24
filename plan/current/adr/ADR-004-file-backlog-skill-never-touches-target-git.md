---
title: "ADR 004: The file-backlog skill never touches the target repo's git state"
summary: "The skill writes one uncommitted entry folder in the target repo. It never commits, pushes, switches branches, stashes, or opens a pull request there."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - The file-backlog skill never touches the target repo's git state

**Skill:** [plan](../skills/ravintio-plan/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Component:** ravintio-zero
**Date:** 2026-10-24

## Context

A human sometimes asks the agent to file a backlog entry in another repo. No skill defines how. The target repo may have work in progress on a branch, a dirty tree, or a stash. Any git action there can interfere with that work.

Ids must not collide. A repo allocates ids across `plan/backlog/`, `plan/_archive/`, and `plan/changelog/`, so a scan of the backlog alone can reuse an id that an archived feature already took.

## Decision

The new skill `ravintio-file-backlog` writes one uncommitted folder, `plan/backlog/{id}-{slug}/entry.md`, in the target repo. It reports the path written.

- The skill never commits, pushes, switches branches, stashes, or opens a pull request in the target repo.
- The next id is the highest ever allocated plus one. The skill scans `plan/backlog/`, `plan/_archive/`, and `plan/changelog/` for leading zero-padded numbers.
- The id width comes from the target repo's existing ids.
- The skill never overwrites an existing folder. If the chosen id is taken, it takes the next free id.
- If a folder with the same slug exists, the skill reports it and writes nothing. A rerun is safe.
- The skill uses the target's backlog template. If the target has none, it uses this pack's template.
- The skill relies on REQ-001 so that the write passes `gate-write`. It adds no hook change.

The human stages and commits the entry when they choose. This rule binds later changes to the skill.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Chore branch and pull request in the target | The entry lands through review | Switches branches and interferes with that repo's work | The human rejected it |
| Commit to the target's current branch | Entry is saved in history | Mixes an unrelated commit into that repo's work | The skill must not touch git state |
| Take the id from `plan/backlog/` alone | Fewer directories to scan | Reuses ids that archived features took | Ids must stay unique for ever |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-zero | New skill folder, a catalogue row, two skill-count suites move from 12 to 13, and a structure suite is added |

## Consequences

**Positive:**
- The target repo's branch, index, and stash stay as the human left them.
- A rerun with the same slug writes nothing, so a retry cannot duplicate an entry.

**Negative:**
- The entry stays uncommitted until the human commits it, so a clean-tree check in the target repo fails afterwards.
- The scan misses an id that a sibling branch allocated and has not yet merged.

**Risks:**
- A sibling session takes the same id at the same moment. The skill refuses to overwrite and takes the next free id.

## Related ADRs

- ADR-002 - depends-on (outside targets pass `gate-write`)

## Supersedes

- None

## Superseded By

- None
