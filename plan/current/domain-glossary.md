---
title: "Domain Glossary - hardening-and-backlog-skill"
summary: "Definitions of the terms used in the gate-write fix, the telemetry cleanup retirement, and the backlog-filing skill."
status: "draft"
version: "0.1.0"
---
# Domain Glossary - hardening-and-backlog-skill

**Skill:** plan
**Feature:** 0000164-hardening-and-backlog-skill
**Version:** 0.1.0

> The ubiquitous language for this feature. If the glossary says "Target repo", the code says `target repo`. Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Always-permitted path | A path that `gate-write` allows without a confirmed design. It covers paths under `plan/` and `docs/`, and it names `plan/backlog/` and `plan/roadmap/` explicitly. | Allowed path | ravintio-zero |
| Orchestrator sentinel | The marker file `plan/.orchestrator-active`. The auto-trigger hook loads the orchestrator skill only while this file is absent. | Orchestrator marker | ravintio-zero |
| Component paths | The paths that this feature's components own: `ravintio-zero/`, `.claude/`, `.github/`, `scripts/`, `CLAUDE.md`, `README.md`, and `product.yml`. | None | ravintio-zero |
| Real path | The absolute path with symlinks resolved. `gate-write` compares real paths. For a file that does not exist yet, it uses the nearest existing parent. | Resolved path, canonical path | ravintio-zero |
| Retired-hooks list | The `RETIRED_HOOK_NAMES` array in `setup.sh` and the `$RetiredHookNames` array in `setup.ps1`. Setup prunes the hook entries that it names. | Retired hook names | ravintio-zero |
| Legacy telemetry wiring | Telemetry hook entries that pack versions before 0000033 left in a consumer repo. Setup removed them before 1.1.0. From 1.1.0, setup no longer removes them. | None | ravintio-zero |
| Backlog entry | A folder `plan/backlog/{id}-{slug}/` that holds one `entry.md`. It records an out-of-scope item for a later discovery run. | Backlog item | ravintio-zero |
| Backlog id high-water mark | The highest backlog id ever allocated in a repo, including picked-up and discarded entries. The next id is this value plus one. | Id high-water mark | ravintio-zero |
| Target repo | The other repo where the backlog-filing skill writes one uncommitted backlog entry folder. The skill never commits, pushes, switches branches, or opens a PR in it. | Other repo | ravintio-zero |
