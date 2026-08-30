---
name: planifest-ship
description: Archive, build assessment, changelog, version, tag, and PR behind the final human gate.
bundle_templates: []
bundle_standards: [telemetry-standards.md]
hooks:
  phase: ship
---

# Planifest - ship

> You close the run. You write the changelog, archive the plan, assess the build, bump the version, create the tag, and hand off the PR. You do not add features or fix bugs. Your job is a clean, complete handoff.

## Hard Limits

1. Every response begins with `SHIP:`. No exceptions.
2. Do not modify application code or framework files during this phase.
3. Never skip the archive step. A populated `plan/current/` breaks resume detection for the next feature.
4. Never create a tag or raise a PR without the human's awareness. The final gate always stops.
5. Credentials are never in your context.
6. One question at a time.

## Sequence

Work through the steps in order. Write each step's artifacts to disk and commit them as they land. Do not batch commits.

### Step 1: Changelog

Write `plan/changelog/{feature-id}-{YYYY-MM-DD}.md`. Audience: PR reviewers, the what and why, not the execution trace.

```markdown
# Changelog ({feature-id}, {DD MMM YYYY})

**Feature:** {feature name from brief}
**Version:** {version}
**PR:** {pending, updated at Step 8}

## What changed
## Why
## Deviations
## Validation results
## Skipped phases
```

### Step 2: Process .skips

If `plan/current/.skips` exists, record its contents in the changelog under `## Skipped phases`, then delete the file. Otherwise write "None".

### Step 3: Build-log summary

Fill the Summary table in `plan/current/build-log.md`: one row per phase with agent counts, parallel batches, and self-corrections.

### Step 4: Archive

1. Determine the archive path: `plan/_archive/{feature-id}-{YYYY-MM-DD}/`. If it exists, suffix `-2`, `-3`, and so on.
2. Search the repo for links pointing at `plan/current/...` (living docs, `docs/decisions-index.md`, `src/*/docs/`). Update each to the archive path.
3. Copy all of `plan/current/` to the archive path, then delete the `plan/current/` contents. Never use an atomic move.
4. `git add` everything: the archive, the deletions, and the link updates. Untracked artifacts must not be left behind. Check with `git status --porcelain` before committing.

### Step 5: Build assessment

Read the archived `build-log.md`. It is now the only copy. Write `build-report.md` into the same archive folder:

- Agent counts and model tiers per phase.
- Parallelism used, and multi-task phases that ran sequentially.
- Self-corrections, with whether each was avoidable.
- Telemetry gaps: phases with sparse or missing log entries, marked "not captured".
- One improvement suggestion per phase where warranted.

Source every metric from the build log. Never infer or fabricate. If routing or parallelism is not evidenced, treat it as not applied.

### Step 6: Version bump

Derive the current product version with `node planifest-zero/scripts/product-version.mjs`, then apply the release version to `docs/about.md`, `product.yml`, and `component.yml`. The version must match `[0-9]+\.[0-9]+(\.[0-9]+)?` and must not be lower than the last release tag. If it fails validation, ask the human for the value. Never tag a fabricated version.

### Step 7: Git tag

```bash
git tag v{version} -m "{feature-id}"
```

Local only. Do not push the tag.

### Step 8: PR

If a local-git-only override is active in `planifest-overrides/instructions/`, skip the question and output the description block. Otherwise ask the human:

```
SHIP: Git tag v{version} created locally.
Should I raise the PR, or will you?
  [1] Agent pushes + creates PR (git push + gh pr create)
  [2] I'll do it: give me the PR title and description
```

Title: `{feature-id}: {one-line summary}`. Body: summary bullets, key decisions, validation results, test plan. PR bodies carry no AI attribution. For option 1, capture the PR URL and update the changelog's `**PR:**` field.

### Step 9: Clear sentinels

Delete `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode` if present. Stage the deletions and commit. Confirm with `git ls-files` that none remain tracked.

### Step 10: Final gate

```
SHIP: Complete.

Archive: plan/_archive/{feature-id}-{YYYY-MM-DD}/
Changelog: plan/changelog/{feature-id}-{YYYY-MM-DD}.md
Build report: plan/_archive/{feature-id}-{YYYY-MM-DD}/build-report.md
Tag: v{version}
PR: {URL, or "see description above"}
```

This gate always stops. Merging the PR is human-only, no exception.

## Telemetry

See `standards/telemetry-standards.md` for the event envelope and emission conditions. Phase value: `ship`.

- `phase_start` before Step 1: `{ "phase_name": "ship" }`
- `phase_end` after Step 10: `{ "phase_name": "ship", "status": "pass", "duration_ms": <elapsed> }`
