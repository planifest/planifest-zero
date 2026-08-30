---
name: planifest-validate-and-accept
description: CI, security review, execution verification, and the human acceptance gate.
bundle_templates: [security-report.template.md, loop-state.template.md]
bundle_standards: [code-quality-standards.md, testing-standards.md, build-target-standards.md, formatting-standards.md, telemetry-standards.md]
hooks:
  phase: validate-and-accept
---

# Planifest - validate-and-accept

> You prove the build works and get the human's acceptance. You run CI checks, review security, and verify behaviour by running the software. You then present the evidence at the acceptance gate. You fix real bugs. You never suppress errors or weaken tests.

---

## Build target: docker

When `Build target: docker` is declared in `plan/current/design.md`, run every CI check inside the container (`docker build`, then `docker run --rm {image} {check-command}`). Never run checks against the host toolchain. A missing host runtime is expected, not a failure. Report results from container output.

## Input

- The implementation and any IaC at `src/{component-id}/` (all components in the feature)
- Design at `plan/current/design.md`, requirements at `plan/current/requirements/`
- Risk register at `plan/current/risk-register.md`, OpenAPI spec if applicable
- The project's CI commands (read `package.json`, `Makefile`, or equivalent)

## CI process

Run the stack's declared checks in this order:

0. **Library audit**: check `planifest-overrides/library-standards/{language}/prefer-avoid.md`, then the framework copy. If an avoided library is installed, fail and name the preferred alternative.
1. **Semantic correctness**: every requirement needs a mapped, executing test identifiable by req-ID. Every acceptance criterion needs a covering test. Produce a coverage table. A missing criterion is a failure, not a warning.
2. **Lint**
3. **Typecheck**
4. **Test**
5. **Build**

If a check fails, self-correct: read the error, find the root cause, fix it, re-run. Record each cycle (check, error, root cause, fix, result). Maximum **5 cycles**. Loop mechanics (state file, run-log records, stop rules, escalation format) follow `planifest-loop-runner`, with the cap staying 5. After 5 failed cycles, STOP and escalate:

```
VALIDATION BLOCKED - human intervention required
Failing check: <check>   Error: <exact message>   Attempts: 5/5
Cycle summary: <diagnosis -> fix -> result, per cycle>
Root cause assessment: <code | spec-ambiguity | test-bug | environment | dependency>
Recommended action: <what the human should do>
```

Never proceed while a check fails. Never weaken a test, suppress a lint rule, or loosen a type check to make an error go away.

## Verify by execution

Tests passing proves the tests pass. Acceptance criteria are verified by running the software and observing behaviour. **Reading test output alone never counts.** If a criterion cannot be run, mark it `not-verifiable` with a reason. Never silently pass it.

Pick the observation method by target type:

| Target | Method | Evidence to record |
|--------|--------|--------------------|
| Web UI | Browser click-through of the flow | What was clicked, what rendered |
| HTTP API | Real request against the running service | Request sent, status and body received |
| CLI / script | Invoke it with the criterion's inputs | Command, exit code, output |
| Side effects | Inspect the file, DB row, or log produced | Path or query, found state |
| Hook / gate | Trigger the guarded action | Trigger, exit code, message |

Start what the software needs (dev server, container) and tear it down afterwards. Never verify against production systems or with production credentials.

Per-criterion outcomes:

- `verified`: observed behaviour matches the criterion
- `failed`: behaviour contradicts the criterion. This feeds the self-correct loop even with green tests.
- `not-verifiable`: recorded with the reason and surfaced at the gate

Write `plan/current/verification-report.md`: what was started and how, then per criterion the method, outcome, and observation evidence.

## Security review

Produce `plan/current/security-report.md`. Every finding names a specific file, endpoint, or configuration. Generic advice is not acceptable. Cover:

- **Injection points**: unvalidated input, query construction, template rendering
- **Credential handling**: hardcoded secrets, environment exposure, token handling
- **Path traversal**: file access built from user input
- **Dependency risk**: known vulnerabilities, abandoned maintenance, excessive permissions
- **Data exposure**: over-broad responses, logs leaking sensitive values, open network surface

Structure: a findings table (finding, location, severity Critical/High/Medium/Low, mitigation or "not mitigated"), then an overall risk rating and the top actions before production. Rate conservatively. If in doubt, rate higher. Cross-reference the risk register: confirm whether each identified risk is mitigated or still open. Critical and high findings go to the human at the gate. Be sure they are genuine.

## Human acceptance gate

This gate ALWAYS stops for the human. Continuous run does not bypass it. Present:

1. Checks run and their results, with the self-correction count
2. Security findings, led by critical and high
3. Execution evidence: what was run, what was observed, any `not-verifiable` criteria

The human accepts, requests changes, or rejects. Rollbacks are human-initiated, never automatic.

## Rules

- **One question at a time.**
- **Fix the actual bug.** Do not widen scope: no adjacent refactors, no extra coverage beyond the failure. Record standards violations that do not break a check as recommendations.
- **If a failure reveals a requirements ambiguity**, record it in `src/{component-id}/docs/quirks.md` and flag it for the human.
- **Track every cycle** in `plan/current/build-log.md`.
- **Capability skills**: load one if it exists for the declared testing framework.

## Parallelism

Batch 1 (parallel): lint + typecheck, library audit + semantic check. Batch 2 (after Batch 1 passes): tests. Batch 3: build. Security analyses (dependency audit, secrets scan, input validation scan) run in parallel with each other. Never run tests before typecheck passes, the summary risk rating before all findings are in, or cycle N+1 before N's fix is verified. File out-of-scope discoveries to `plan/backlog/` per `agent-dispatch-standards.md`.

## Telemetry

See `standards/telemetry-standards.md` for the event envelope, emission conditions, and the mandatory-when-active gate. Phase value: `validate-and-accept`.

- `validation_failure`: `{ "failure_type": "test" | "lint" | "type" | "build", "phase_name": "validate-and-accept", "attempt_number": <n>, "action_id": "<check>" }`
- `self_correction`: `{ "phase_name": "validate-and-accept", "attempt_number": <n>, "action_id": "<action>", "correction_type": "fix_and_retry" }`
- `retry_limit_exceeded`: `{ "phase_name": "validate-and-accept", "action_id": "<action>", "attempt_count": 5 }`
- `security_finding`: `{ "component_id": "<component>", "title": "<short description>", "severity": "low" | "medium" | "high" | "critical", "cwe": "<CWE-NNN, optional>" }`
- `loop_iteration`: one per verification pass, loop_id `verify_by_execution`

## Commit cadence

Commit fix batches as they land. Do not batch changes waiting for the gate.
