---
title: "Skill Consolidation Map - 0000031"
summary: "Section-to-destination map for the 21-to-12 skill merge. Implement builds from this. Validate audits against it."
status: "active"
version: "0.2.0"
---
# Skill Consolidation Map

Destination skills after the merge: planifest-orchestrator (rewritten), planifest-plan, planifest-implement, planifest-validate-and-accept, planifest-ship, planifest-test-writer, planifest-implementer, planifest-refactor, planifest-loop-runner, planifest-optimise-agent, planifest-migrator, planifest-refresh-setup.

The five phases are discovery, plan, implement, validate-and-accept, and ship.

## planifest-orchestrator -> planifest-orchestrator (rewritten)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | orchestrator / Hard Limits | rewrite, limit 9 ("exactly 10 phases, P0-P9") becomes "exactly 5 phases", all other limits carry over verbatim |
| ## Response Prefix Convention | orchestrator / Response Prefix Convention | rewrite, five prefixes replace eleven, PC prefix dropped with the change route |
| ## Resume Detection | orchestrator / Resume Detection | rewrite, keep migration scan, framework-update detection, sentinel cleanup, pause and run-mode restore, renumber the interrupted-P9 case to the ship phase |
| ## Framework Index (JIT Loading) | orchestrator / Framework Index | rewrite, drop the design-critic, reversal-assessor, and scope-lock-agent spawn rows, keep template and loop-runner rows |
| ## Routing Directive | orchestrator / Routing | rewrite, single route replaces the three-track tree, keep the standalone-skills table (test-writer, implementer, refactor, optimise), Fast Path and Change Pipeline routing dropped |
| ## Phase Skip Protocol | orchestrator / Phase Skip Protocol | merge, .skips mechanics unchanged, renumber phase names |
| ## Pause Command | orchestrator / Pause Command | merge, unchanged |
| ## Context Hygiene | orchestrator / Context Hygiene | merge, bookend points become discovery start and ship completion |
| ## Phase 0 - Assess and Coach | orchestrator / Discovery phase | rewrite, coaching method, priority order, decomposition, waves, start actions (sentinel, build log, repo instructions, adoption mode, version read, backlog pickup, discovery.md, skill map, strict-mode ack, skills inbox) all carry over under the discovery name |
| ### Capability Skills | orchestrator / Capability Skills | merge, intake procedure and skill-scope test unchanged |
| ### Scope Lock Challenge | orchestrator / Scope Lock Challenge | rewrite, orchestrator drafts the four scenario answers inline, no subagent dispatch, ⚠ RULE: per-item explicit human accept, edit, or reject remains the only thing that counts as confirmation, with immediate per-item build-log capture |
| ### P0 Audit Trail | orchestrator / Discovery audit trail | merge, incremental per-exchange build-log entries unchanged |
| ### Phase 0 -> Phase 1 Gate Checklist | orchestrator / Discovery gate checklist | rewrite, checklist items carry over, P0 completeness loop toggle retained via loop-runner |
| ## Phase Conventions (P1-P7) | orchestrator / Phase conventions | rewrite, build-log-first, load-skill-before-acting, and commit rules carry, per-phase STOP gates collapse into the single-gate model |
| ## Phase Invocation Table (P1-P6) | orchestrator / Phase invocation table | rewrite, six rows collapse to plan, implement, and validate-and-accept rows, gate conditions merge per destination skill |
| ## Phase 1 - Requirements | orchestrator / Plan phase | rewrite, invokes planifest-plan |
| ## Phase 2 - Architecture Decisions | orchestrator / Plan phase | rewrite, folded into the planifest-plan invocation |
| ## Phase 3 - Code Generation | orchestrator / Implement phase | rewrite, invokes planifest-implement, keep the pre-phase capability-skill check and Subagent Decomposition Directive |
| ## Phase 4 - Validate | orchestrator / Validate-and-accept phase | rewrite, invokes planifest-validate-and-accept |
| ## Phase 5 - Security | orchestrator / Validate-and-accept phase | rewrite, folded into the planifest-validate-and-accept invocation |
| ## Phase 6 - Documentation | orchestrator / Implement phase | rewrite, docs land with code inside planifest-implement, the P6 STOP gate collapses into the single-gate model |
| ### Cross-Model Review Gate | orchestrator / Pre-ship review gate | rewrite, toggle, cap, and different-model rule unchanged, repositioned before the ship phase |
| ## Phase 7 - Archive | orchestrator / Ship phase | rewrite, invokes planifest-ship |
| ## Phase 8 - Build Assessment | orchestrator / Ship phase | rewrite, folded into the planifest-ship invocation |
| ## Phase 9 - Ship | orchestrator / Ship phase | rewrite, gate wording renumbered, always-confirm rule ("continuous_run does NOT bypass") carries over |
| ## Agent Dispatch Standards | orchestrator / Agent Dispatch Standards | merge, pointer to agent-dispatch-standards.md unchanged |
| ## Mid-Pipeline Requirement Changes | orchestrator / Mid-pipeline change protocol | rewrite, absorbs the reversal-assessor's domain, re-run rules renumbered to the five phases |
| ## Governed Phase-Reversal Protocol | dropped | drop, ⚠ RULE: reversal budget of 2 per feature in a git-tracked counter, and the four always-stop human gates (altering classification voids continuous-run, re-exit from discovery, budget exhaustion, cascade over 3 artifacts) exist nowhere else, the mid-pipeline change protocol has no budget and no always-stop gates |
| ## Adoption Modes | orchestrator / Adoption modes | merge, discovery-pass lifecycle, mode taxonomy, and conflict warnings carry into the discovery phase content |
| ## Invoking the Change Pipeline | dropped | drop, single route replaces it, note the change-agent row below for what folds into implement |
| ## Telemetry | orchestrator / Telemetry | merge, unified signal, failure-marker recovery, per-phase Telemetry line rule, and block-or-proceed question all retained, orchestrator keeps ownership |

## planifest-spec-agent -> planifest-plan

| Source section | Destination | Action |
|---|---|---|
| ## Input | planifest-plan / Input | merge, unchanged |
| ## What You Produce | planifest-plan / Requirements artifacts | merge, minimal default set and conditional-trigger rule (never from feature size alone, no placeholder files) carry verbatim |
| ## Rules | planifest-plan / Requirements rules | merge, one-question-at-a-time, retrofit mode, OpenAPI critical condition, no invented requirements, measurable NFRs, specific risks, mandatory notResponsibleFor, and the no-assuming-away-ambiguity rule all carry |
| ## Waved Features | planifest-plan / Waved features | merge, current-wave-only rule and cumulative glossary and risk register carry |
| ## Parallelism Directive | planifest-plan / Parallelism | merge, combine with the adr-agent table into one plan-phase table |
| ## Telemetry | planifest-plan / Telemetry | merge, spec_gap event and the mandatory-when-active gate carry |
| ## Commit Cadence (Hard Limit 7) | planifest-plan / Commit cadence | merge, unchanged |

## planifest-adr-agent -> planifest-plan

| Source section | Destination | Action |
|---|---|---|
| ## Input / Output | planifest-plan / ADR input and output | merge, unchanged |
| ## What Requires an ADR | planifest-plan / What requires an ADR | merge, criteria table carries verbatim, including the every-data-ownership-mapping rule |
| ## Rules | planifest-plan / ADR rules | merge, supersede protocol, sequential numbering, one-positive-one-negative consequence, write-to-disk-as-completed all carry |
| ## Parallelism Directive | planifest-plan / Parallelism | merge, combined with the spec-agent table |
| ## Telemetry | planifest-plan / Telemetry | merge, adr_decision event carries |
| ## Commit Cadence (Hard Limit 7) | planifest-plan / Commit cadence | merge, unchanged |

## planifest-codegen-agent -> planifest-implement

| Source section | Destination | Action |
|---|---|---|
| ## Build Target: docker | planifest-implement / Build target | merge, never-check-host-runtimes rule carries verbatim |
| ## Input | planifest-implement / Input | merge, Precision Reading Protocol carries, extended by the change-agent's domain-context pattern (see change-agent block) |
| ## What You Produce | planifest-implement / Outputs | merge, extended with the docs-agent outputs so code, tests, and docs land together |
| ## Multi-Component Sequencing | planifest-implement / Sequencing | merge, dependency order and circular-dependency halt carry |
| ## Library Standards: Pre-Scaffold Check | planifest-implement / Library check | merge, overrides-first lookup, avoid-list substitution, and no-silent-use escalation carry |
| ## Rules | planifest-implement / Rules | merge, ⚠ RULE rows preserved: schema-change proposal-and-stop, TDD inner loop with 3-attempt escalation ceiling, deviation and escalation protocol, no-invented-endpoints, framework component.yml close-out |
| ## Parallel Dispatch Checklist | planifest-implement / Parallel dispatch | merge, checklist and MUST-parallelise table carry, out-of-scope backlog filing clause carries |
| ## Telemetry | planifest-implement / Telemetry | merge, deviation, migration_proposal, self_correction, and retry_limit_exceeded events carry with phase_name updated |
| ## Commit Cadence (Hard Limit 7) | planifest-implement / Commit cadence | merge, unchanged |

## planifest-docs-agent -> planifest-implement

| Source section | Destination | Action |
|---|---|---|
| ## Living Documentation Layer | planifest-implement / Living docs | merge, mandatory living-docs table, update-do-not-recreate rule, and Last-updated stamp carry |
| ## P6 Gate | planifest-implement / Docs gate | rewrite, Gate A (docs/ must exist) carries, Gate B's standalone confirmation stop collapses into the implement phase flow, continuous-run auto-accept wording carries |
| ## Input | planifest-implement / Input | merge, folded into the combined input list |
| ## What You Produce | planifest-implement / Per-component docs | merge, per-component artifact table, feature-level completeness check, and changelog audit trail carry |
| ## Rules | planifest-implement / Docs rules | merge, every-artifact-accounted-for, drift detection table, legitimate-absences list, and backlog filing for deferred items and tech debt all carry |
| ## Parallelism Directive | planifest-implement / Parallel dispatch | merge, combined with the codegen table |
| ## Telemetry | planifest-implement / Telemetry | merge, doc_gap event carries |
| ## Commit Cadence (Hard Limit 7) | planifest-implement / Commit cadence | merge, unchanged |

## planifest-validate-agent -> planifest-validate-and-accept

| Source section | Destination | Action |
|---|---|---|
| ## Build Target: docker | planifest-validate-and-accept / Build target | merge, in-container CI rule carries |
| ## Input | planifest-validate-and-accept / Input | merge, unchanged |
| ## Process | planifest-validate-and-accept / CI process | merge, ⚠ RULE rows preserved: library audit, semantic AC coverage as failure not warning, 5-cycle self-correct cap, halt-and-escalate format, and the do-not-proceed-while-failing block rule |
| ## Rules | planifest-validate-and-accept / Rules | merge, fix-the-actual-bug (no suppression), no scope widening, and cycle tracking carry |
| ## Parallelism Directive | planifest-validate-and-accept / Parallelism | merge, batch dispatch order carries |
| ## Telemetry | planifest-validate-and-accept / Telemetry | merge, validation_failure, self_correction, and retry_limit_exceeded events carry |
| ## Commit Cadence (Hard Limit 7) | planifest-validate-and-accept / Commit cadence | merge, unchanged |

## planifest-security-agent -> planifest-validate-and-accept

| Source section | Destination | Action |
|---|---|---|
| ## Input | planifest-validate-and-accept / Security input | merge, unchanged |
| ## Report Structure | planifest-validate-and-accept / Security report | merge, STRIDE model, report path, and section list carry |
| ## Rules | planifest-validate-and-accept / Security rules | merge, conservative rating, risk-register cross-reference, and critical-and-high-findings-flagged-at-PR-gate carry |
| ## Parallelism Directive | planifest-validate-and-accept / Parallelism | merge, combined into the phase table |
| ## Telemetry | planifest-validate-and-accept / Telemetry | merge, security_finding event carries |
| ## Commit Cadence (Hard Limit 7) | planifest-validate-and-accept / Commit cadence | merge, unchanged |

## planifest-verify-by-execution -> planifest-validate-and-accept

| Source section | Destination | Action |
|---|---|---|
| ## The One Rule | planifest-validate-and-accept / Verify by execution | merge, reading-test-output-never-counts rule carries verbatim |
| ## Method Selection | planifest-validate-and-accept / Verification methods | merge, ⚠ RULE preserved: never verify against production systems or with production credentials |
| ## Per-Criterion Outcomes | planifest-validate-and-accept / Verification outcomes | merge, failed feeds the self-correct loop, not-verifiable is recorded with reason and never silently passed |
| ## Report | planifest-validate-and-accept / Verification report | merge, verification-report.md format carries |
| ## Telemetry | planifest-validate-and-accept / Telemetry | merge, loop_iteration emission carries |

## planifest-ship-agent -> planifest-ship

| Source section | Destination | Action |
|---|---|---|
| ## Prefix | planifest-ship / Prefix | rewrite, P7, P8, and P9 prefixes collapse to the single ship-phase prefix |
| ## Hard Limits | planifest-ship / Hard Limits | merge, ⚠ RULE rows preserved: no code or framework modification, never skip the archive, never raise a PR or create a tag without human awareness |
| ## P7: Archive | planifest-ship / Archive | rewrite, all steps carry (changelog, .skips, .feature-id, regression confirmation, test report, copy-then-delete archive, sentinel-last deletion, blocking docs/about.md step, cross-reference link check, archive commit), phase numbering removed |
| ## P8: Build Assessment | planifest-ship / Build assessment | rewrite, subagent dispatch replaced by the merged build-assessment content below, archived-build-log-is-the-only-copy warning carries |
| ## P9: Ship | planifest-ship / Ship steps | rewrite, version derivation (product.yml policies, exit codes, never tag a fabricated or unvalidated version, never lower than the last tag), marker pre-flight, local-git-only and restore-pr-attribution overrides, push-or-describe question, confirmation, and fresh-session advisory all carry |
| ## Telemetry | planifest-ship / Telemetry | merge, phase_start and phase_end events renamed to the ship phase |

## planifest-build-assessment-agent -> planifest-ship

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | planifest-ship / Assessment limits | merge, read-only rule carries, P8 prefix rule drops with the prefix rewrite |
| ## Input / Output | planifest-ship / Assessment input | merge, archive-path input and build-report.md output carry |
| ## Report Structure | planifest-ship / Build report | merge, report template carries |
| ## Critical Audit | planifest-ship / Critical audit | rewrite, model-routing, parallelism, self-correction, and build-log-integrity audits carry, the phase-gate audit's P1-P7 gate list is renumbered to the single-gate model |
| ## Rules | planifest-ship / Assessment rules | merge, source-from-build-log-only and not-evidenced-treat-as-not-applied carry |
| ## After the Report | planifest-ship / Assessment completion | rewrite, completion confirmation reworded without the P8 prefix |

## planifest-test-writer -> planifest-test-writer (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | unchanged | merge, one test, no implementation code, RED confirmation, no full suite |
| ## Input | unchanged | merge |
| ## What You Produce | unchanged | merge |
| ## Process | unchanged | merge |
| ## Regression Tagging | rewrite in place | rewrite, "human review at P7" becomes the ship phase, the advisory mechanism itself carries |

## planifest-implementer -> planifest-implementer (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | unchanged | merge, minimum code, no refactor, GREEN required, no full suite |
| ## Input | unchanged | merge |
| ## What You Produce | unchanged | merge |
| ## Process | unchanged | merge, 3-fix-attempt escalation to the invoking agent carries, invoker renamed from codegen-agent to planifest-implement |

## planifest-refactor -> planifest-refactor (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | unchanged | merge, no new behaviour, never change tests, full suite green, escalation renamed from codegen-agent to planifest-implement |
| ## Input | unchanged | merge |
| ## What You Produce | unchanged | merge |
| ## Process | unchanged | merge |

## planifest-loop-runner -> planifest-loop-runner (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | unchanged | merge, ⚠ RULE rows preserved: armed stop rule before first iteration, .ratchet-approve human-only write protocol with dedicated commit, budget counters never agent-reset, append-only run logs |
| ## Toggle Protocol (ADR-003) | unchanged | merge, absent-means-off and human-only enablement carry |
| ## Loop State (per instance) | unchanged | merge, commit-per-iteration and never-leave-a-dead-loop-armed carry |
| ## The Iteration Cycle | unchanged | merge |
| ## Stop Rules | rewrite in place | rewrite, caps carry (default 3, validate keeps 5, reversal budget row drops with the protocol), the intro's loop roster is trimmed of design-critic and reversal-protocol references |
| ## Escalation Format | unchanged | merge, phase prefix in the message renumbered |
| ## Telemetry | unchanged | merge, loop_iteration event carries |

## planifest-optimise-agent -> planifest-optimise-agent (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Scope | unchanged | merge |
| ## Categories of Superfluous Content | unchanged | merge |
| ## Process | rewrite in place | rewrite, the Change Pipeline hand-off in Phase 4 becomes a hand-off to the single route |
| ## Hard Limits | unchanged | merge, never writes files, never confirms without explicit human confirm |

## planifest-migrator -> planifest-migrator (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Hard Limits | unchanged | merge, never touch src/, never auto-correct code, never proceed past a human skip |
| ## Process | unchanged | merge |
| ## Exclusions (always apply) | unchanged | merge |
| ## Response Style | unchanged | merge |

## planifest-refresh-setup -> planifest-refresh-setup (survives, trim)

| Source section | Destination | Action |
|---|---|---|
| ## Step 1 - Determine the Target Tool | unchanged | merge |
| ## Step 2 - Check for an Interrupted Prior Run | unchanged | merge |
| ## Step 3 - Reconstruct the Active Flags | unchanged | merge |
| ## Step 4 - Confirm With the Human on the Loop | unchanged | merge, no-bypass explicit-affirmative rule carries |
| ## Step 5 - Write the Marker Before Any Deletion | unchanged | merge |
| ## Step 6 - Delete the Boot Files | unchanged | merge, script-only deletion with hardcoded allowlist carries |
| ## Step 7 - Re-invoke Setup | unchanged | merge |
| ## Step 8 - Setup Failure Handling | unchanged | merge, never-retry-automatically carries |
| ## What This Skill Never Does | unchanged | merge |

## planifest-change-agent -> retired (domain-context pattern folds into planifest-implement)

| Source section | Destination | Action |
|---|---|---|
| ## Input | dropped | drop, change-route framing, no binding rule |
| ## Process / Phase 1 - Domain Context | planifest-implement / Input | merge, the Precision Reading Protocol and blast-radius analysis fold into implement's input discipline, this is the one part of this skill that survives |
| ## Process / Phase 2 - Targeted Change | dropped | drop, minimum-change and no-out-of-scope-refactor discipline retires with the route, the schema proposal-and-stop rule is not lost (CLAUDE.md rule 3 and planifest-implement both state it) |
| ## Process / Phase 3 - Validate | dropped | drop, duplicate of the validate-agent rules already merged into validate-and-accept |
| ## Process / Phase 4 - ADR & Migration Check | dropped | drop, ADR supersede protocol survives via the adr-agent merge, ⚠ RULE: "rollbacks are human-initiated, never automatic" is stated only here |
| ## Process / Phase 5 - Update Documentation | dropped | drop, the affected-artifact update list is covered by the docs-agent merge and CLAUDE.md rule 7 |
| ## Process / Phase 6 - Archive | dropped | drop, archive close-out is covered by planifest-ship, which every run now reaches |
| ## New Component Handoff | dropped | drop, single route makes the escalate-to-new-feature branch moot |
| ## Output Header | dropped | drop, change-summary.md retires with the route |
| ## Telemetry | dropped | drop, its four event types all survive via other skills' telemetry merges |

## planifest-design-critic -> retired (human uses /code-review)

| Source section | Destination | Action |
|---|---|---|
| ## Invocation Contract | dropped | drop, fresh-context maker-checker contract retires with the skill |
| ## Step 1: Mechanical layer first | dropped | drop, ⚠ RULE: the consistency-check.mjs run with automatic REJECT on non-zero exit has no remaining caller, /code-review does not run it |
| ## Step 2: Rubric (REJECT-default) | dropped | drop, deliberate, /code-review replaces the rubric |
| ## Step 3: Verdict artifact | dropped | drop, verdict file format retires |
| ## Telemetry | dropped | drop, loop_iteration for loop_id design_critic retires with the loop |

## planifest-reversal-assessor -> retired (mid-pipeline change protocol covers it)

| Source section | Destination | Action |
|---|---|---|
| ## Invocation Contract | dropped | drop, ⚠ RULE: the assessor is never the filer (ADR-006 separation), the mid-pipeline change protocol has no equivalent independence requirement |
| ## Rubric: ALL five must be evidenced | dropped | drop, ⚠ RULE: DENY-default burden of proof, budget check (2 per feature), cascade-over-3 human gate, and altering-voids-continuous-run classification (REQ-019) all retire with this skill and the orchestrator's reversal protocol |
| ## Verdict artifact | dropped | drop, verdict file format retires |
| ## Telemetry | dropped | drop, phase_reversal_granted and phase_reversal_denied events retire |

## planifest-scope-lock-agent -> retired (orchestrator drafts inline)

| Source section | Destination | Action |
|---|---|---|
| ## Invocation Contract | dropped | drop, four-way parallel dispatch and partial-failure fallback retire with the subagent |
| ## Drafting rules | orchestrator / Scope Lock Challenge | rewrite, rules 1-4 (usage-only framing, outcome not action, honest N/A, consistency check) fold into the orchestrator's inline drafting, ⚠ RULE: rule 5 (never self-confirm, only the human's explicit per-item accept, edit, or reject counts) must survive in the rewritten orchestrator, at risk because the drafter and confirmer are now the same agent |
| ## Output format | dropped | drop, subagent return format is moot when drafting is inline |
| ## Telemetry | dropped | drop, it declared no event of its own, build-log entries remain the durable record |

## Rules at risk

Every ⚠ entry from the tables above, gathered for human review. The first five die with retired content. The last one survives only if the implement phase carries it deliberately.

1. **Reversal budget and always-stop gates** (orchestrator, Governed Phase-Reversal Protocol). A budget of 2 reversals per feature in a git-tracked counter, plus four always-stop human gates: altering classification voids continuous-run authorisation, any re-exit from discovery, budget exhaustion, and a cascade larger than 3 artifacts. The mid-pipeline change protocol that replaces this has no budget and no always-stop gates.
2. **DENY-default reversal rubric with maker-checker separation** (planifest-reversal-assessor). The judge is never the filer, ambiguous evidence fails, and the burden of proof sits on the petition. Nothing in the replacement protocol requires an independent judgement.
3. **Rollbacks are human-initiated, never automatic** (planifest-change-agent, Phase 4). This sentence appears nowhere else in the framework.
4. **Mechanical consistency check with automatic REJECT** (planifest-design-critic, Step 1). `consistency-check.mjs` loses its only caller. /code-review does not run it, so a non-zero consistency failure no longer blocks anything.
5. **REJECT-default artifact critique before the human gate** (planifest-design-critic, Step 2). The human now reviews first drafts unless /code-review is invoked by hand.
6. **Scope confirmation is human-only, per item** (planifest-scope-lock-agent, drafting rule 5). With inline drafting, the same agent drafts and records confirmation, so the rewritten orchestrator must state explicitly that a draft is never approval and only the human's per-item accept, edit, or reject counts.
