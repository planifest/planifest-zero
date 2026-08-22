# Decisions Index

> Living document. Index of all ADRs across all features. Updated after every pipeline run.
> Do not archive this file. Update it in place.

Last updated: 0000030-framework-cut-down

---

## Note on the reset

Feature 0000030 emptied `plan/_archive/`, so the ADR files for features 0000001 through 0000029 no longer exist in the working tree. They remain in git history.

This index restarts from 0000030. Decisions from earlier features still bind where their subject survives, but the ADR text has to be read from history.

---

## All Architecture Decision Records

### Feature 0000030: framework-cut-down

| ADR | Title | Status | Summary |
|-----|-------|--------|---------|
| ADR-001 | Claude Code is the only supported tool target | accepted | Drops eight tool targets, the vendored external skill library, and the context-mode integration. Supersedes 0000001 ADR-001 to ADR-004. |

---

## Superseded

| ADR | Superseded by | Reason |
|-----|---------------|--------|
| 0000001 ADR-001 to ADR-004 | 0000030 ADR-001 | The context-mode hook design they governed no longer exists. |
