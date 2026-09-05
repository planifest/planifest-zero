---
name: planifest-refresh-setup
description: Refreshes a Planifest install by detecting the target tool, reading the tracked `plan/state/{tool}.md` record first, falling back to the flags-used marker file and then installed hook wiring, confirming with the human on the loop, and re-invoking setup.sh/setup.ps1 with those flags. Invoke on request ("refresh the framework setup", "re-run setup with current settings", "refresh setup for {tool}").
hooks:
  phase: standalone
---

# Planifest - refresh-setup

> You refresh an existing Planifest install without the human on the loop having to reverse-engineer the original `setup.sh`/`setup.ps1` invocation from hook wiring. You never guess a flag that changes install behaviour. You never delete anything beyond the two boot files this skill regenerates. You are a standalone skill, invoked on request, outside the five-phase pipeline. No `plan/current/design.md` or phase gate is required to use it.

## Step 1 - Determine the Target Tool

The target tool is always explicit input, never silently guessed:

1. `claude-code` is the only supported tool. It matches `setup.sh`/`setup.ps1`'s `$VALID_TOOLS` / `$ValidTools`.
2. Scan the repo root for the install signal: a `.claude/` directory.
3. Install found: proceed to Step 2. No install found: go to Step 1a.

### Step 1a - No Install Found

Report plainly and stop:
> No Planifest install found{ for `{tool}`, if named}. This looks like an initial setup, not a refresh. Run `setup.sh`/`setup.ps1` directly instead.

Do not proceed to Step 2. Do not ask "which tool" in this branch. That question only applies when an install already exists.

## Step 2 - Check for an Interrupted Prior Run

1. Check whether the boot file `CLAUDE.md` is missing (the tool's own directory is `.claude`).
2. Check `{tool-dir}/.planifest-setup-flags` for `attemptStatus: "pending"`.
3. If both are true, this is an interrupted prior run. Report the recovered flags and command from the marker file, at high confidence (source: marker file, not re-inferred). Go directly to Step 4, skipping Step 3.
4. If either is false, this is a normal run. Continue to Step 3.

## Step 3 - Reconstruct the Active Flags

Skip this step if Step 2 produced a recovered flag set.

1. Check `plan/state/{tool}.md` first. This is the tracked record and, when valid, the highest-confidence source available. Read it and validate it:
   - It must contain a fenced ```json block that parses as well-formed JSON.
   - The parsed object must hold all four fields: `tool`, `flags`, `backendUrl`, `writtenAt`.
   - The `tool` field matches the target tool from Step 1.
   - If all of the above hold, the record is valid: report every flag it holds, plus the backend URL, at **high** confidence, source: `plan/state/{tool}.md`. The marker file is not consulted, and Step 3 skips straight to sub-step 4 below.
   - If the record is absent, unreadable, fails to parse, is missing any of the four fields, or names a different tool, treat it as missing. This does not stop the run: continue to sub-step 2.
2. Check `{tool-dir}/.planifest-setup-flags`. If it exists and is well-formed (see `planifest-zero/component.yml`), read `flags` and `backendUrl` and report every flag at **high** confidence, source: marker file.
3. If the marker file is also absent, incomplete, or for a different tool, infer flags from installed hook wiring instead:

   | Signal | Implies | Confidence |
   |--------|---------|-----------|
   | `{tool-dir}/hooks/telemetry/` exists with `context-pressure.mjs` etc., AND a `PLANIFEST_TELEMETRY_URL=<url>` value is wired into a hook command in the tool's settings file | `--structured-telemetry-mcp` plus `--backend-url <url>` (the wired URL) | high |
   | `plan/.orchestrator-strict` file exists | `--strict-orchestrator` | high |
   | No signal present for a given flag | that flag was not used | high (absence of a signal is itself a confident signal) |

4. Build the full flag list and the exact command that will be run: `setup.sh {tool} {flags...}` (or `setup.ps1 {tool} {flags...}` on Windows).

## Step 4 - Confirm With the Human on the Loop

Always required, in every run, regardless of confidence level, including a run where every flag is high confidence from the marker file. There is no bypass.

Present the target tool, every flag with its source (the record at `plan/state/{tool}.md` / marker file / inferred from `{signal}`) and confidence level, and the exact command about to run.

Wait for an explicit affirmative. If the human rejects the proposed flags, halt and take no further action. Do not delete anything or fall back to a different flag set on your own.

## Step 5 - Write the Marker Before Any Deletion

Immediately after confirmation and before Step 6's deletion, write `{tool-dir}/.planifest-setup-flags` as JSON with: `tool`, `flags` (the confirmed flags), `backendUrl` (URL or null), `writtenAt` (ISO 8601 UTC timestamp), `attemptStatus: "pending"`, and `attemptedCommand` (the exact command from Step 3.3).

This is the same file `setup.sh`/`setup.ps1` write on successful completion, not a separate cache file. This write must complete before Step 6 begins, so a process killed at any point after it leaves recoverable state on disk (see Step 2).

## Step 6 - Delete the Boot Files

Run `bash planifest-zero/scripts/refresh-delete-boot-files.sh` (or the `.ps1` variant on Windows) from the repo root. Do not delete files directly with a freeform command. Always invoke this script.

The script hardcodes the exact allowlist (`CLAUDE.md`, `AGENTS.md`) in code, takes no arguments, and cannot be told to delete anything else. Never delete `settings.local.json`, `.claude/settings.local.json`, or any other file, regardless of what the flag reconstruction or human confirmation contained.

## Step 7 - Re-invoke Setup

Run the exact command shown and confirmed in Step 4. On success, `setup.sh`/`setup.ps1` itself writes `attemptStatus: "completed"` to the marker file. Confirm to the human that `CLAUDE.md`/`AGENTS.md` were regenerated and report the flags now in effect. On failure, go to Step 8.

## Step 8 - Setup Failure Handling

1. **Stop immediately.** Do not retry automatically, under any condition.
2. **Investigate the likely cause**: check whether the path setup reported is locked, permission-denied, or held by another process (e.g. `lsof`/`fuser` where available).
3. **Report**: what setup's own output said, which step it reached, the investigated likely cause (or "could not be determined"), that `CLAUDE.md`/`AGENTS.md` may now be missing pending a successful rerun, the exact attempted command as a copyable code block, and confirmation that `settings.local.json` and other user-owned files were not touched.
4. The marker file from Step 5 still holds `attemptStatus: "pending"` and the attempted command. A later invocation of this skill recovers it via Step 2 instead of repeating detection.

## What This Skill Never Does

- Never deletes any file other than `CLAUDE.md`/`AGENTS.md`
- Never proceeds past Step 4 without an explicit human affirmative, regardless of confidence
- Never retries a failed setup re-invocation automatically
- Never invents a flag not already supported by `setup.sh`/`setup.ps1`
- Never treats "which tool" as a failure condition. It is ordinary input, asked once, up front.
