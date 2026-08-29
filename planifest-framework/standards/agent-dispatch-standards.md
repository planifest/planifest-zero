---
title: "Agent Dispatch Standards"
version: "1.0.0"
---
# Agent Dispatch Standards

Canonical home for model tier selection and parallelism/dispatch mechanics, shared by the orchestrator and every phase skill that spawns subagents.

---

## Model Tier Decision Table

**Consult this table before spawning every subagent.** Resolve the tier to a concrete model name for the active tool, then pass it explicitly.

| Task type | Tier | Rationale |
|-----------|------|-----------|
| Codebase discovery (grep, find, ls, file listing) | Cheaper | No synthesis required |
| Single-file read with no synthesis | Cheaper | Mechanical retrieval |
| Formatting / spelling / lint checks | Cheaper | Pattern matching, no reasoning |
| Validation (lint, typecheck, test runner) | Cheaper | Tool execution, not reasoning |
| Web research: fetching a single known reference doc | Cheaper | Retrieval, minimal synthesis |
| Documentation writing (no novel decisions) | Cheaper | Structured output from known inputs |
| Web research with synthesis across multiple sources | Primary | Reasoning across conflicting sources |
| Code generation | Primary | Multi-file reasoning, correctness required |
| Security review | Primary | Adversarial reasoning, high-stakes |
| Architecture decisions (ADR writing) | Primary | Consequential, requires judgement |
| Requirements writing (spec) | Primary | Ambiguity resolution, domain reasoning |
| Phase 0 coaching | Primary | Dialogue, gap assessment |
| Build assessment (P8) | Cheaper | Read-only summarisation from a structured log |

**Tier-to-model mapping by tool** (update when tools release new models):

| Tool | Primary tier | Cheaper tier |
|------|-------------|-------------|
| Claude Code | claude-sonnet-4-6 (or latest Sonnet) | claude-haiku-4-5 (or latest Haiku) |

**How to apply:** Before calling `Agent(...)`, look up the task in the table. Pass `model: {resolved model name}` as a parameter. Record the tier in the build log for P8.

---

## Parallelism Rules

**Default posture: parallel.** Sequential dispatch requires an explicit dependency justification. **Dependency test:** can task B start before task A's output is available? If you cannot state why it must wait, dispatch both in parallel (single message, multiple Agent tool calls).

### MUST parallelise

| Pattern | Example |
|---------|---------|
| Multiple independent codebase searches | Grepping for hook files + scanning skill dirs simultaneously |
| Web research across independent sources | Two vendors' hook documentation, same question, different sources |
| Independent document reads | Reading 3 skill files that do not reference each other |
| Background test runner while writing docs | Run `run-tests.sh` in background while docs-agent produces output |
| Multi-component security reviews (no shared state) | Reviewing component A and component B in parallel |
| Independent requirement files (no cross-references) | Writing req-001 through req-008 in a single parallel batch |
| Independent new test files closing a coverage gap | 2+ new test files, each testing independent, non-cross-referencing sections, dispatched in a single parallel batch instead of written one after another |
| Independent living-doc edits (no shared content) | 2+ living docs (e.g. component-registry.md, decisions-index.md) that don't read each other's new content, edited in a single parallel batch instead of serially |

### Cannot parallelise

| Pattern | Reason |
|---------|--------|
| Phase N work before Phase N-1 artifacts exist | Hard phase dependency |
| ADR writing before requirements are complete | ADR content depends on spec output |
| Codegen before ADRs are accepted | ADRs may constrain implementation choices |
| P8 before P7 archive is confirmed | Report needs the archive path |
| Tasks where B reads A's output | Sequential by definition |

**Record in build log:** After each phase, record the parallel task batch count. If it is 0 for a phase where parallelism was possible, the P8 efficiency observation will flag it.

---

## Agent Dispatch Template

Agent spawning is level-2 parallelism (the Agent tool for independent sub-tasks that each need their own tool access and context); level-1 (multiple native tool calls in one message) is covered by Parallelism Rules above. Spawn when a task is self-contained enough to brief to a colleague in one paragraph; stay inline when it needs ongoing dialogue, shared mutable state, or is too small to justify the overhead.

**Concrete parallel dispatch skeleton** (send both `Agent()` calls in a single message so they execute concurrently):

```
Agent({ description: "Implement REQ-001: {one-liner}", subagent_type: "general-purpose", model: "claude-haiku-4-5",
  prompt: "Requirement: plan/current/requirements/req-001-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-1}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Confirm: files modified, what changed." })

Agent({ description: "Implement REQ-002: {one-liner}", subagent_type: "general-purpose", model: "claude-haiku-4-5",
  prompt: "Requirement: plan/current/requirements/req-002-{slug}.md. ADR: plan/current/adr/ADR-00N-{slug}.md. Stack: {constraint}. Task: {what to build}. If you discover an out-of-scope bug/gap, file it at plan/backlog/{backlog-id-2}-{slug}/entry.md per templates/backlog-entry.template.md; do not report it back for me to relay. Confirm: files modified, what changed." })
```

**Self-contained prompt rule:** include the requirement file path, relevant ADR paths, stack declaration or relevant constraint, the backlog ID to use if filing an out-of-scope discovery, and what "done" looks like. Do NOT rely on shared conversation history: the spawned agent has no memory of this session.

**Model tier for spawned agents:** see the Model Tier Decision Table above.

**Out-of-scope discovery filing (0000027-req-003):** if a dispatched subagent discovers an out-of-scope bug or gap while doing its task, it MUST file `plan/backlog/{id}-{slug}/entry.md` directly, per `templates/backlog-entry.template.md`, with `Deferral source: discovered mid-flight`, `Source feature` set to the active feature ID, and `Source phase` set to the phase active at discovery. It must NOT report the discovery back for the dispatching agent to relay through a host-tool side channel (e.g. a task-spawning tool), and must NOT silently drop it.

The **dispatching agent** (orchestrator or phase skill placing the `Agent()` call) pre-computes the next available backlog ID before dispatch, per the Backlog ID sequence convention (`planifest-orchestrator/SKILL.md` Phase 0 Start Actions, backlog pickup step: highest ID ever allocated, including picked-up and discarded entries, plus one), and passes it explicitly in the subagent's prompt as the ID to use if a discovery needs filing. Subagent self-lookup of `plan/backlog/` at file-time is rejected: picked-up entries are deleted from `plan/backlog/` once folded into a design, so a subagent scanning only that directory would systematically undercount the true high-water mark and risk reusing a retired ID.

When dispatching multiple subagents in a single parallel batch, each MUST receive a distinct pre-assigned backlog ID (or a reserved contiguous block, one per subagent); no two subagents may independently file under the same ID.
