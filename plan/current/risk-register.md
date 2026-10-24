---
title: "Risk Register - hardening-and-backlog-skill"
summary: "Technical and operational risks for the gate-write fix, the test loops, the telemetry cleanup retirement, and the backlog-filing skill."
status: "draft"
version: "0.1.0"
---
# Risk Register - hardening-and-backlog-skill

**Skill:** plan
**Feature:** 0000164-hardening-and-backlog-skill
**Version:** 0.1.0
**Overall Risk Level:** high

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | Real-path resolution differs on Windows and on macOS `/private/tmp`. An in-project write reads as outside the project and skips the gate. | medium | high | Resolve both the project root and the target with the same call. Test on all three CI hosts. | open |
| R-002 | technical | Removing the telemetry cleanup breaks a suite that asserts its output. | high | low | List every telemetry-mentioning suite in P1. Update or delete each one. | open |
| R-003 | technical | The backlog-filing skill picks an id that a sibling session takes at the same time. | low | low | Refuse to overwrite an existing folder. Take the next free id. | open |
| R-004 | operational | No live consumer still carries pre-0000033 telemetry wiring. If this is wrong, stale settings entries stay in a consumer repo until the consumer removes them by hand. | medium | low | The changelog states that consumers with leftover entries remove them by hand. | open |

## Assumptions Logged as Risks

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | No live consumer still carries pre-0000033 telemetry wiring. Tracked as R-004. | Stale settings entries stay until the consumer removes them by hand. The changelog says so. | open |
