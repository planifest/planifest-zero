# Planifest Tests

This directory holds the framework's own test suite. The suites are Bash
scripts, they run on macOS, Linux, and WSL, and they cover the Claude Code
target only.

## Layout

| Path | Contents |
|------|----------|
| `test-*.sh` | Per-feature test suites |
| `helpers/` | Shared assertions (`assert.sh`) and the controllable telemetry backend |
| `regression/` | The long-term regression pack and its manifest |
| `run-tests.sh` | The runner |

## Running the tests

```bash
bash planifest-zero/tests/run-tests.sh
```

The runner discovers every `test-*.sh` in this directory by glob. No suite is
registered by hand. Add a conforming file and it runs on the next invocation.
After the per-feature suites, the runner executes every `test-*.sh` under
`regression/` and reports the two sets separately.

You can also run a single suite directly:

```bash
bash planifest-zero/tests/test-commit-msg-hook.sh
```

Suites create their own temporary workspaces where they need isolation and
clean up after themselves, so a run leaves your working tree unaffected.

## The regression pack

`regression/` holds suites promoted from completed feature runs, so behaviour
proven in one feature stays covered in every later one.

`regression/regression-manifest.json` records each promoted test: its source
feature, promotion date, and promoter. `scripts/promote-to-regression.sh`
manages the manifest. Do not edit it by hand.

## Adding a test

1. Name the file `test-{feature-id}-{description}.sh` and put it in this
   directory.
2. Source `helpers/assert.sh` for the shared assertion functions.
3. Exit non-zero on failure. The runner counts a suite as failed on any
   non-zero exit.

The runner picks the file up automatically. Nothing else needs registering.

## Manual verification (setup.ps1)

No PowerShell runner exists in CI (backlog 0000084), so `setup.ps1` suites such
as `test-0000032-req-002-powershell-write-to-plan-state.sh` assert statically
against the script's source. A person with `pwsh` installed confirms the
runtime behaviour by hand:

1. Run `pwsh ./planifest-zero/setup.ps1 claude-code` from the repository root.
2. Check that `plan/state/claude-code.md` exists and its `tool` field reads
   `claude-code`.
3. Confirm the run printed a line naming `plan/state/claude-code.md`.
4. Run the same command again.
5. Diff the file against its previous content. Only the `writtenAt` field
   changes between the two runs.
