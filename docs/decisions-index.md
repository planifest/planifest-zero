# Decisions Index

> Change record. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file. Update it in place.

Last updated: 0000164-hardening-and-backlog-skill

---

## Note on the reset

Feature 0000030 emptied `plan/_archive/`, so the ADR files for features 0000001 through 0000029 no longer exist in the working tree. They remain in git history.

This index restarts from 0000030. Decisions from earlier features still bind where their subject survives, but the ADR text has to be read from history.

Rows for features before 0000160 use the product name and paths of their time. 0000160 renamed them.

---

## All Architecture Decision Records

### Feature 0000030: framework-cut-down

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Claude Code is the only supported tool target | accepted | Drops eight tool targets, the vendored external skill library, and the context-mode integration. Supersedes 0000001 ADR-001 to ADR-004. |

### Feature 0000031: five-phase-planifest-zero

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Five-phase pipeline contract and skill consolidation | accepted | Collapses the ten-phase pipeline to five phases (discovery, plan, implement, validate and accept, ship) and 21 skills to 12. |
| ADR-002 | Folder rename and product identity | accepted | Renames `planifest-framework/` to `planifest-zero/`, sets the `product.yml` id to `planifest-zero`, and fixes the Windows refresh script to derive its own path. |
| ADR-003 | One route: the feature pipeline | accepted | Drops the Change Pipeline and Fast Path routes. Every change runs the five-phase feature pipeline, and one CI parity check applies to every diff. |
| ADR-004 | Living docs describe the present only | accepted | Moves historical narrative to change records: `plan/changelog/`, `plan/_archive/`, ADR files, and git history. This index and `docs/about.md` carry stated exemptions. |

### Feature 0000032: relocate-setup-config-to-plan-state

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The setup-config record lives in plan/state/ | accepted | Moves the tracked setup-flags record from `planifest-overrides/setup-config/{tool}.md` to `plan/state/{tool}.md`. Supersedes 0000025 ADR-002. |
| ADR-002 | Refresh-setup reads the record before the marker | accepted | `planifest-refresh-setup` Step 3 reads `plan/state/{tool}.md` first at high confidence, falling back to the gitignored marker then hook inference. |
| ADR-003 | Setup removes the old record inline | accepted | `setup.sh` and `setup.ps1` delete the pre-relocation record at its exact path after a successful write, with no separate migration file. |

### Feature 0000033: remove-telemetry-mcp

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Telemetry is not a pack concern | accepted | Removes the telemetry system from `planifest-zero` with no replacement and no extension seam. Drops `backendUrl` from the setup-config record, narrowing 0000032 ADR-001. |
| ADR-002 | Setup cleans up telemetry wiring on every run | superseded by 0000164 ADR-003 | Every setup run removes legacy telemetry hook entries, the opt-in sentinel, and the marker directories. One line per removal, a warning without failing. |
| ADR-003 | The phase vocabulary lives in prose, not in a module | accepted | Deletes `phase-enum.mjs` and states the five phase names in `pipeline-reference.md`. The `product.yml` id and its hard stop stay, for versioning. |

### Feature 0000164: hardening-and-backlog-skill

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stack unchanged | accepted | Keeps the declared stack and adds no dependency. `gate-write.mjs` uses `realpathSync` from `node:fs`. |
| ADR-002 | gate-write scopes to the project by real path | accepted | The hook exits 0 when a target's real path lies outside the project's real root. A symlink inside the project that points outside counts as outside. |
| ADR-003 | Retire the telemetry cleanup and keep the retired-hooks list | accepted | Setup drops the legacy telemetry cleanup in both shells. The list stays as `RETIRED_HOOK_NAMES` and `$RetiredHookNames`, and hook install drops settings entries for any retired hook. Supersedes 0000033 ADR-002. |
| ADR-004 | The file-backlog skill never touches the target repo's git state | accepted | `ravintio-file-backlog` writes one uncommitted entry folder. It never commits, pushes, switches branches, stashes, or opens a pull request there. |

---

## Superseded

| ADR | Superseded by | Reason |
|-----|---------------|--------|
| 0000001 ADR-001 to ADR-004 | 0000030 ADR-001 | The context-mode hook design they governed no longer exists. |
| 0000025 ADR-002 | 0000032 ADR-001 | The record moved from planifest-overrides/setup-config/ to plan/state/. The ADR text is in git history only. |
| 0000018, 0000024, 0000026, 0000027, and 0000028 telemetry ADRs | 0000033 ADR-001 | Their subject no longer exists in `planifest-zero`. The ADR text is in git history only. |
| 0000024 product-id ADR (rationale only, partly superseded) | 0000033 ADR-003 | The `id` field and the hard stop stand. Versioning and archive attribution replace telemetry attribution as the reason. |
| 0000032 ADR-001 (record shape only, narrowed) | 0000033 ADR-001 | The record drops `backendUrl` and holds `tool`, `flags`, and `writtenAt`. Its location and tracked status stand. |
| 0000036 ADR-003 (Bash suites out of CI only, narrowed) | 0000037 ADR-002 | The `bash-suites` job runs the Bash suites in CI. The Windows job stands. |
| 0000037 ADR-003 (decision item 4 only, narrowed) | 0000041 ADR-003 | The non-array warning no longer prints the old value. Warn, replace, and exit 0 stand. |
| 0000031 ADR-001 (phase numbers and prefixes only, superseded in part) | 0000042 ADR-003 | Phases take the numbers P0 to P4 and number-plus-name prefixes. The five-phase contract and skill consolidation stand. |
| 0000023 run-mode gate rules (in skills and tests, no ADR) | 0000042 ADR-002 | The two earlier run modes become `gated` and `autonomous`. |
| 0000042 ADR-002 (merge rule only, amended) | 0000043 ADR-003 | The agent may squash-merge its own step PR into a `roadmap/*` branch after a clean P3 and green CI. Merging into `main` stays human-only. |
| 0000031 ADR-002 (folder and product id only, superseded in part) | 0000160 ADR-001 | The pack folder is `ravintio-zero/` and the product id is `ravintio-zero`. |
| 0000042 ADR-004 (brand word only, superseded in part) | 0000160 ADR-004 | A separate brand guard test blocks the earlier product name. The wording allowlist test for the retired word stands. |
| 0000043 ADR-004 (driver child contract, extended) | 0000151 ADR-005 | Each roadmap child gets a model, an optional turn cap, a step log, and telemetry labels. The fresh `claude -p` session per step stands. |
| 0000042 ADR-002 (exception stops, extended) | 0000151 ADR-004 | A sixth exception stop covers a library or service missing from the approved list. It applies to both run modes. |

### Feature 0000034: setup-hardening

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Retired setup flags warn and continue | accepted | Setup accepts four retired flags with one warning each and skips the `--backend-url` value. Supersedes the no-op rejection in 0000030 ADR-001. |
| ADR-002 | settings.json writes go through a temporary file and a rename | accepted | Every `settings.json` write uses a same-folder temporary file, keeps the original's mode, and never follows a planted link. |
| ADR-003 | The stack stays as it is | accepted | No new language, runtime, or test framework. |


### Feature 0000035: powershell-setup-parity

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | setup.ps1 writes the same hook entries as setup.sh | accepted | `setup.ps1` wires all six enforcement hooks in the `setup.sh` entry shape, and a static parity suite checks the match. |
| ADR-002 | setup.ps1 supports Windows PowerShell 5.1 | accepted | `setup.ps1` uses no PowerShell 7-only feature, so it runs on the PowerShell that ships with Windows. |
| ADR-003 | setup.ps1 flags are case-sensitive | accepted | The flag `switch` matches case, as `setup.sh` does. Both scripts remove a leftover temporary file at the start of each run. |

### Feature 0000036: test-runner-coverage

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Stray test files fail the run | accepted | `run-tests.sh` names every file under `tests/` that is neither a suite nor a known non-suite, and exits 1. |
| ADR-002 | PowerShell suites use a plain assert helper | accepted | `test-*.ps1` suites use `helpers/assert.ps1` with no Pester. `run-tests.sh` runs them with `pwsh` or reports the skip. |
| ADR-003 | CI runs the PowerShell suites on Windows under both hosts | accepted | A `windows-latest` job runs `run-tests.ps1` with `powershell` and with `pwsh`. Bash suites stay out of CI for now. |

### Feature 0000037: self-host-on-planifest-zero

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The repo self-hosts on planifest-zero | accepted | Repoints `core.hooksPath` to `planifest-zero/hooks`, then deletes `planifest-framework/`. The setup record moves to `plan/state/claude-code.md`. |
| ADR-002 | The Bash suites run in CI on Ubuntu | accepted | A `bash-suites` job runs `run-tests.sh` with `PLANIFEST_REQUIRE_PWSH=1` and `contents: read`. The `validate-telemetry-schema` job goes. |
| ADR-003 | Setup repairs the hook entries it owns | accepted | `setup.sh` removes Planifest `PreToolUse` entries on any matcher. Both scripts warn on a non-array hook event and replace it. |
| ADR-004 | P0 states standard-iterative mode without asking | accepted | When standard-iterative is the only signal, the orchestrator states the mode and its signal. Every other case keeps the question. |

### Feature 0000038: setup-hook-filter-fixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as it is | accepted | No new language, runtime, or test framework. |
| ADR-002 | Setup filters Planifest hook commands one at a time | accepted | Both scripts remove only Planifest commands from a `PreToolUse` or `UserPromptSubmit` entry and keep user commands. `setup.sh` matches `UserPromptSubmit` by path boundary. Refines 0000037 ADR-003. |

### Feature 0000039: setup-hardening-release-sizing

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as it is | accepted | No new language, runtime, or dependency. |
| ADR-002 | Invalid JSON exits 1 with a fixed message | accepted | The hook install step prints one fixed line naming the file, leaves it unchanged, and exits 1. The telemetry cleanup still warns and carries on. |
| ADR-003 | A single-object `hooks` value counts as a one-item array | accepted | Both scripts apply the per-command filter to a single-object `hooks` value. Refines 0000038 ADR-002. |
| ADR-004 | The release budget lives in `product.yml` | accepted | An optional `releaseSize` field sets a budget of 4, 8, or 14 points, with `medium` as the default. It replaces the fixed 3-story rule. |

### Feature 0000040: setup-json-checks-and-park

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as it is | accepted | No new language, runtime, or dependency. |
| ADR-002 | Valid JSON that is not a settings object exits 1 | accepted | Both scripts print one shared fixed line, leave the file unchanged, and exit 1. Extends 0000039 ADR-002. |
| ADR-003 | Only `setup.ps1` rejects case-duplicate keys | accepted | `ConvertFrom-Json` can't read them, so `setup.ps1` gives the shared line. `setup.sh` accepts them. |
| ADR-004 | JSON depth is capped at 1024 | accepted | `Test-JsonText` uses a counter and a `Stack[char]`, runs in linear time, and fails past 1024 levels. |
| ADR-005 | Park keeps the work on the feature branch | accepted | Park pushes the branch and files a `parked` backlog entry by chore PR. Pickup resumes or discards it. |

### Feature 0000041: setup-cleanup-and-park-hardening

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as it is | accepted | No new language, runtime, or dependency. |
| ADR-002 | The telemetry cleanup skips unreadable settings | accepted | Both cleanups skip in silence on a parse or shape failure. The hook install step reports the fault once. Extends 0000033 ADR-002. |
| ADR-003 | The non-array warning drops the old value | accepted | Both scripts name the event and the file only. Supersedes decision item 4 of 0000037 ADR-003. |

### Feature 0000042: autonomous-mode-and-prefixes

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as it is | accepted | No new language, runtime, or dependency. |
| ADR-002 | Gated and autonomous run modes | accepted | Replaces the two earlier run modes with `gated` and `autonomous`. Autonomous runs to a raised PR. Five exception stops apply to both modes. |
| ADR-003 | Phase numbers P0 to P4 and number-plus-name prefixes | accepted | Phases run P0 Discovery to P4 Ship. Messages start with `P0 Discovery:` to `P4 Ship:`. A guard test blocks stale cites. Supersedes 0000031 ADR-001 in part. |
| ADR-004 | Pack wording and identifier map | accepted | No tracked file outside history describes Planifest Zero with the retired word. Identifiers follow one map, and an allowlist test enforces the rule. |

### Feature 0000043: autonomous-roadmaps

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as declared | accepted | No new language, runtime, or dependency. Adds one Node hook, `merge-guard`, and one Node script, `roadmap-run.mjs`. |
| ADR-002 | Roadmap storage and lifecycle | accepted | Drafts live in `plan/roadmap/`. The one active roadmap lives in `plan/current-roadmap/` on the roadmap branch. Ids share the backlog sequence. |
| ADR-003 | Agent squash-merge into roadmap branches | accepted | The agent may run `gh pr merge --squash` for its own step PR into `roadmap/*` after a clean P3 and green CI. `merge-guard` enforces it. Amends the 0000042 run-mode merge rule. |
| ADR-004 | Driver script runs each step in a fresh session | accepted | `roadmap-run.mjs` runs each step as its own `claude -p` session in auto permission mode. A lock file stops a second driver. |
| ADR-005 | Tag after the squash merge in a roadmap step | accepted | A roadmap step squash-merges first, then tags the squash commit and pushes the tag. Outside a roadmap, tag-before-PR stays. |
| ADR-006 | Self-confirmed roadmap steps and stage prefixes | accepted | A step's P0 builds the brief from its backlog entries and self-confirms. R-A Chart is the single human approval, including predicted additive schema changes. Stages R-A to R-E sit beside P0 to P4. |
| ADR-007 | Progress markers and interrupted-unit resume | accepted | Each dispatched unit logs `In progress:` before it starts and `Done:` with its work. On resume, the session stashes left-over changes and reruns an interrupted unit from its start. |

### Feature 0000151: hardening-efficiency-and-ci

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The stack stays as declared | accepted | No new language, runtime, or package. Adds one Node helper, `roadmap-labels.mjs`, and edits existing files. |
| ADR-002 | Hook block reasons go to stderr and stdout | accepted | `gate-write`, `em-dash-guard`, and `ratchet-check` write each block reason to both streams, as `merge-guard` does. The stdout write stays plain text. |
| ADR-003 | Ship clears sentinels before the PR | accepted | Ship runs Step 7 tag, Step 8 clear sentinels, Step 9 push and PR, Step 10 final gate. The tag is pushed with the branch. |
| ADR-004 | A sixth exception stop for unapproved dependencies | accepted | P1 or P2 adding a library or service that is missing from the approved list stops the run. It applies to both run modes. |
| ADR-005 | Roadmap driver child contract | accepted | The driver passes `--model` and `--max-turns`, writes `plan/.roadmap-logs/step-{position}.log`, and appends percent-encoded labels to `OTEL_RESOURCE_ATTRIBUTES`. |
| ADR-006 | Orchestrator references split | accepted | Rarely used orchestrator sections move word for word to `references/orchestrator-*.md`. A line-preservation test proves no rule was lost. |
| ADR-007 | Setup prunes retired hooks by list | accepted | Setup deletes an installed hook only if its name is on the retired list, which starts with `phase-enum`. |
| ADR-008 | Park refuses symlinked entry paths | accepted | Park refuses any symlink in the entry path, checking with `lstat` and real-path containment before it creates, writes, or removes. |

### Feature 0000160: ravintio-rebrand

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | The RAVINTIO rename map | accepted | Prose writes RAVINTIO in block capitals. Identifiers use lowercase `ravintio` and variables use `RAVINTIO_`. History folders stay as written. Supersedes 0000031 ADR-002 in part. |
| ADR-002 | Legacy aliases stay accepted through 1.x | accepted | Two roadmap variables and the em dash sentinel keep their earlier names as fallbacks. The new name wins. The fallbacks go at 2.0.0. |
| ADR-003 | Consumer migration 0004 | accepted | Bash and PowerShell helpers move the overrides folder and the workflow, remove old markers, move the old pack folder to `.ravintio-backup/` instead of deleting it, and archive 0004. A migration with a false `Applies when:` condition stays pending. Setup stops while an old folder remains. |
| ADR-004 | Brand guard test | accepted | A test fails on any tracked path or line outside history that holds the earlier product name, unless a path and line allowlist entry matches. A stale entry also fails. |
| 0000033 ADR-002 | 0000164 ADR-003 | Setup no longer removes legacy telemetry wiring. A pre-0000033 consumer removes it by hand. |
