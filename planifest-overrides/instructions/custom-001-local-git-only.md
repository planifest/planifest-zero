### Git Permissions
You may fetch, pull, push, and create pull requests (`gh pr create`) without asking each time. Work on a feat/ branch and push it to origin as you commit. Don't use git worktrees - ensure you are on a feat/ branch but work directly in the working directory.

Two actions are human-only, with no exception:

- Committing directly to `main`. Every change lands via a feature branch.
- Merging pull requests. The human on the loop reviews and merges.

Report back if any remote git or GitHub command fails for any reason.

### Commit Granularly, Continuously
Commit locally after every meaningful artifact write — do not batch changes waiting for a phase gate, an approval checkpoint, or task completion. A single requirement doc, ADR, TDD cycle, or config fix is a commit on its own; don't hold it pending a bigger, later commit. Uncommitted work in the working directory is unrecoverable progress — commit early and often so nothing sits unsaved.
