# Component Registry

**Last updated:** 0000030-framework-cut-down (22 Aug 2026)
**Maintained by:** planifest-change-agent

---

## Registry

| ID | Name | Type | Domain | Status | Summary | Docs |
|----|------|------|--------|--------|---------|------|
| `planifest-framework` | Planifest Framework | component-pack | developer-tooling | active | Core standards, skills, hooks, and Claude Code setup scripts that enforce the confirmed-design pipeline. | [component.yml](../planifest-framework/component.yml) |

---

## Status key

| Status | Meaning |
|--------|---------|
| `active` | In production, installed in target environments |
| `in-progress` | Pipeline in flight |
| `deprecated` | Superseded, pending removal |
| `planned` | On the roadmap, not yet in a pipeline |

---

## Removed at 0000030

| ID | Reason |
|----|--------|
| `context-mode-hooks` | Commit 6a50af1 dropped context-mode from the boot templates, orphaning the component. 0000030 removed the `--context-mode-mcp` flag and the hooks with it. |
| `setup-hook-integration` | Its `src/` tree documented `setup.sh` and `setup.ps1`, which live in `planifest-framework/` and survive under that component. |

Both remain recoverable from git history.
