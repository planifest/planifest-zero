---
title: "Build Log - {{feature-id}}"
summary: "Working telemetry file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - {{feature-id}}

> Created at discovery (P1). Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `{{feature-id}}` |
| Pipeline start | `{{start-timestamp}}` |
| Tool | `{{tool-name}}` |
| Primary model | `{{primary-model-name}}` |
| Cheaper model | `{{cheaper-model-name}}` |

---

## Phase Log

### P1: Discovery

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| Model tier | primary / cheaper |
| Skills loaded | planifest-orchestrator |
| Agents spawned | `{{count}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| Telemetry | emitted / failed-with-recorded-choice / confirmed-disabled |
| Notes | `{{free text or "none"}}` |

---

<!-- Copy and fill in this block at each phase boundary. Headings use the form
     "### P<n>: {Phase Name}" with n from 2 to 5 and the phase names
     P2: Plan, P3: Implement, P4: Validate and Accept, P5: Ship.

### P<n>: {Phase Name}

| Field | Value |
|-------|-------|
| Start | `{{timestamp}}` |
| Model tier | primary / cheaper |
| Skills loaded | `{{skill names}}` |
| Agents spawned | `{{count}}` |
| MCP calls | `{{count}}` |
| Parallel task batches | `{{count}}` |
| Telemetry | emitted / failed-with-recorded-choice / confirmed-disabled |
| Notes | `{{free text or "none"}}` |

-->

---

## Summary (filled at ship, P5)

| Metric | Value |
|--------|-------|
| Total phases completed | `{{count}}` |
| Total agents spawned | `{{count}}` |
| Total MCP calls | `{{count}}` |
| Phases using parallelism | `{{count}}` |
| Primary tier agent calls | `{{count}}` |
| Cheaper tier agent calls | `{{count}}` |
| Self-corrections | `{{count}}` |
| Phases skipped | `{{list or "none"}}` |
| Phases with a recorded telemetry gap | `{{count, phases where Telemetry was failed-with-recorded-choice, or "0"}}` |
