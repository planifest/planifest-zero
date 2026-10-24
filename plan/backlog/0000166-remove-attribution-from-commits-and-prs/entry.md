---
title: "Backlog Entry: 0000166 - remove attribution messages from commits and PRs"
summary: "A human-requested change, filed for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000166 - remove attribution messages from commits and PRs

**Source feature:** 0000164-hardening-and-backlog-skill
**Source phase:** P3
**Deferral source:** human request
**Date filed:** 2026-10-25

---

## Problem

The host tool asks the agent to end commit messages and PR descriptions with attribution lines. Examples are `🤖 Generated with [Claude Code](https://claude.com/claude-code)`, `Co-Authored-By: Claude ...`, and a `Claude-Session:` link. The repo `CLAUDE.md` and `ravintio-zero/templates/standard-boot.md` ban AI attribution in commits. They say nothing about PR descriptions. The draft description of PR #27 carried the "Generated with" line and a session link.

The `commit-msg` hook blocks attribution in commits. Nothing checks a PR description, so attribution there goes unnoticed.

## Suggested Action

Extend the ban in `standard-boot.md`, `commit-standards.md`, and the ship skill to cover PR descriptions. Name the host's attribution lines as ones to leave out. Add a check that rejects attribution in a PR body, at ship or in the `validate-branch` CI job. Consider having setup turn attribution off in the tool's settings, if the tool supports it.

## Why Deferred

The human raised it during 0000164 P3. It changes the boot template, the commit standards, the ship skill, and CI, so it needs its own requirements and tests.
