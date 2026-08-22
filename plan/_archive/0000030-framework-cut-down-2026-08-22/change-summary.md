# Change Summary

Change request: Cut this repo down to a Claude Code only framework. Delete the accumulated plan and docs history, the two `src/` components, all non-Claude tool support, every element of context-mode, and the vendored external skill library. Rewrite `README.md` and `product.yml`, and reset the version to 0.1.0.

Interpretation: A file-removal build with three documentation rewrites. No behaviour is added. The narrowest reading of "remove all elements of context-mode" is taken to mean the hooks, the `--context-mode-mcp` flag and its branches in both setup scripts, the tests, and every doc reference. The `context-pressure` telemetry hook shares a name prefix but is unrelated, so it stays.

Components affected: `planifest-framework` (modified), `context-mode-hooks` (deleted), `setup-hook-integration` (deleted)

Contract changed: yes. `setup.sh` and `setup.ps1` lose the `--context-mode-mcp` flag and eight of nine tool targets. An ADR is required.

Schema changed: no

Migration proposed: no

Consumers affected: none known. No repo outside this one is recorded as installing from this source tree.

Blast radius:
- `planifest-framework`: Direct. Loses `external-skills/`, `hooks/context-mode/`, `hooks/adapters/` (all six are non-Claude), eight tool setup scripts, `tool-setup-reference.md`, `templates/cursor-boot.md`, and the context-mode branches in `setup.sh` and `setup.ps1`.
- `context-mode-hooks`: Direct. Deleted outright. Its three hooks were already orphaned when commit 6a50af1 dropped context-mode from the boot templates.
- `setup-hook-integration`: Direct. Deleted outright. Its `src/` tree documented `setup.sh` and `setup.ps1`, which live in `planifest-framework/` and survive.
- Claude Code runtime: Indirect. The enforcement and telemetry hooks stay wired and unchanged. Only the context-mode PreToolUse entries disappear, and those install only under a flag that is being removed.
- context-mode MCP server (external): None. This repo never shipped it. Deleting the hooks removes the only edge pointing at it.
