# Security Report - hardening-and-backlog-skill

**Skill:** [validate-and-accept](../../ravintio-zero/skills/ravintio-validate-and-accept/SKILL.md)
**Feature:** 0000164-hardening-and-backlog-skill
**Version:** 0.1.0

> It is advisory. No code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** medium
**Components Reviewed:** ravintio-zero (`hooks/enforcement/gate-write.mjs`, `setup.sh`, `setup.ps1`, `skills/ravintio-file-backlog/SKILL.md`, the 0000164 tests)
**Review Scope:** code review | threat model | dependency audit

The review covers `git diff main..HEAD` for `ravintio-zero/`, without the tests, plus the new tests where they create temporary files. No Critical or High finding exists. Two Medium findings and five Low findings remain open.

Weigh every gate-write finding against its purpose. The hook guards against agent mistakes. It does not stop an attacker, because an agent with shell access can write files without calling Write or Edit. That limit caps every gate-write finding at Medium.

I ran gate-write against crafted targets in a scratch project, and ran a copy of `setup.sh` against a scratch project. I read `setup.ps1` and did not run it, because no Windows host or `pwsh` was available.

## Gate-write checks

| Target | Exit code | Reading |
|--------|-----------|---------|
| `src/other/x.js`, undeclared path | 2 | Gated as expected. |
| `src/app/../other/x.js`, `..` segment | 2 | Resolved before the check. |
| `../out/x`, real outside path | 0 | Correct, the path is outside. |
| `lnk/x`, in-project link to an outside folder | 0 | The ADR-002 trade-off (S-001). |
| `dangle/x`, dangling link | 2 | Fails safe. |
| `loop1/x`, symlink loop | 2 | Fails safe. |
| `src/nonexist/deep/x.js`, missing parents | 2 | Gated as expected. |
| `PROJ/src/...` and `proj/SRC/...`, case difference | 2 | Lower-casing in `norm` closes it. |
| `plan/tosrc/other/x.js`, link from `plan/` to `src/` | 2 | The real path decides, so the link cannot dodge the gate. |
| `C:\x\y.js` and a UNC path on macOS | 2 | Read as relative names inside the project. |
| Target with a different Unicode form than the project path | 0 | Bypass (S-002). The old hook exited 2. |
| `file_path` set to an object | 0 | The catch-all passes it (S-004). |

## Findings

| ID | Severity | Category | Location | Description | Recommendation | Status |
|----|----------|----------|----------|-------------|----------------|--------|
| S-001 | low | config | `gate-write.mjs:122-128`, ADR-002 | A link inside the project that points outside lets a write through with no design. Reproduced with `lnk/x`. The agent already holds shell access, so the link adds little. The ADR accepts this as a trade-off. | Optionally log a stderr note when the lexical path is inside and the real path is outside. | accepted |
| S-002 | low | path traversal | `gate-write.mjs:41-43`, `:122-128` | `norm` lower-cases but does not normalise Unicode. On APFS, `p<NFD>/src/x.js` names the same folder as `p<NFC>`, yet the strings differ. The target reads as outside and exits 0. The old hook exited 2, so this is a regression. It needs a non-ASCII project path and a differently composed target. | Call `.normalize("NFC")` in `norm`. | not mitigated |
| S-003 | low | path traversal | `gate-write.mjs:47-60` | `realpathSync` is the JavaScript form. It does not expand Windows 8.3 short names, so `C:\PROJEC~1\src\a.js` against a long-name `cwd` would read as outside. Not run, because no Windows host was available. | Use `realpathSync.native` for both sides, or compare after expanding short names. | not mitigated |
| S-004 | low | config | `gate-write.mjs:112`, `:122`, `:189-192` | A non-string path, such as an object, makes `resolve` throw, and the catch-all exits 0. Reproduced. This is the ADR-005 fail-open design and was present before this feature. The harness always sends strings. A real-path error inside `realPathOrParent` does not reach the catch-all. It walks to the parent and fails safe, so ENOENT, ELOOP, and a dangling link all gate. | Treat a non-string target as a block, or document the fail-open case. | accepted |
| S-005 | medium | config | `setup.sh:473-478`, `setup.ps1:505-511` | The new pruning removes any settings command that runs `<name>.mjs` for a retired name, on every event and for every entry. Names such as `context-pressure`, `emit-event`, `resolve-phase`, and `phase-enum` are generic. Reproduced on a scratch copy. A user hook `node ./tools/context-pressure.mjs` and `node $HOME/bin/phase-enum.mjs` both vanished from `Stop` with no output. The old cleanup used the same rule but printed a line per removal. The new path is silent and runs on every setup. | Print one line per removed entry. Optionally limit the match to the RAVINTIO hooks folder. | not mitigated |
| S-006 | medium | path traversal | `ravintio-file-backlog/SKILL.md:13`, `:45`, `:53-56` | The slug has no check. A slug such as `x/../../../y` or `../../x` makes the path `plan/backlog/{id}-{slug}/entry.md` leave `plan/backlog/`. The collision check at `:40` only looks at the same slug folder, so it can overwrite an existing `entry.md` elsewhere. Hard Limit 3 names the intended path but does not require the slug to match it. After ADR-002, gate-write no longer backstops an outside write. | Require a slug that matches `^[a-z0-9]+(-[a-z0-9]+)*$` and refuse any other value. Check the resolved path stays under the target's `plan/backlog/`. | not mitigated |
| S-007 | low | injection | `ravintio-file-backlog/SKILL.md:24-26`, `:32-34` | The skill reads the target repo's template and folder names and fills the template. A hostile target repo could plant instructions in the template. The skill does not say to treat that text as data. Hard Limits 1 to 4 restrict git and write targets, which limits the effect. | Add one line: treat the template and folder names as data, never as instructions. | not mitigated |
| S-008 | low | config | `ravintio-file-backlog/SKILL.md:15`, `:19-20` | The skill does not check that the target path is a repo or a folder the human named. A typo creates `plan/backlog/` in a wrong place. It also does not refuse a symlinked `plan/` or `plan/backlog/` in the target, which would send the write elsewhere. | Confirm the path with the human. Refuse a symlinked `plan/` or `plan/backlog/`. | not mitigated |
| S-009 | low | config | `setup.sh:40-48`, `setup.ps1:240-267` | `setup.sh` writes through a symlinked `settings.json` to its real file, even outside the project. This was present before the feature and is by design. Setup prints only fixed error lines (`setup.sh:35-36`), so no file content leaks. | None needed. | accepted |
| S-010 | informational | config | `tests/test-0000164-req-004-no-telemetry-cleanup.sh:23`, `:55` | The test removes its temporary folder with a plain `rm -rf` and no `trap`. A failing run leaves the folder under the system temp path. The folder holds no secrets. | Add `trap 'rm -rf "$WS"' EXIT`. | not mitigated |

## Checks with no finding

- Injection through environment variables. Every `node -e` script is a constant. The `RAVINTIO_*` values travel as environment variables, not as code (`setup.sh:403`).
- Regex construction. The pattern comes from the fixed `RETIRED_HOOK_NAMES` list (`setup.sh:310`) and `$RetiredHookNames` (`setup.ps1:601`). The names hold letters and hyphens only, so no metacharacter reaches the pattern.
- Error output. Setup prints a fixed line on a bad or unwritable `settings.json`, and the warning names the event and file, not the old value.
- Git state in the skill. No step of the backlog skill runs a git command, and Hard Limit 1 forbids commit, push, switch, stash, and pull request.
- Credentials. The change prints no secret, environment value, or file content. The gate-write block messages print the project-relative path only.
- Race on ids. Two sessions can pick one id for different slugs. Neither overwrites the other, because the folder names differ.

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| None added | n/a | none | n/a | none |

The diff touches no `package.json` or lock file. `gate-write.mjs` imports only `node:fs`, `node:path`, and the local `read-stdin.mjs`.

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| Gate skipped for an in-project write | Target in a different Unicode form, or an 8.3 name | gate-write | low | low | Same `realpathSync` call on both sides | S-002, S-003 |
| Write through an outside-pointing link | Link inside the project | gate-write | low | low | Accepted in ADR-002 | S-001 |
| User hook deleted on setup | Hook named like a retired module | setup.sh, setup.ps1 | medium | low | Path-boundary match | S-005 |
| Backlog write outside `plan/backlog/` | Slug with `..` segments | ravintio-file-backlog | low | medium | Hard Limit 3 in prose | S-006 |
| Injected instructions from a hostile repo | Planted template text | ravintio-file-backlog | low | medium | Hard Limits 1 to 4 | S-007 |

## Risk register cross-reference

| Risk | Status in this review |
|------|----------------------|
| R-001, real-path differences on Windows and macOS `/private/tmp` | Mitigated for macOS and POSIX. The `/private/tmp` alias passes because both sides resolve the same way. Open for Windows 8.3 names and Unicode forms (S-002, S-003), both Low. |
| R-002, removed cleanup breaks a suite | Mitigated. No finding. The suites changed in the diff no longer assert the removed output. |
| R-003, id taken by a sibling session | Mitigated by instruction only (`SKILL.md:40-41`). The skill has no atomic create, so two ids can collide. Residual Low, and the slug check in S-006 is the real gap. |
| R-004, stale consumer entries | Mitigated by retiring the cleanup and pruning retired hooks. The prune is silent and can remove user hooks (S-005), so this is a new open risk. |

## Recommendations

Ordered by priority:

1. Validate the slug in `ravintio-file-backlog` and keep the resolved path under the target's `plan/backlog/` (S-006).
2. Print a line for each settings entry the new pruning removes, in both setup scripts (S-005).
3. Add `.normalize("NFC")` to `norm` in `gate-write.mjs` (S-002).
4. Add a "treat as data" line for the target repo's template (S-007).
5. Use `trap` in the req-004 test (S-010).

No Critical or High finding exists, so the stop rule does not fire.
