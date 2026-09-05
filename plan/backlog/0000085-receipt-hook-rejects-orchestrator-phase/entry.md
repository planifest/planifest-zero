---
title: "Backlog Entry: 0000085 - the receipt hook rejects the orchestrator phase name"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000085 - the receipt hook rejects the orchestrator phase name

**Source feature:** 0000032-relocate-setup-config-to-plan-state
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-05

---

## Problem

`telemetry-standards.md` tells agent-driven `spec_gap` emission to send
`"phase_name": "orchestrator"`. The `emit-event-receipt.mjs` hook validates
every `emit_event` envelope against the shared phase enum before it writes a
receipt, and that enum has no `orchestrator` value. The hook throws
`emit_event envelope has unrecognised phase="orchestrator" or event="deviation"`
and writes a failure marker instead of a receipt.

The previous run (0000031, 2026-08-30) tripped this five times. The events
most likely reached the backend, because the hook runs after the MCP call
succeeds. The missing receipt then makes `check-telemetry-receipts.mjs` report
a gap that isn't one. Every fresh P0 also has to surface the marker and ask the
human a block-or-proceed question about a defect in the framework's own
contract.

Two candidate causes, both in the framework's own files:

- The standards doc and the hook disagree on whether `orchestrator` is a
  valid phase for agent-driven events.
- The standards snippet uses the key `phase_name` while the hook reads
  `envelope.phase`. One of the two is wrong.

## Suggested Action

Decide whether `orchestrator` belongs in the shared phase enum or whether
orchestrator-emitted events should carry the active pipeline phase instead.
Align `telemetry-standards.md`, the phase enum module, and the receipt hook to
that decision, and add a test that emits a `spec_gap` envelope and expects a
receipt.

## Why Deferred

Out of scope for 0000032, which relocates the setup-config record. Fixing this
needs a decision about the telemetry contract, so it is a design change rather
than a patch.
