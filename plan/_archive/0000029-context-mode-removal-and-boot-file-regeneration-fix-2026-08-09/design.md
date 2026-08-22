## Feature
- Problem: A third-party MCP plugin (context-mode) was found to inject a fake system-reminder instructing the agent to conceal a change from the human; it was disabled machine-wide. Two tooling bugs surfaced while cleaning up its traces by hand: boot files never regenerate once they exist, and the shared boot template unconditionally instructs every generated CLAUDE.md/AGENTS.md to prefer context-mode tools even where it is not installed.
- Adoption mode: standard-iterative
- Feature ID: 0000029-context-mode-removal-and-boot-file-regeneration-fix
- Discovery: see `plan/current/discovery.md`

## Product Layer
- User stories:
  - US-001: As a human running a Planifest refresh, I want CLAUDE.md/AGENTS.md to always regenerate from the current template, so that stale instructions do not linger once local customization already lives in planifest-overrides/instructions/
  - US-002: As a human who has disabled context-mode, I want the generated boot file to stop instructing the agent to use it, so that no repo (this one or any downstream consumer) is told to route work through a plugin that may not be installed or trusted
  - US-003: As the human on the loop, I want the agent's standing git-permission instruction updated to reflect that pull, push, and PR creation are now authorized, so that the agent's actual authority matches what has been granted
- Acceptance criteria confirmed: 5 (see feature-brief.md)
- Constraints: must not remove the `--context-mode-mcp` flag or its hook-install code path; `setup.ps1` must stay in parity with `setup.sh`
- Integrations: none

## Architecture Layer
- Latency target: not applicable, tooling fix
- Availability target: not applicable
- Scalability target: not applicable
- Security: no auth/authz change. The local-git-only override text is the only policy-adjacent change, expanding agent authority to pull/push/PR-create, explicitly excluding commits to main and PR merges, both of which stay human-only
- Data privacy: no regulated data
- Observability: standard defaults, no new telemetry events
- Cost boundary: not constrained

## Engineering Layer
- Stack: bash (setup.sh), PowerShell (setup.ps1), markdown templates. No new stack decisions.
- Components:
  - planifest-framework (existing): `write_boot_file`/`Write-BootFile` regeneration fix, `templates/standard-boot.md` context-mode line removal. This is distributed source, changes here affect every repo that installs the framework.
- Data ownership: not applicable
- Deployment: not applicable
- API versioning: not applicable

## Repo-Local Config (not a planifest-framework distribution change)
- `planifest-overrides/instructions/custom-001-local-git-only.md`: update to state pull, push, and PR creation are authorized for the agent; commits to `main` and PR merges remain explicitly human-only. This is this repo's own local override, it does not ship to other repos.
- `planifest-overrides/setup-config/claude-code.md`: fold in the already-uncommitted diff from this session's manual `setup.sh` reruns (context-mode flag removed from the recorded flag set).

## Scope
- In: setup.sh/setup.ps1 write_boot_file fix (all applicable tools); templates/standard-boot.md context-mode line removal (claude-code, cline, codex, antigravity, copilot, windsurf; cursor already clean; roo-code/opencode not applicable); custom-001-local-git-only.md git-permission update; fold in pending claude-code.md flag-record diff; regenerate CLAUDE.md in this repo and the other Planifest-enabled repos touched earlier this session
- Out: removing --context-mode-mcp flag or its hook-install code path; context-mode marketplace registration in ~/.claude/settings.json (already handled outside the pipeline this session); structured-telemetry-mcp wiring (unaffected)
- Deferred: none

## Assumptions
- CLAUDE.md/AGENTS.md are fully disposable, all durable local customization lives in planifest-overrides/instructions/ and is re-applied by append_override_instructions on every regeneration. Impact if wrong: regenerating would silently drop customization not actually captured in overrides. Confirmed by human this session ("Claude files are disposable").

## Risks
- Regenerating CLAUDE.md across repos on this machine could momentarily surface as an unexpected diff if any repo had manual CLAUDE.md edits not reflected in overrides. Likelihood: low (assumption above holds by design). Impact: low, file is gitignored and disposable, worst case is a human notices unexpected content and re-adds it as an override.

## Dependencies
- Upstream: none
- Downstream: every repo that runs `setup.sh`/`setup.ps1` in the future (including the 7 Planifest-enabled repos on this machine touched earlier this session) benefits from the fix on next run.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001, US-002 - boot file regeneration and template fix | planifest-codegen-agent | Direct source-code-level bash/PowerShell/markdown fix, no new component |
| US-003 - git permission override update | planifest-codegen-agent | Small markdown edit to an existing override file |

## Repo Instructions
- custom-001-local-git-only.md: Local Git Only (being updated by this feature) plus Commit Granularly, Continuously
- custom-002-prefer-subagent-decomposition.md: standing instruction to decompose long-running/multi-unit tasks into parallel subagents
- custom-003-git-up-to-date-shorthand.md: GUTD shorthand for checkout main + pull + report untracked files

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 09 Aug 2026 @ 22:30 BST
