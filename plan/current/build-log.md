---
title: "Build Log - 0000030-framework-cut-down"
summary: "Working telemetry file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - 0000030-framework-cut-down

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000030-framework-cut-down` |
| Pipeline start | `2026-08-22T14:51:24Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5[1m]` |
| Cheaper model | `claude-sonnet-5` |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `2026-08-22T14:51:24Z` |
| Model tier | primary |
| Skills loaded | planifest-orchestrator, fast-path, change-pipeline |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Telemetry | emitted |
| Notes | Route triage recorded below. |

#### Route triage

- The human first selected the Fast Path route.
- Fast Path was rejected at its gate: the change edits `setup.sh` install logic, deletes two components, and rewrites `product.yml`. None of the four Fast Path criteria hold.
- The human then selected the Change Pipeline route. Recorded as the confirmed route.

#### P0 exchanges

P0 exchange (delete scope, tool support): Q: Beyond plan history and docs, what else goes? / A: Non-Claude tool support.
P0 exchange (route): Q: How should this deletion build run? / A: Fast Path, later revised to Change Pipeline once the Fast Path gate failed.
P0 exchange (src): Q: Do the two src/ components go? / A: Delete both.
P0 exchange (external skills): Q: Does planifest-framework/external-skills/ go? / A: Delete it.
P0 exchange (plan files): Q: What about the three loose files in plan/? / A: Keep all three.
P0 exchange (CI): Q: What happens to .github/workflows/planifest.yml? / A: Leave it as is.
P0 exchange (README and product.yml): Q: Rewrite or leave? / A: Rewrite both now.
P0 exchange (README scope): Q: What should the new README describe? / A: The cut-down framework.
P0 exchange (skill trim): Q: Trim the 21 pipeline skills in this build? / A: No, delete files only.
P0 exchange (changelog): Q: Fast Path writes to plan/changelog/, which is on the delete list. / A: Empty the folder, keep it.
P0 exchange (archive and backlog): Q: Empty or delete outright? / A: Empty both, keep the folders.
P0 exchange (docs): Q: Empty or delete outright? / A: Empty it, keep the folder.
P0 exchange (PowerShell): Q: Does Windows support go with the non-Claude tool support? / A: Keep all PowerShell for Claude Code.
P0 exchange (context-mode): Q: Should context-mode come out of the framework too? / A: Rip it out fully. Confirmed again in a follow-up message.
P0 exchange (pre-flight): Q: Is main up to date, and what happens to the uncommitted setup-config change? / A: Commit it first. Revised to commit it on the feature branch, since CLAUDE.md makes commits to main human-only.

---

## Summary (filled at P7)

| Metric | Value |
|--------|-------|
| Total phases completed | `{{count}}` |
| Total agents spawned | `{{count}}` |
| Total MCP calls | `{{count}}` |
| Phases using parallelism | `{{count}}` |
| Primary tier agent calls | `{{count}}` |
| Cheaper tier agent calls | `{{count}}` |
| Self-corrections | `{{count}}` |
| Phases skipped | `{{list or "none"}}` |
| Phases with a recorded telemetry gap | `0` |

#### P0 gate

- Adoption mode: standard-iterative, detected from 30 archived features and `docs/about.md`.
- Version confirmed: 0.1.0. Downward from 0.28.1 under an explicit human override; rationale recorded in `design.md`.
- Backlog pickup: all 23 entries discarded in bulk by human decision, matching the empty-the-folder scope item. No entry was pulled into this feature.
- Scope Lock Challenge: not run. The Change Pipeline route does not re-run P0 coaching.
- Run mode: continuous.
- Design confirmed: 22 Aug 2026 @ 04:03 p.m. BST.

### PC: Change Pipeline

| Field | Value |
|-------|-------|
| Start | `2026-08-22T15:37:08Z` |
| Model tier | primary |
| Skills loaded | planifest-change-agent |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Telemetry | emitted |
| Notes | See below. |

**Subagent decomposition:** not used. Repo instruction custom-002 prefers parallel
subagents for multi-unit work, and the context-mode sweep would have qualified. This
session carries a standing directive not to call the Agent tool unless the human asks
for it. The conflict was surfaced to the human before Phase 2 began, and the work ran
inline.

**Phase 1, domain context.** Blast radius recorded in change-summary.md. Three
components affected, one surviving.

**Phase 2, targeted change.** Executed in eleven commits. One mid-build question:
skill sync had no source left after external-skills was deleted, and the human
confirmed removing the flag and the scripts.

**Phase 3, validate.** First full run: 40 feature suites passed, 12 failed;
17 regression passed, 4 failed. Every failure asserted against a deleted feature. One
suite deleted, nine amended, zero self-corrections against real regressions. Final run:
51 feature suites and 20 regression suites, zero failures.

**Phase 4, ADR.** The contract changed, so ADR-001 records the Claude Code only
decision. It supersedes 0000001 ADR-001 to ADR-004.

**Phase 5, documentation.** component.yml, product.yml, README.md, and the four
docs/ artifacts rewritten. setup.sh re-run to regenerate the installed .claude/ tree.

**Deviations from the confirmed design:** three, all recorded in the changelog.
Skill sync removal, component.yml rewritten rather than patched, and the src/
scaffold restored after setup recreated it.

Gate accepted: PC (2026-08-22T15:37:08Z)
