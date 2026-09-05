---
title: "Requirement: req-004 - refresh-setup-reads-record-first"
summary: "Detailed requirements for this specific functional feature."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - refresh-setup-reads-record-first

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-relocate-setup-config-to-plan-state
**Source:** US-001
**Priority:** must-have

## User Story

As a maintainer refreshing a Planifest install, I want `planifest-refresh-setup` to read
the relocated record first, so that the flags it proposes come from the most reliable
source available.

## Functional Requirements
- `planifest-refresh-setup` Step 3 reads `plan/state/{tool}.md` before the
  `{tool-dir}/.planifest-setup-flags` marker and before hook-wiring inference.
- The record is valid when it is a well-formed ```json block containing `tool`, `flags`,
  `backendUrl`, and `writtenAt`, and the `tool` field matches the tool the skill is
  targeting.
- When the record is valid, the skill reports every flag it holds at high confidence,
  source: `plan/state/{tool}.md`.
- When `plan/state/{tool}.md` is missing, unreadable, or fails validation (malformed JSON,
  a missing required field, or a `tool` field that does not match the target), the skill
  falls back to the existing Step 3 order: the marker file, then hook-wiring inference.
- The skill's Step 4 confirmation report states which source (the record, the marker, or
  inference) supplied the proposed flags.

## Acceptance Criteria
- [ ] With a valid `plan/state/claude-code.md` present, Step 3 reports every flag and the backend URL at high confidence with source `plan/state/claude-code.md`, and does not consult the marker file.
- [ ] With the record absent, unreadable, containing invalid JSON, missing the `flags` field, or naming a different `tool`, Step 3 treats it as missing and falls back to the marker file then hook inference without stopping the skill run.
- [ ] The Step 4 confirmation names the source used for each flag: the record, the marker file, or hook inference.

## Dependencies
- req-001

## Input Validation

- [ ] Input source: filesystem path `plan/state/{tool}.md`
- [ ] Allowed character pattern: the file must parse as well-formed JSON inside a fenced
  ```json block; content that does not parse is rejected, not sanitised
- [ ] maximum length: no explicit limit; a record exceeding typical file-read limits is
  treated as unreadable
- [ ] Failure behaviour: treat the record as missing and fall back to the marker file, then
  hook inference, continuing the skill run
- [ ] Logging policy: report the source used (record, marker, or inference) to the human;
  do not log the raw file content beyond the confirmed flags and backend URL already shown
  in Step 4
