# Build Report - 0000031-five-phase-planifest-zero

**Source:** build-log.md in this archive.
**Route:** Feature Pipeline, continuous run.

## Shape of the build

27 subagents across three parallel batches. Discovery used four Haiku drafters for the Scope Lock batch. P1 and P2 used ten Sonnet drafters for requirement files and ADRs. P3 used thirteen Fable 5 agents for the skill rewrites, standards, templates, setup scripts, docs, and the consolidation map. Everything else ran inline in the orchestrating context.

## What worked

- The consolidation map paid for itself. It flagged six rules at risk before any rewrite began, and three genuinely went missing in the merge. The P3 sweep caught all three against the map and restored them.
- TDD on infrastructure held up. Six RED suites written before the rename turned green one requirement at a time and caught the sweep corrupting its own test assertions.
- The installed-tree insulation held. The live session ran the old contract from `.claude/` throughout while the source tree changed underneath it, exactly as designed.
- Parallel dispatch compressed the wall clock of P3's ten independent rewrites into roughly the duration of the slowest one.

## What cost time

- A repo-wide sweep rewrote literal strings inside the new tests and had to be repaired with concatenated needles. Sweeps and self-referential tests need the needle convention from the start.
- Two zsh and BSD-grep portability slips in inline sweep commands forced re-runs. Python file-walks proved the reliable tool.
- The legacy-suite sweep subagents died on a session limit mid-edit, and the remaining 23 suites were finished inline. Partial agent state resumed cleanly thanks to granular commits.
- Agents committing concurrently produced two wrong-scope commit subjects and one amend collision, repaired by rebase. Sequential commit ownership per agent, or no-commit agents, would have been cleaner.

## Telemetry

Every phase block records `emitted`. Zero failure markers. One correction early in P0 where the field was first recorded wrong and fixed in-run.

## Improvement suggestions

1. Discovery: the sweep-proof needle convention (`"context""-mode"`) belongs in the testing standards, not in tribal memory.
2. Implement: when dispatching agents that commit, assign each a file set and forbid amends, or collect commits centrally.
3. Validate: the consistency check now gates the plan phase, which would have surfaced the acceptance-criteria finding before codegen rather than at P4.
