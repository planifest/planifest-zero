# Repository structure

> The canonical layout for a Planifest-managed repository. Three top-level folders, three concerns.

## The three folders

```
repo/
+-- planifest-zero/          <- The framework: skills, templates, schemas,
|                               standards, hooks, setup scripts.
|
+-- plan/                    <- The specifications and records.
|
+-- src/                     <- The code, one folder per component.
```

## plan/ layout

The active run works in `plan/current/`. The ship phase archives it.

```
plan/
+-- current/                 <- The active run. Empty between runs.
|   +-- feature-brief.md
|   +-- discovery.md
|   +-- design.md
|   +-- build-log.md
|   +-- execution-plan.md
|   +-- scope.md
|   +-- risk-register.md
|   +-- domain-glossary.md
|   +-- requirements/
|   |   +-- req-001-{slug}.md
|   +-- adr/
|       +-- ADR-001-{slug}.md
|
+-- _archive/
|   +-- {feature-id}-{YYYY-MM-DD}/   <- current/ moves here at ship.
|
+-- changelog/
|   +-- {feature-id}-{YYYY-MM-DD}.md
|
+-- backlog/
    +-- {id}-{slug}/entry.md
```

Two rules govern the layout:

- No permanent per-feature folders. Work lives in `current/` and ships to `_archive/`.
- One level of nesting inside a feature folder: `requirements/` and `adr/` only.

## src/ layout

One folder per component. The manifest lives with the code.

```
src/
+-- {component-id}/
    +-- component.yml
    +-- docs/
    +-- {source}
```

This repository's single component is the framework itself, so its manifest
lives at `planifest-zero/component.yml` and `src/` holds only the scaffold.
