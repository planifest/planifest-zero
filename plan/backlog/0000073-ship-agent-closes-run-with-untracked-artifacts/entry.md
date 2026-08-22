---
title: "Backlog Entry: 0000073 - Ship-agent can close a run with untracked P8/P9 artifacts"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000073 - Ship-agent can close a run with untracked P8/P9 artifacts

**Source feature:** discovered during the `structured-telemetry-mcp` product's `0000019-loopback-daemon-hardening` ship (a downstream consumer of this framework)
**Source phase:** P9 (post-ship, observed during deploy verification)
**Deferral source:** process defect
**Date filed:** 2026-08-08

---

## Problem

The `planifest-ship-agent` close-out sequence generates artifacts *after* its own
commit points, so a completed run can end with untracked changes still in the tree.
A planifest run is expected to close with a clean working tree; leaving generated
artifacts untracked means the archive's own audit trail is incomplete in git.

Concrete instance from the downstream `0000019` run:

- **P7** commits the archive (`plan(p7): archive {feature-id}`).
- **P8** then spawns the build-assessment sub-agent, which writes
  `plan/_archive/{feature-id}-{date}/build-report.md` — **after** the P7 commit.
- **P9** tags and raises the PR. Nothing between P8's write and the PR re-stages
  the new `build-report.md`.

Result: `build-report.md` was left untracked on the branch, was not part of the
PR, and surfaced only by chance during a later `git status`. The same shape of gap
can affect anything P8 or P9 produce after their preceding commit (the build
report, a post-archive changelog PR-URL edit, a `product.yml`/version fix made at
P9, etc.). In `0000019` several of these were committed only because a human
noticed and committed them by hand.

Note the boundary this entry is scoped to: untracked changes *outside* a running
pipeline (ordinary editing between runs) are expected and are not the concern.
The defect is specifically that the ship-agent can declare a run **complete** (P9)
while untracked changes it or its sub-agents produced remain in the tree.

## Suggested Action

Two complementary fixes; either closes it, both is cleaner:

1. **Reorder P7/P8 so the archive is committed once, whole.** Generate the build
   report (P8's product) *before* the P7 archive commit, or fold the P8 output
   into the archive commit, so `plan/_archive/{feature-id}-{date}/` is never
   committed and then added to.
2. **Add a clean-tree gate at the end of P8 and P9.** Before declaring the phase
   complete, run a scoped `git status --porcelain` over `plan/`, `docs/`, and
   `src/**/docs/`, and **flag any untracked or modified file the ship-agent or its
   sub-agents produced to the human** — listed by path, with what wrote each —
   asking whether to commit and push to the PR branch. The human may decline; the
   requirement is that such files are never *silently* left behind at run close,
   mirroring the human-gated posture the rest of the pipeline already uses.

A `git status --porcelain` assertion in the ship-agent's own test would catch a
regression of this in future.

## Why Deferred

Filed at explicit human request after the `0000019` ship in a downstream product,
where the human noted these artifacts "need to be flagged, though of course the
human can say no," and that "it's not expected to close a planifest run with
untracked changes." The fix lives in `skills/planifest-ship-agent/` in this
framework repo, so it belongs to the framework's own pipeline and numbering, not a
consumer product's backlog.
