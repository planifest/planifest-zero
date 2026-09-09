---
title: "Backlog Entry: 0000087 - refresh-setup validates record flags against an allowlist"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000087 - refresh-setup validates record flags against an allowlist

**Source feature:** 0000032-relocate-setup-config-to-plan-state
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-09

---

## Problem

`planifest-zero/skills/planifest-refresh-setup/SKILL.md` Step 3 sub-step 1 reads
`plan/state/{tool}.md`, a git-tracked file, and copies its `flags` and `backendUrl`
into the `setup.sh {tool} {flags...}` command built in sub-step 4 and run in Step 7.
Validation checks only that the JSON parses, the four fields exist, and `tool` matches.
Nothing constrains `flags` to the two flags `setup.sh` accepts, or `backendUrl` to the
http(s) shape `setup.sh` line 1097 enforces. A hostile or careless commit can place
shell metacharacters or extra arguments in either field. `setup.sh` rejects unknown
flags, but the shell parses metacharacters before `setup.sh` runs. The Step 4 human
confirmation is the only barrier. ADR-002 for 0000032 states the input must be
validated because it is injected into a command. Recorded as finding S-001 in
`plan/current/security-report.md`.

## Suggested Action

Add two rules to Step 3 sub-step 1: every `flags` entry must be one of
`--structured-telemetry-mcp` or `--strict-orchestrator`, and `backendUrl` must be
`null` or match `^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._/-]*)?$`. Any other
value makes the record invalid and triggers the existing fallback. Extend
`test-0000032-req-004-refresh-setup-reads-record-first.sh` to assert both rules.

## Why Deferred

req-004's Input Validation section asks only for parse-or-reject, so the implementation
matches its spec. Tightening it changes the requirement and its acceptance criteria,
which needs a human decision rather than a P5 edit.
