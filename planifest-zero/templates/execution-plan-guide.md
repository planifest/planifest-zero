# Execution Plan - Guide

> How the plan phase produces requirements, and how to read one.

*Related: [Plan Skill](../skills/planifest-plan/SKILL.md) | [Feature Brief Guide](feature-brief-guide.md)*

---

## Purpose

The Execution Plan translates the Feature Brief into **specific, testable requirements**. It is the contract between what the human asked for and what the implement phase will build. Every requirement traces back to a user story or acceptance criterion - if it doesn't trace, it shouldn't exist.

---

## Who Writes It

The **plan skill** produces this document during the plan phase (P2). It reads the confirmed design and the original Feature Brief as input. It does not invent requirements - it derives them.

---

## When It's Produced

- **After** the orchestrator confirms the design (end of discovery)
- **Before** ADRs are written (they read it as input)
- **One per feature**, or one per wave if the feature is waved (`execution-plan-wave-2.md`)

---

## Section-by-Section Guidance

### Functional Requirements

Each requirement must be:
- **Specific** - one behaviour, not a category
- **Testable** - you can write a test case from the requirement alone
- **Traceable** - sourced from a user story or acceptance criterion in the brief

| Bad | Good |
|--------|---------|
| "The system should handle authentication" | "FR-001: The system shall accept a POST to /api/v1/auth/login with email and password, returning a JWT access token (15min TTL) and refresh token (7d TTL)" |
| "Users can manage their profile" | "FR-003: The system shall accept a PATCH to /api/v1/users/:id with partial profile fields, returning the updated user object" |

### Non-Functional Requirements

Same rule - measurable targets only. These are derived from the NFR section of the Feature Brief, not invented.

### API Summary

A quick-reference table. The full contract is in `openapi-spec.yaml` - this table is for humans scanning the requirements set.

### Data Model Summary

Entities, their owner components, and relationships. This feeds into the data contract and the ADRs.

### Open Questions

Material gaps the plan skill could not resolve from the brief. These are **not** filled by assumption - they're reported to the orchestrator, which surfaces them to the human.

---

## Common Mistakes

1. **Inventing requirements.** The requirements set derives from the brief. If the brief didn't ask for email notifications, its requirements set doesn't add them.
2. **Vague requirements.** "The system should be secure" is not a requirement. What authentication? What authorization? What data classification?
3. **Missing traceability.** Every FR and NFR must have a Source column pointing to the brief. If it can't be traced, it shouldn't be there.
4. **Mixing concerns.** Functional requirements describe WHAT. Architecture decisions (HOW) belong in ADRs.

---

## How It Connects

```
Feature Brief -> Execution Plan -> ADRs -> Code
              -> OpenAPI Spec (if API)
              -> Data Model -> Data Contract
```

The execution plan is the central artifact. ADRs explain HOW to implement the requirements. The implement phase reads both.

---

## File Location

`plan/current/execution-plan.md`

If waved: `plan/execution-plan-wave-{n}.md`

---

*Template: [execution-plan.template.md](execution-plan.template.md)*

