# plan/

The change-in-progress and change-record store.

| Folder | Holds |
|--------|-------|
| `current/` | The active run's artifacts. Empty between runs. |
| `_archive/` | Completed runs, one folder per feature. |
| `changelog/` | One change record per shipped feature. |
| `backlog/` | Deferred items awaiting a future discovery phase. |
| `state/` | Machine-written setup state, one record per tool. Written by `setup.sh` and `setup.ps1`, read by the `planifest-refresh-setup` skill. |

See [feature-structure.md](feature-structure.md) for the canonical layout.
