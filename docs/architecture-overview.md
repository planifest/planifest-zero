# Architecture Overview

**Last updated:** 0000030-framework-cut-down (22 Aug 2026)

---

## What this repo is

This repo is the Planifest framework itself. It holds one component, `planifest-zero`, which other projects install into their working tree.

The framework is not a service. It has no runtime of its own. It ships four things:

1. **Skills.** Markdown instructions that Claude Code auto-discovers from `.claude/skills/`. The orchestrator drives phases P0 through P9, and each phase has its own skill.
2. **Hooks.** Node `.mjs` scripts that Claude Code invokes synchronously at tool-call boundaries. Enforcement hooks block or annotate. Telemetry hooks emit events.
3. **Standards, templates, and schemas.** The reference material that skills bundle at install time.
4. **Setup scripts.** `setup.sh` and `setup.ps1` copy the above into a target project and wire `.claude/settings.json`.

---

## Install flow

```
planifest-zero/          setup.sh claude-code          target project
├── skills/          ──────────────────────────────────▶   .claude/skills/
├── templates/       ── bundled per skill frontmatter ──▶   .claude/skills/*/assets/
├── standards/       ── bundled per skill frontmatter ──▶   .claude/skills/*/references/
├── workflows/       ──────────────────────────────────▶   .claude/commands/
├── hooks/enforcement/ ────────── always ──────────────▶   .claude/hooks/enforcement/
├── hooks/telemetry/   ── under --structured-telemetry-mcp ▶ .claude/hooks/telemetry/
└── templates/standard-boot.md ───────────────────────▶   CLAUDE.md
```

Skills bundle selectively. Each `SKILL.md` declares `bundle_templates` and `bundle_standards` in its frontmatter, and setup copies only those files. A skill with no manifest gets everything.

Boot files are disposable build outputs. Every run regenerates `CLAUDE.md` from the template, then re-appends the contents of `planifest-overrides/instructions/` between sentinel markers. Durable local customisation lives in the overrides directory, never in the boot file.

---

## Enforcement model

Enforcement is deterministic where it can be, and instructional where it cannot.

**Deterministic.** A hook exits 2 with a human-readable message and Claude Code blocks the tool call. `gate-write` blocks writes to `src/` without a confirmed design. `ratchet-check` blocks weakening edits to an active loop's artifacts. `em-dash-guard` rejects U+2014 in scoped prose paths.

**Instructional.** Skills tell the agent what to do. The orchestrator's hard limits, the one-question-at-a-time rule, and the phase gates all rely on the agent following its instructions.

Every hook fails open on an unexpected error. Exit 0 with no output means the tool call proceeds. That is deliberate: a broken hook must never stop a session.

---

## Telemetry

Telemetry is gated on one signal: `--structured-telemetry-mcp` passed at setup. When active, emission is mandatory rather than best-effort.

`resolve-phase.mjs` interposes on the Skill tool to work out which pipeline phase is active, then re-execs `emit-phase-start.mjs`. A `Stop` hook handles `emit-phase-end.mjs`. Events carry a `product_id` sourced from `product.yml`, so they stay attributable across clones and machines.

When emission fails, the hook writes a durable marker under `plan/.telemetry-failures/`. The orchestrator surfaces that marker at the next phase start and asks the human whether to block or proceed.

---

## Version derivation

`product.yml` holds the product-level version manifest. Under `versionPolicy: max-component-version`, `scripts/product-version.mjs` reads each listed `component.yml` live and takes the highest. Nothing caches a version, so the list only changes when a component is added or removed.

This project has one component and keeps `product.yml` anyway, because the telemetry hooks source `product_id` from its `id` field.
