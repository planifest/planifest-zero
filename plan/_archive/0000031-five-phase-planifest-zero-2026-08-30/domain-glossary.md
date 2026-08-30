---
title: "Domain Glossary - five-phase-planifest-zero"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.2.0"
---
# Domain Glossary - five-phase-planifest-zero

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000031-five-phase-planifest-zero
**Version:** 0.2.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| planifest-zero | The framework component and its folder, renamed from planifest-framework | the framework | planifest-zero |
| phase | One of exactly five pipeline stages: discovery, plan, implement, validate-and-accept, ship | none | planifest-zero |
| discovery | First phase. Brief, coaching, discovery record, backlog pickup, version confirmation, design gate | none | planifest-zero |
| plan | Second phase. Requirements and ADRs as one artifact set behind one human gate | none | planifest-zero |
| implement | Third phase. Code, tests, and docs land together through the TDD loop | none | planifest-zero |
| validate-and-accept | Fourth phase. CI, self-correction, security review, verify-by-execution, human acceptance | none | planifest-zero |
| ship | Fifth phase. Archive, build assessment, changelog, tag, PR | none | planifest-zero |
| route | The single path every change takes: the feature pipeline. No other routes exist | feature pipeline | planifest-zero |
| skill | A markdown instruction pack under `skills/`, installed to `.claude/skills/` by setup | none | planifest-zero |
| phase enum | The five canonical phase values exported by `phase-enum.mjs` and mirrored in telemetry-standards.md | none | planifest-zero |
| installed tree | The `.claude/` copy of hooks and skills that setup generates; the live contract until setup re-runs | live contract | planifest-zero |
| overrides | Repo-level customisation under `planifest-overrides/`: instructions, capability-skills, setup-config, library-standards | none | planifest-zero |
| change record | Historical narrative locations exempt from the present-state docs rule: `plan/changelog/`, `plan/_archive/`, ADR files, `docs/decisions-index.md` | none | planifest-zero |
| pruning | Setup deleting retired skill folders from `.claude/skills/` so exactly the current set remains | none | planifest-zero |
