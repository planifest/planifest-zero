# Verification report - 0000164-hardening-and-backlog-skill

All checks ran on branch `feat/0000164-hardening-and-backlog-skill` (macOS, `/bin/bash` 3.2.57, `node`). Every fixture lived in a directory from `mktemp -d`. Nothing ran inside the repo's own `plan/` or `.claude/`. No source file changed. This report is the only file added.

`pwsh` is not installed here. The PowerShell side of REQ-004 and REQ-009 is `not-verifiable` locally and deferred to CI on PR #27. The Bash side is verified.

## Summary

| Outcome | Criteria |
|---|---|
| verified | 18 |
| verified for Bash, PowerShell side not-verifiable here | 3 (REQ-004 b, REQ-004 c, REQ-005 a) |
| verified by execution, no covering test (coverage gap) | 1 (REQ-003 b) |
| failed locally, passes in a clean copy | 2 (REQ-008 b, REQ-009 a) |

Total: 24 criteria. No criterion failed on shipped code. Two points need a decision:

- **Local size-budget failure.** `test-0000151-req-011-orchestrator-references-split.sh:45` fails under `env -i /bin/bash`. `CLAUDE.md` plus `SKILL.md` is 35,524 bytes against a 35,484 byte budget. `CLAUDE.md` is gitignored (`.gitignore:3`), so the local copy edited for REQ-007 is not in the PR. In a copy of `ravintio-zero/` with no `CLAUDE.md` (the CI state) the suite passes, 64 of 64. CI on PR #27 settles it. A maintainer who runs the suite locally with the REQ-007 wording in `CLAUDE.md` sees the failure, so the budget or the wording needs a decision.
- **Coverage gap.** No test asserts that the five converted loops skip an empty line (REQ-003 b). I confirmed the behaviour by execution.

## What I started

- Gate-write fixtures: a temp project with `src/comp/`, `plan/backlog/`, `plan/roadmap/`, and `other/`, plus a second temp directory as the outside location. Symlinks and `/tmp` aliases were made per case.
- Bash 3.2: `env -i HOME="$HOME" PATH="$PATH" /bin/bash` for the guard suite, four converted suites, and the full runner.
- Telemetry retirement: a temp git repo holding a copy of `ravintio-zero/`, then `bash ravintio-zero/setup.sh claude-code`.
- File-backlog: a temp git repo with one commit, then a hand-run of the skill steps (a shell function that mirrors each step in `SKILL.md`).
- Full suite: `RAVINTIO_TEST_QUIET=1 env -i ... /bin/bash ravintio-zero/tests/run-tests.sh`. Result: 117 feature suites passed, 1 failed, 19 regression suites passed, 12 PowerShell suites skipped.

## Coverage table

Each row names the executing test. Line numbers are in `ravintio-zero/tests/`.

| Criterion | Covering test (file:line) |
|---|---|
| REQ-001 a: outside target exits 0 with and without design | `test-0000164-req-001-gate-write-outside-project.mjs:11-13`, `:23` |
| REQ-001 b: in-project ungated exits 2, plan/current needs sentinel | `...req-001...mjs:17`, `:19`, `:21` |
| REQ-001 c: in-project symlink to in-project gets checks | `test-0000164-req-006-gate-write-symlink-cases.mjs:21-26` |
| REQ-002 a: plan/backlog and plan/roadmap exit 0 | `test-0000164-req-002-gate-write-documented-scope.mjs:9-10` |
| REQ-002 b: prefixes and basenames unchanged | `...req-002...mjs:16-17`, header check `:15` |
| REQ-003 a: no `done < <(` under tests | `test-0000164-req-008-no-process-substitution-loops.sh:28` |
| REQ-003 b: converted loops skip empty line, same results | none for the empty-line skip. Same results: `test-0000042-req-009-pack-identifiers.sh:127`, `test-0000042-req-010-pack-wording-allowlist.sh:103`, `regression/...:103`, `test-0000160-req-001-pack-identifiers.sh:43`, `run-tests.sh:75` |
| REQ-004 a: no cleanup symbols | `test-0000164-req-004-no-telemetry-cleanup.sh:16-19` |
| REQ-004 b: telemetry untouched, no telemetry line | `...req-004...sh:33-42` (Bash only) |
| REQ-004 c: retired hook pruned | `...req-004...sh:48-53`, `test-0000151-req-004-prune-retired-hooks.sh` (Bash), `.ps1` twin (PowerShell, CI) |
| REQ-005 a: skill exists, name matches, setup installs it | `test-0000164-req-005-file-backlog-skill.sh:12-19`, `test-0000031-req-004-setup-execution.sh:23`, `:32` |
| REQ-005 b: id rule, slug rule, never-overwrite | `...req-005...sh:22-33` |
| REQ-006 a: symlink to outside exits 0 | `test-0000164-req-006-gate-write-symlink-cases.mjs:12-13` |
| REQ-006 b: outside path through symlink into project gets checks | `...req-006...mjs:35-37`, `:45-46` |
| REQ-006 c: Windows suites pass | `test-gate-write-windows.sh`, `test-gate-write-windows.mjs` |
| REQ-007 a: CLAUDE.md wording | `test-0000164-req-007-gate-write-doc-correction.sh:20-39` (skips if `CLAUDE.md` is absent) |
| REQ-007 b: three other docs | `...req-007...sh:20-39` |
| REQ-008 a: guard fails on planted file | `test-0000164-req-008-no-process-substitution-loops.sh:30-35` |
| REQ-008 b: full suite on Bash 3.2 and Bash 5 | `run-tests.sh` (whole runner) |
| REQ-009 a: every suite passes in CI | `run-tests.sh` (whole runner) |
| REQ-009 b: changelog note | none. Checked by reading `plan/changelog/0000164-...md` |
| REQ-009 c: component.yml claim removed | none. Checked by diff of `ravintio-zero/component.yml` |
| REQ-010 a: never-commit rule | `test-0000164-req-005-file-backlog-skill.sh:36-39` |
| REQ-010 b: catalogue row and 13 skills | `...req-005...sh:40`, `test-0000031-req-003-five-phases.sh:9-12`, `test-0000031-req-004-setup-execution.sh:23`, `:32` |

Every criterion has at least one covering test, except the empty-line skip in REQ-003 b and the two documentation criteria in REQ-009 b and c. The two documentation criteria are static text and I verified them by reading the shipped files.

## Gate-write execution (REQ-001, REQ-002, REQ-006)

Command shape for every case: `printf '{"cwd":"<proj>","tool_input":{"file_path":"<target>"}}' | node ravintio-zero/hooks/enforcement/gate-write.mjs`, with `<proj>` a temp project.

| Case | Exit | Message |
|---|---|---|
| Outside target, no `design.md` | 0 | none |
| Outside target in missing directories, no design | 0 | none |
| Outside target, `design.md` present | 0 | none |
| In-project `other/x.js`, no design | 2 | `[RAVINTIO] No confirmed design at plan/current/design.md. Complete P0 Discovery first.` |
| In-project `other/x.js`, design lists only `src/comp/` | 2 | `[RAVINTIO] Path 'other/x.js' is not covered by the confirmed design...` |
| In-project `src/comp/a.js`, design present | 0 | none |
| `plan/current/x.md`, no sentinel | 2 | `[RAVINTIO] No orchestrator sentinel at plan/.orchestrator-active...` |
| `plan/backlog/0000001-a/entry.md`, no sentinel, no design | 0 | none |
| `plan/roadmap/r.md`, no sentinel, no design | 0 | none |
| In-project symlink to an outside directory, design present | 0 | none |
| Same symlink, no design | 0 | none |
| Outside symlink to in-project `other/`, design present | 2 | `Path 'other/x.js' is not covered...` |
| Outside symlink to in-project `src/comp/` | 0 | none |
| Outside symlink to in-project `other/`, no design | 2 | `No confirmed design...` |
| cwd `/tmp/gw-N`, target `/private/tmp/gw-N/other/x.js`, no design | 2 | `No confirmed design...` (target treated as inside) |
| cwd `/private/tmp/gw-N`, target `/tmp/gw-N/other/x.js`, no design | 2 | `No confirmed design...` (target treated as inside) |

The blocked cases wrote the message to stderr and stdout. The existing suite `test-gate-write-windows.sh` exited 0 ("All gate-write Windows tests passed").

- REQ-001 a: **verified.** Three outside cases exit 0.
- REQ-001 b: **verified.** The in-project ungated cases exit 2 and the `plan/current/` write without a sentinel exits 2.
- REQ-001 c: **verified.** The mjs suite covers the in-project symlink to an in-project directory (`:21-26`, exit 2 for ungated, exit 0 for a component). My outside-path symlink cases into the project also got the checks.
- REQ-002 a: **verified.** Both `plan/backlog/` and `plan/roadmap/` exit 0 with no sentinel and no design.
- REQ-002 b: **verified.** `git diff main...HEAD -- ravintio-zero/hooks/enforcement/gate-write.mjs` shows the `ALWAYS_PERMITTED_PREFIXES` and `ALWAYS_PERMITTED_FILES` lines are not in the diff. The suite regexes at `...req-002...mjs:16-17` also pass.
- REQ-006 a: **verified.** Both symlink-to-outside cases exit 0.
- REQ-006 b: **verified.** The outside-path symlink into the project exits 2 for an ungated target and 0 for a component target. The `/tmp` and `/private/tmp` cases resolve to the same project and get the checks in both directions.
- REQ-006 c: **verified** on this host. The Windows path-form suites exit 0 here. Windows hosts run in CI.

## Bash 3.2 (REQ-003, REQ-008)

- REQ-003 a: **verified.** `grep -rn 'done < <(' ravintio-zero/tests` printed nothing (exit 1). The guard test names the pattern in parts, so it does not match.
- REQ-003 b: **verified by execution, coverage gap.**
  - Method: diff the five files, run the suites under `env -i ... /bin/bash` 3.2, and run the loop shape on empty input.
  - Evidence: each of the five diffs adds `[ -n "$x" ] || continue` and swaps to `done <<< "$(...)"`. Four converted suites exit 0 (40, 7, 2, and 2 checks passed). `run-tests.sh` ran all suites. On 3.2, a `while read` loop over `<<< "$(true)"` with the empty-line guard ran 0 iterations. No test asserts this empty-line skip.
- REQ-008 a: **verified.**
  - Method: copy `ravintio-zero/` to a temp directory, run the guard, plant a file with the pattern, run it again.
  - Evidence: clean copy exit 0. After planting `tests/planted.sh`, the guard printed `FAIL ... actual: planted.sh` and exited 1.
- REQ-008 b: **failed locally, Bash 5 not-verifiable here.**
  - Method: `env -i HOME PATH /bin/bash ravintio-zero/tests/run-tests.sh`.
  - Evidence: 117 passed, 1 failed, exit 1. The failure is the size budget described in the summary. In a copy without `CLAUDE.md` the same suite passes, so the cause is the local gitignored file. Bash 5 runs in CI on PR #27.

## Telemetry retirement (REQ-004, REQ-009)

Fixture: temp git repo with a copy of `ravintio-zero/`. Seeds: `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, `plan/.telemetry-receipts/`, a `PostToolUse` entry with the `mcp__structured-telemetry-mcp__emit_event` matcher and command `echo keep-me`, a `UserPromptSubmit` entry running `phase-enum.mjs`, and `.claude/hooks/enforcement/phase-enum.mjs`. Command: `bash ravintio-zero/setup.sh claude-code`.

- REQ-004 a: **verified.** The grep from the criterion returned nothing (exit 1). `setup.sh` has 4 `RETIRED_HOOK_NAMES` lines and `setup.ps1` has 5 `RetiredHookNames` lines.
- REQ-004 b: **verified for Bash, PowerShell not-verifiable here.** Setup exited 0. `.claude/telemetry-enabled` and both `plan/.telemetry-*` folders remain. The settings file still holds the telemetry matcher and `keep-me`, and parses as JSON. The word "telemetry" appears 0 times in stdout and stderr. The only line naming a retired hook is `- removed .claude/hooks/enforcement/phase-enum.mjs`.
- REQ-004 c: **verified for Bash, PowerShell not-verifiable here.** The `phase-enum.mjs` file is gone and its `settings.json` entry is gone (0 matches for `phase-enum`). `test-0000151-req-004-prune-retired-hooks.sh` exits 0 (32 checks). No `.ps1` suite covers the "telemetry untouched" half of REQ-004 b, so CI must run `pwsh` for that.
- REQ-009 a: **failed locally, CI pending.** See the summary. The deleted suites are gone (`ls tests | grep -E '0000033|0000041'` shows only an unrelated `0000041-req-004` suite). `test-0000035-req-005-leftover-temp-file.sh` exits 0. The PowerShell rewrites are not-verifiable here (12 PowerShell suites skipped).
- REQ-009 b: **verified.** `plan/changelog/0000164-hardening-and-backlog-skill-2026-10-25.md` carries `**Version:** 1.1.0` and an "Upgrade note" that tells a pre-0000033 consumer to remove the matcher entries, `.claude/telemetry-enabled`, `plan/.telemetry-failures`, and `plan/.telemetry-receipts` by hand.
- REQ-009 c: **verified.** `git diff main...HEAD -- ravintio-zero/component.yml` shows the setup line now reads "retract any legacy setup-config record on the next run". The roadmap "telemetry labels" line (line 36) remains.

## File-backlog skill (REQ-005, REQ-010)

Fixture: temp git repo on `main` with one commit, `plan/backlog/0000004-x/`, `plan/_archive/0000007-y-2026-01-01/`, and `plan/changelog/0000006-z.md`. Before: clean status, HEAD `688c6f18`, branch `main`, empty stash list. I followed `SKILL.md` steps 1 to 6 with slug `demo-entry` and the pack's template (the repo has none).

- Run 1 chose id `0000008` (highest of 4, 7, 6, plus one, width 7) and wrote `plan/backlog/0000008-demo-entry/entry.md` from the template (`title: "Backlog Entry: 0000008 - Demo entry"`). `git status --porcelain` printed only `?? plan/backlog/0000008-demo-entry/`. HEAD, branch, and stash list matched the "before" values.
- Run 2 with the same slug printed `EXISTS: plan/backlog/0000008-demo-entry - wrote nothing`. The file list and status were identical to after run 1.
- Run 3 in a repo with `plan/_archive/0000003-q-2026-01-01/` and no `plan/backlog/` created `plan/backlog/` and wrote `0000004-demo-entry/entry.md`. Status showed only `?? plan/`.
- REQ-005 a: **verified for Bash, PowerShell not-verifiable here.** The skill exists with a matching name and description, and `test-0000031-req-004-setup-execution.sh` (exit 0) shows setup installs 13 skills, on first run and on re-run. Setup in PowerShell runs in CI.
- REQ-005 b: **verified.** The structure suite (21 checks) passes. My walk-through confirmed the id rule across all three folders, the same-slug stop, and no overwrite.
- REQ-010 a: **verified.** The "Never commit, push, switch branches, stash, or open a pull request" line exists. The git state stayed unchanged in all three runs.
- REQ-010 b: **verified.** The catalogue row reads `| ravintio-file-backlog | Human asks to file a backlog entry in another repo | Standalone. Invoke any time. |`. `test-0000031-req-003-five-phases.sh` (25 checks) and `...req-004...` (12 checks) expect 13 skills and pass.

### Skill-instruction findings

None of these block the skill. Each is a gap a reader meets while following it.

1. Step 2 says to use "this pack's width" when the target has no ids, but neither `SKILL.md` nor the template states that width (the pack uses 7 digits). A fresh repo has no answer in the text. Name the width.
2. Step 5 says "in that repo's template format" but does not say whether to keep the template's guidance blockquote and the `{{...}}` hints. I dropped the blockquote placeholders by hand, so two agents could produce different entries. State what to keep.
3. Step 5 does not say to omit the `**Parked branch:**` line for an open entry. The template says so in its note, but `SKILL.md` does not point to it.
4. Step 1 creates `plan/backlog/` before step 4's same-slug check. This is harmless, because the check can only match when the folder already exists, but the order reads oddly.
5. Step 4 says "If the chosen id is taken, take the next free id". Highest plus one cannot be taken unless two runs overlap, so the rule only guards a race. Say so.
6. Step 4 matches the slug only in `plan/backlog/`. A slug that exists in `plan/_archive/` under another id writes a duplicate-named entry. Decide whether that is intended.
