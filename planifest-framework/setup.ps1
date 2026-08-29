<#
.SYNOPSIS
    Planifest Setup - Configures skills for your agentic coding tool.

.DESCRIPTION
    Copies Planifest skills into the directory structure each coding tool expects.
    Each tool's specific config lives in setup/<tool>.ps1.
    This script handles shared logic only.

.EXAMPLE
    .\planifest-framework\setup.ps1 claude-code
    .\planifest-framework\setup.ps1 claude-code --structured-telemetry-mcp
#>

# Manual arg parsing — supports --flag style for cross-platform consistency
$Tool = $null
$StructuredTelemetryMcp = $false
$BackendUrl = 'http://localhost:3741'
$StrictOrchestrator = $false
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        '--structured-telemetry-mcp'  { $StructuredTelemetryMcp = $true; $i++ }
        '--strict-orchestrator'       { $StrictOrchestrator = $true; $i++ }
        '--backend-url' {
            $i++
            if ($i -ge $args.Count) { Write-Host "Error: --backend-url requires a value"; exit 1 }
            # Validated here, once, at parse time -- Merge-TelemetryHookSettings
            # interpolates this value directly into a shell command string
            # written into the target tool's hook config (backlog 0000055,
            # found during 0000027's P5 review). Fail loudly (setup-time check).
            if ($args[$i] -notmatch '^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._/-]*)?$') {
                Write-Host "Error: --backend-url must be a plain http(s) URL (host[:port][/path]), got: $($args[$i])"
                exit 1
            }
            $BackendUrl = $args[$i]; $i++
        }
        default {
            if ($args[$i] -like '-*') { Write-Host "Unknown flag: $($args[$i])"; exit 1 }
            else { $Tool = $args[$i]; $i++ }
        }
    }
}

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SkillsSrc = Join-Path $ScriptDir 'skills'
$WorkflowsSrc = Join-Path $ScriptDir 'workflows'
$SetupDir = Join-Path $ScriptDir 'setup'

$ValidTools = @('claude-code')

# --- Shared functions ---

function Copy-PlanifestSkills {
    param($TargetDir)

    Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
        $skillName = $_.Name
        $srcDir = $_.FullName
        $destDir = Join-Path $TargetDir $skillName
        
        $srcSkillMd = Join-Path $srcDir "SKILL.md"
        if (Test-Path $srcSkillMd) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Copy-Item -Path $srcSkillMd -Destination $destDir -Force

            # Rewrite relative paths to match bundled directory structure
            $skillMdPath = Join-Path $destDir "SKILL.md"
            $skillContent = Get-Content -Path $skillMdPath -Raw
            $skillContent = $skillContent -replace '\.\./templates/', './assets/templates/'
            $skillContent = $skillContent -replace '\.\./standards/reference/', './references/reference/'
            $skillContent = $skillContent -replace '\.\./standards/', './references/'
            $skillContent = $skillContent -replace '\.\./schemas/', './assets/schemas/'
            Set-Content -Path $skillMdPath -Value $skillContent -NoNewline -Encoding UTF8

            Write-Host "  + $skillName/SKILL.md"
            
            foreach ($optDir in @('scripts', 'assets', 'references')) {
                $srcOptDir = Join-Path $srcDir $optDir
                if (Test-Path $srcOptDir) {
                    Copy-Item -Path $srcOptDir -Destination $destDir -Recurse -Force
                }
            }

            # Parse bundle_templates and bundle_standards from SKILL.md frontmatter
            $rawContent = Get-Content -Path $srcSkillMd -Raw
            $bundleTemplates = @()
            $bundleStandards = @()
            if ($rawContent -match '(?m)^bundle_templates:\s*\[([^\]]*)\]') {
                $bundleTemplates = $Matches[1].Trim() -split '\s*,\s*' | Where-Object { $_ }
            }
            if ($rawContent -match '(?m)^bundle_standards:\s*\[([^\]]*)\]') {
                $bundleStandards = $Matches[1].Trim() -split '\s*,\s*' | Where-Object { $_ }
            }

            # Bundle only declared templates (or all if no manifest found)
            $templatesSrc = Join-Path $ScriptDir "templates"
            if (Test-Path $templatesSrc) {
                $destTemplates = Join-Path $destDir "assets\templates"
                New-Item -ItemType Directory -Path $destTemplates -Force | Out-Null
                if ($bundleTemplates.Count -gt 0) {
                    foreach ($tpl in $bundleTemplates) {
                        $tplPath = Join-Path $templatesSrc $tpl
                        if (Test-Path $tplPath) {
                            Copy-Item -Path $tplPath -Destination $destTemplates -Force
                        }
                    }
                    Write-Host "    templates: selective ($($bundleTemplates.Count) files)"
                }
                else {
                    Copy-Item -Path "$templatesSrc\*" -Destination $destTemplates -Recurse -Force
                    Write-Host "    templates: all (no manifest)"
                }
            }

            # Always bundle schemas (small, universally needed)
            $schemasSrc = Join-Path $ScriptDir "schemas"
            if (Test-Path $schemasSrc) {
                $destSchemas = Join-Path $destDir "assets\schemas"
                New-Item -ItemType Directory -Path $destSchemas -Force | Out-Null
                Copy-Item -Path "$schemasSrc\*" -Destination $destSchemas -Recurse -Force
            }

            # Bundle only declared standards (or all top-level if no manifest found)
            $standardsSrc = Join-Path $ScriptDir "standards"
            if (Test-Path $standardsSrc) {
                $destRefs = Join-Path $destDir "references"
                New-Item -ItemType Directory -Path $destRefs -Force | Out-Null
                if ($bundleStandards.Count -gt 0) {
                    foreach ($std in $bundleStandards) {
                        $stdPath = Join-Path $standardsSrc $std
                        if (Test-Path $stdPath) {
                            Copy-Item -Path $stdPath -Destination $destRefs -Force
                        }
                    }
                    Write-Host "    standards: selective ($($bundleStandards.Count) files)"
                }
                else {
                    # No manifest - copy all top-level standards (skip reference/ subdirectory)
                    Get-ChildItem -Path $standardsSrc -File | ForEach-Object {
                        Copy-Item -Path $_.FullName -Destination $destRefs -Force
                    }
                    Write-Host "    standards: all top-level (no manifest)"
                }
            }
        }
    }
}

function Write-PlanifestBootFile {
    # Boot files are disposable build outputs (0000029 ADR-001): always
    # regenerate from the current template so template fixes propagate on
    # every run. Durable local customization lives in
    # planifest-overrides/instructions/ and is re-applied by
    # Append-OverrideInstructions after this write.
    param($RelPath, $Content)

    $fullPath = Join-Path $ProjectRoot $RelPath
    $dir = Split-Path -Parent $fullPath
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    if (-not (Test-Path $fullPath)) {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  + $RelPath (created)"
    }
    else {
        Set-Content -Path $fullPath -Value $Content -Encoding UTF8
        Write-Host "  ~ $RelPath (regenerated from template)"
    }
}

function Copy-PlanifestWorkflow {
    param($WorkflowFile, $TargetDir)

    $name = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowFile)
    $destFile = Join-Path $TargetDir "$name.md"

    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Copy-Item -Path $WorkflowFile -Destination $destFile -Force
    Write-Host "  + workflows/$name.md"
}

function Merge-TelemetryHookSettings {
    # Merge context-pressure (PostToolUse), emit-phase-start (PreToolUse), and
    # emit-phase-end (Stop) hook entries into .claude/settings.json, plus the
    # emit_event receipt hook (PostToolUse, req-004/ADR-001). Idempotent: each
    # script's prior entry is removed before being re-added.
    #
    # Wiring design decision (req-001, feature 0000027) -- mirrors setup.sh's
    # Merge-TelemetryHookSettings/merge_telemetry_hook_settings: a single hook
    # `command` string is fixed at setup time and cannot vary the <phase>
    # argument emit-phase-start.mjs/emit-phase-end.mjs each require as the
    # pipeline moves through phases. Both entries below route through
    # hooks/telemetry/resolve-phase.mjs, which infers the active phase from an
    # observable tool-lifecycle signal (which phase-agent Skill was invoked)
    # and re-execs the real script with that phase supplied. See
    # resolve-phase.mjs's own header for the full mechanism.
    param(
        [string]$SettingsPath,
        [string]$HooksDir,
        [string]$BackendUrl
    )

    $pressureCmd = "PLANIFEST_TELEMETRY_URL=$BackendUrl node $HooksDir/context-pressure.mjs"
    $startCmd    = "PLANIFEST_TELEMETRY_URL=$BackendUrl node $HooksDir/resolve-phase.mjs start $HooksDir/emit-phase-start.mjs"
    $endCmd      = "PLANIFEST_TELEMETRY_URL=$BackendUrl node $HooksDir/resolve-phase.mjs end $HooksDir/emit-phase-end.mjs"
    $receiptCmd  = "node $HooksDir/emit-event-receipt.mjs"

    $postToolUseEntries = @(
        @{
            matcher = ".*"
            hooks = @(@{ type = "command"; command = $pressureCmd; async = $true; timeout = 5000 })
        },
        @{
            matcher = "mcp__structured-telemetry-mcp__emit_event"
            hooks = @(@{ type = "command"; command = $receiptCmd; async = $true; timeout = 5000 })
        }
    )
    $preToolUseEntry = @(
        @{
            matcher = "Skill"
            hooks = @(@{ type = "command"; command = $startCmd })
        }
    )
    $stopEntry = @(
        @{
            matcher = ".*"
            hooks = @(@{ type = "command"; command = $endCmd })
        }
    )

    if (Test-Path $SettingsPath) {
        $existing = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json

        if (-not $existing.hooks) {
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        if (-not $existing.hooks.PostToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PostToolUse' -NotePropertyValue @() -Force
        }
        if (-not $existing.hooks.PreToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @() -Force
        }
        if (-not $existing.hooks.Stop) {
            $existing.hooks | Add-Member -NotePropertyName 'Stop' -NotePropertyValue @() -Force
        }

        # Remove existing entries for each script then append the fresh ones.
        $filteredPost = @($existing.hooks.PostToolUse | Where-Object {
            $hooks = $_.hooks
            -not ($hooks | Where-Object { $_.command -match 'context-pressure' -or $_.command -match 'emit-event-receipt' })
        })
        $existing.hooks.PostToolUse = $filteredPost + $postToolUseEntries

        $filteredPre = @($existing.hooks.PreToolUse | Where-Object {
            $hooks = $_.hooks
            -not ($hooks | Where-Object { $_.command -match 'resolve-phase' -and $_.command -match 'emit-phase-start' })
        })
        $existing.hooks.PreToolUse = $filteredPre + $preToolUseEntry

        $filteredStop = @($existing.hooks.Stop | Where-Object {
            $hooks = $_.hooks
            -not ($hooks | Where-Object { $_.command -match 'resolve-phase' -and $_.command -match 'emit-phase-end' })
        })
        $existing.hooks.Stop = $filteredStop + $stopEntry

        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
        Write-Host "  ~ .claude/settings.json (telemetry hooks merged: context-pressure, emit-phase-start, emit-phase-end, emit-event-receipt)"
    }
    else {
        $dir = Split-Path -Parent $SettingsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        $settings = [PSCustomObject]@{
            hooks = [PSCustomObject]@{
                PostToolUse = $postToolUseEntries
                PreToolUse  = $preToolUseEntry
                Stop        = $stopEntry
            }
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
        Write-Host "  + .claude/settings.json (created with telemetry hooks: context-pressure, emit-phase-start, emit-phase-end, emit-event-receipt)"
    }
}

function Test-TelemetryHooksInstalled {
    # Positive-presence check (req-001, acceptance criterion): fails loudly if
    # any telemetry hook was copied to disk but never actually registered in
    # the target tool's settings -- the exact partial-wiring regression this
    # requirement exists to prevent from recurring silently. Static parity
    # with setup.sh's verify_telemetry_hooks_installed() / scripts/
    # verify-telemetry-hooks.mjs (no live PowerShell run required to verify
    # this parity -- see test-0000027-req-001-telemetry-hooks-wired.sh).
    param(
        [string]$SettingsPath,
        [string]$ScriptDirPath
    )

    $verifyScript = Join-Path $ScriptDirPath 'scripts/verify-telemetry-hooks.mjs'
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "  ! Warning: node not found -- skipping telemetry hook presence verification"
        return
    }

    & node $verifyScript $SettingsPath '--with-receipt'
    if ($LASTEXITCODE -ne 0) {
        throw "Telemetry hook presence check failed -- see output above."
    }
}

function Install-TelemetryHooks {
    # Copy context-pressure hook and wire PostToolUse in settings.json (REQ-008, REQ-010)
    # Only called when --structured-telemetry-mcp is active (0000018 req-001).
    param(
        [string]$HooksSrcRel,    # relative to ScriptDir  e.g. hooks/telemetry
        [string]$HooksDirRel,    # relative to ProjectRoot e.g. .claude/hooks/telemetry
        [string]$SettingsRel,    # relative to ProjectRoot e.g. .claude/settings.json
        [string]$BackendUrl
    )

    $src      = Join-Path $ScriptDir $HooksSrcRel
    $dest     = Join-Path $ProjectRoot $HooksDirRel
    $settings = Join-Path $ProjectRoot $SettingsRel

    if (-not (Test-Path $src)) {
        Write-Host "  ! Warning: telemetry hook scripts not found at $src — skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing structured telemetry hooks"

    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Get-ChildItem -Path $src -Filter '*.mjs' | ForEach-Object {
        $destFile = Join-Path $dest $_.Name
        Copy-Item -Path $_.FullName -Destination $destFile -Force
        Write-Host "  + $HooksDirRel/$($_.Name)"
    }

    Merge-TelemetryHookSettings -SettingsPath $settings -HooksDir $HooksDirRel -BackendUrl $BackendUrl
}

function Merge-EnforcementHookSettings {
    # Merge gate-write (PreToolUse), auto-trigger-orchestrator, check-orchestrator-presence,
    # check-design, check-telemetry-failures, and check-telemetry-receipts (UserPromptSubmit)
    # into settings.json.
    # check-telemetry-failures (0000026, backlog 0000044) and check-telemetry-receipts
    # (req-004, feature 0000027, ADR-001) are UserPromptSubmit-shaped like the other
    # enforcement hooks here, not PostToolUse like context-pressure.mjs, and are always
    # installed regardless of MCP flags. Idempotent.
    param(
        [string]$SettingsPath,
        [string]$HooksDir
    )

    $preToolEntry = @{
        matcher = 'Write|Edit'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/gate-write.mjs" })
    }
    $autoTriggerEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/auto-trigger-orchestrator.mjs" })
    }
    $presenceEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-orchestrator-presence.mjs" })
    }
    $userPromptEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-design.mjs" })
    }
    $telemetryFailuresEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-telemetry-failures.mjs" })
    }
    $telemetryReceiptsEntry = @{
        matcher = '.*'
        hooks   = @(@{ type = 'command'; command = "node $HooksDir/check-telemetry-receipts.mjs" })
    }

    if (Test-Path $SettingsPath) {
        $existing = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json

        if (-not $existing.hooks) {
            $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }

        # Merge PreToolUse — remove stale gate-write entry, append fresh one
        if (-not $existing.hooks.PreToolUse) {
            $existing.hooks | Add-Member -NotePropertyName 'PreToolUse' -NotePropertyValue @() -Force
        }
        $filtered = @($existing.hooks.PreToolUse | Where-Object {
            -not ($_.hooks | Where-Object { $_.command -match 'gate-write' })
        })
        $existing.hooks.PreToolUse = $filtered + $preToolEntry

        # Merge UserPromptSubmit — remove stale entries, append fresh ones in order
        if (-not $existing.hooks.UserPromptSubmit) {
            $existing.hooks | Add-Member -NotePropertyName 'UserPromptSubmit' -NotePropertyValue @() -Force
        }
        $filtered = @($existing.hooks.UserPromptSubmit | Where-Object {
            -not ($_.hooks | Where-Object {
                $_.command -match 'auto-trigger-orchestrator' -or
                $_.command -match 'check-orchestrator-presence' -or
                $_.command -match 'check-design' -or
                $_.command -match 'check-telemetry-failures' -or
                $_.command -match 'check-telemetry-receipts'
            })
        })
        $existing.hooks.UserPromptSubmit = $filtered + $autoTriggerEntry + $presenceEntry + $userPromptEntry + $telemetryFailuresEntry + $telemetryReceiptsEntry

        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
        Write-Host "  ~ .claude/settings.json (enforcement hook entries merged)"
    }
    else {
        $dir = Split-Path -Parent $SettingsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        $settings = [PSCustomObject]@{
            hooks = [PSCustomObject]@{
                PreToolUse       = @($preToolEntry)
                UserPromptSubmit = @($autoTriggerEntry, $presenceEntry, $userPromptEntry, $telemetryFailuresEntry, $telemetryReceiptsEntry)
            }
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
        Write-Host "  + .claude/settings.json (created with enforcement hook entries)"
    }
}

function Merge-AllowedTools {
    # Idempotently add "Agent" to allowedTools in .claude/settings.json (REQ-002).
    # Preserves existing allowedTools entries — additive merge only.
    param([string]$SettingsPath)

    $settings = @{}
    if (Test-Path $SettingsPath) {
        $raw = Get-Content -Raw -Path $SettingsPath -Encoding UTF8
        $settings = $raw | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
        if (-not $settings) { $settings = @{} }
    }

    $existing = if ($settings.ContainsKey('allowedTools') -and $settings['allowedTools']) {
        @($settings['allowedTools'])
    } else { @() }

    if ($existing -notcontains 'Agent') {
        $settings['allowedTools'] = $existing + @('Agent')
        $dir = Split-Path -Parent $SettingsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsPath -Encoding UTF8
        Write-Host "  ~ .claude/settings.json (Agent added to allowedTools)"
    } else {
        Write-Host "  - .claude/settings.json (Agent already in allowedTools)"
    }
}

function Install-EnforcementHooks {
    # Copy gate-write.mjs + check-design.mjs + check-telemetry-failures.mjs (0000026) and
    # wire settings.json. Always runs — no flag required.
    param(
        [string]$HooksSrcRel,
        [string]$HooksDirRel,
        [string]$SettingsRel
    )

    $src      = Join-Path $ScriptDir $HooksSrcRel
    $dest     = Join-Path $ProjectRoot $HooksDirRel
    $settings = Join-Path $ProjectRoot $SettingsRel

    if (-not (Test-Path $src)) {
        Write-Host "  ! Warning: enforcement hook scripts not found at $src — skipping"
        return
    }

    Write-Host ""
    Write-Host "  Installing Planifest enforcement hooks"

    New-Item -ItemType Directory -Path $dest -Force | Out-Null

    Get-ChildItem -Path $src -Filter '*.mjs' | ForEach-Object {
        $destFile = Join-Path $dest $_.Name
        Copy-Item -Path $_.FullName -Destination $destFile -Force
        Write-Host "  + $HooksDirRel/$($_.Name)"
    }

    Merge-EnforcementHookSettings -SettingsPath $settings -HooksDir $HooksDirRel
}

function Invoke-PlanifestGuardrails {
    Write-Host ""
    Write-Host "  Activating Planifest Git Guardrails"

    # Point Git to the version-controlled hooks directory
    git config core.hooksPath planifest-framework/hooks
    Write-Host "  + git config core.hooksPath planifest-framework/hooks"

    # Note: chmod is not available on Windows; hooks are made executable by setup.sh on Unix.
    # On Windows, Git for Windows respects the executable bit stored in the repo,
    # so no additional step is required here.

    # Deploy the CI/CD pipeline workflow
    $githubWorkflows = Join-Path $ProjectRoot '.github\workflows'
    $workflowSrc = Join-Path $ScriptDir 'hooks\planifest.yml'
    if (Test-Path $workflowSrc) {
        New-Item -ItemType Directory -Path $githubWorkflows -Force | Out-Null
        $dest = Join-Path $githubWorkflows 'planifest.yml'
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $workflowSrc -Destination $dest -Force
            Write-Host "  + .github/workflows/planifest.yml (created)"
        }
        else {
            Write-Host "  - .github/workflows/planifest.yml (already exists, skipped)"
        }
    }

    # Deploy .gitattributes to enforce LF endings on hook scripts.
    # Without this, Git for Windows re-adds CRLF on checkout, breaking the bash shebang.
    $gitattributesSrc = Join-Path $ScriptDir '.gitattributes'
    $gitattributesDest = Join-Path $ProjectRoot '.gitattributes'
    if (Test-Path $gitattributesSrc) {
        if (-not (Test-Path $gitattributesDest)) {
            Copy-Item -Path $gitattributesSrc -Destination $gitattributesDest -Force
            Write-Host "  + .gitattributes (created - enforces LF on hook scripts)"
        }
        else {
            Write-Host "  - .gitattributes (already exists, skipped)"
        }
    }

    Write-Host "  `u{2705} Git guardrails activated."
}

function Initialize-PlanifestRepo {
    Write-Host ""
    Write-Host "  Initializing Repository Structure"

    $gitignoreSrc = Join-Path $ScriptDir ".gitignore"
    $gitignoreDest = Join-Path $ProjectRoot ".gitignore"
    
    if (Test-Path $gitignoreSrc) {
        if (-not (Test-Path $gitignoreDest)) {
            Copy-Item -Path $gitignoreSrc -Destination $gitignoreDest
            Write-Host "  + .gitignore (copied)"
        }
        else {
            Write-Host "  - .gitignore (already exists at root, skipped)"
        }
    }
    else {
        Write-Host "  ! Warning: .gitignore not found in framework directory ($gitignoreSrc)"
    }

    $srcDir = Join-Path $ProjectRoot "src"
    if (-not (Test-Path $srcDir)) {
        New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
        Write-Host "  + src/ (created)"
    }
    
    $srcReadme = Join-Path $srcDir "README.md"
    if (-not (Test-Path $srcReadme)) {
        Set-Content -Path $srcReadme -Value @'
# src/

Components live here. Each component is a subfolder with a `component.yml` manifest.

See [planifest/spec/feature-structure.md](../planifest/spec/feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + src/README.md (created)"
    }

    $planDir = Join-Path $ProjectRoot "plan"
    if (-not (Test-Path $planDir)) {
        New-Item -ItemType Directory -Path $planDir -Force | Out-Null
        Write-Host "  + plan/ (created)"
    }
    
    $planReadme = Join-Path $planDir "README.md"
    if (-not (Test-Path $planReadme)) {
        Set-Content -Path $planReadme -Value @'
# plan/

Feature specifications live here. Each feature gets a subfolder.

See [plan/feature-structure.md](feature-structure.md) for the canonical layout.
'@ -Encoding UTF8
        Write-Host "  + plan/README.md (created)"
    }

    $planStructure = Join-Path $planDir "feature-structure.md"
    if (-not (Test-Path $planStructure)) {
        Set-Content -Path $planStructure -Value @'
# Planifest - Repository Structure

> The canonical layout for a Planifest-managed repository. Three top-level folders, three concerns.

---

## The Three Folders

```
repo/
+-- planifest-framework/        <- The framework (skills, templates, schemas, standards)
|                                  Drop this in. Don't modify it per-project.
|
+-- plan/                       <- The specifications (organized by feature)
|                                  Plans, briefs, specs, ADRs, risk, scope, glossary.
|                                  Everything that describes WHAT to build and WHY.
|
+-- src/                        <- The code (organized by component)
                                   Implementation, tests, config, manifests.
                                   Everything that IS the built thing.
```

---

## `planifest-framework/` - The Framework

This folder is the Planifest framework itself. It is the same across every project. You do not modify it per-feature - you update it when the framework evolves.

```
planifest/
+-- skills/           <- Agent instructions (orchestrator + phase skills)
+-- templates/        <- File format templates for every artifact
+-- schemas/          <- JSON Schema validation definitions
+-- standards/        <- Code quality standards
+-- spec/             <- This file - the canonical structure definition
```

---

## `plan/` - The Plan/Specifications

Organized by feature. Each feature gets a subfolder. This is where humans write briefs and agents write specs. No code lives here.

```
plan/
+-- {feature-id}/
    +-- feature-brief.md          <- Human input (start here)
    +-- design.md                 <- Validated plan (orchestrator output)
    +-- pipeline-run.md              <- Audit trail (per run)
    +-- pipeline-run-phase-2.md      <- Phase 2 audit (if phased)
    |
    +-- design-requirements.md               <- Functional & non-functional requirements
    +-- design-spec-phase-2.md       <- Phase 2 spec (if phased)
    +-- openapi-spec.yaml            <- API contract
    +-- scope.md                     <- In / Out / Deferred
    +-- risk-register.md             <- Risk items with likelihood & impact
    +-- domain-glossary.md           <- Ubiquitous language
    +-- security-report.md           <- Security review findings
    +-- quirks.md                    <- Quirks and workarounds
    +-- recommendations.md           <- Improvement suggestions
    |
    +-- adr/
        +-- ADR-001-{title}.md       <- Architecture decision records
        +-- ADR-002-{title}.md
        +-- ...
```

### Path Rules - plan/

1. **Feature ID** follows the format `{0000000}-{kebab-case-name}` - a 7-digit zero-padded number prefix for chronological ordering, followed by a human-chosen kebab-case name.
2. **No nesting** - specs, ADRs, and supporting docs are flat within the feature folder. One level of subfolders only (adr/).
3. **No code** - nothing executable lives in `plan/`. If it runs, it belongs in `src/`.
4. **Phased features** append the phase number: `design-spec-phase-2.md`, `pipeline-run-phase-2.md`. The `design.md` is updated per phase, not duplicated.
5. **ADRs** are numbered sequentially. Never renumber. Superseded ADRs stay with `status: superseded`.

---

## `src/` - The Code

Organized by component. Each component is a subfolder at the top level of `src/`. The component manifest lives with the code, not with the plan.

```
src/
+-- {component-id}/
    +-- component.yml               <- Component manifest (from template)
    +-- package.json                  <- (or equivalent for the stack)
    |
    +-- src/                          <- Implementation (structure varies by stack)
    |   +-- ...
    |
    +-- tests/                        <- Tests
    |   +-- ...
    |
    +-- docs/
        +-- data-contract.md          <- Schema ownership & invariants
        +-- migrations/
            +-- proposed-{desc}.md    <- Migration proposals
```

### Path Rules - src/

1. **Component ID** is kebab-case, matches the `id` in `component.yml`.
2. **component.yml is mandatory** - every component has one. Read it before any work; update it after every build.
3. **Component-specific docs** live with the component at `src/{component-id}/docs/`. These describe the component's data contract, migrations, and technical specifics.
4. **Feature-level docs** live in `plan/`. The component's `component.yml` references the feature via the `feature` field.
5. **Existing components** that predate Planifest are retrofitted by adding a `component.yml` at their root.

---

## How the Three Folders Connect

```
plan/current/design.md
    +-- lists component IDs -> src/{component-id}/component.yml
                                    +-- references feature -> plan/

plan/current/design-requirements.md
    +-- functional requirements -> implemented in -> src/{component-id}/src/

plan/current/adr/ADR-001-*.md
    +-- decisions -> followed by -> src/{component-id}/src/

plan/current/openapi-spec.yaml
    +-- API contract -> implemented in -> src/{component-id}/src/
```

The relationship is bidirectional:
- `design.md` lists all component IDs
- Each `component.yml` references its feature ID
- The plan describes WHAT; the code IS the WHAT

---

## Retrofit Ã¢â‚¬â€ Adding Planifest to an Existing Repo

If the repo already has code:

1. Drop `planifest/` into the repo root
2. Create `plan/` for the first feature
3. Move existing components under `src/` (or leave them if they're already there)
4. Add a `component.yml` to each existing component
5. The orchestrator's retrofit mode will read the codebase and infer the existing architecture

---

*Templates for each file are in [planifest/templates/](../templates/). Skills reference these paths.*
'@ -Encoding UTF8
        Write-Host "  + plan/feature-structure.md (created)"
    }

    # Add tool ignore rules to keep context windows lean
    $ignoreContent = @"

# Planifest - Token Reduction (keeps agent semantic search from bloating context)
plan/_archive/
node_modules/
dist/
build/
out/
.next/
"@

    $ignoreFile = '.claudeignore'
    $ignorePath = Join-Path $ProjectRoot $ignoreFile
    if (-not (Test-Path $ignorePath)) {
        Set-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
        Write-Host "  + $ignoreFile (created)"
    }
    else {
        $existing = Get-Content -Path $ignorePath -Raw
        if ($existing -notmatch "Planifest - Token Reduction") {
            Add-Content -Path $ignorePath -Value $ignoreContent -Encoding UTF8
            Write-Host "  + $ignoreFile (appended Planifest ignore rules)"
        }
    }
}

function Copy-CapabilitySkills {
    # Copies permanent capability skills from planifest-overrides/capability-skills/
    # into the tool's skill directory (ADR-006). The tool discovers them the same way
    # it discovers built-in skills — no separate registry file needed.
    param($TargetDir)

    $capSkillsDir = Join-Path $ProjectRoot 'planifest-overrides\capability-skills'
    if (-not (Test-Path $capSkillsDir)) { return }

    $found = @(Get-ChildItem -Path $capSkillsDir -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName 'SKILL.md')
    })
    if ($found.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Syncing capability skills from planifest-overrides/capability-skills/"
    foreach ($dir in $found) {
        $destDir = Join-Path $TargetDir $dir.Name
        Copy-Item -Path $dir.FullName -Destination $destDir -Recurse -Force
        Write-Host "  + capability-skill: $($dir.Name)"
    }
}

function Append-OverrideInstructions {
    # Appends project-specific instructions from planifest-overrides/instructions/
    # to the tool's boot file. Idempotent — strips and replaces the override block
    # on every re-run so changes in planifest-overrides/ are always reflected.
    param($BootFilePath)

    $bootPath = Join-Path $ProjectRoot $BootFilePath
    if (-not (Test-Path $bootPath)) { return }

    $startMarker = '<!-- planifest-overrides:instructions:start -->'
    $endMarker   = '<!-- planifest-overrides:instructions:end -->'

    # Strip any existing override block from a previous run
    $current = Get-Content -Path $bootPath -Raw
    if ($current -match [regex]::Escape($startMarker)) {
        $pattern = "(?s)\r?\n$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))\r?\n?"
        $current = [regex]::Replace($current, $pattern, '')
        Set-Content -Path $bootPath -Value $current.TrimEnd() -Encoding UTF8 -NoNewline
    }

    $instrDir = Join-Path $ProjectRoot 'planifest-overrides\instructions'
    if (-not (Test-Path $instrDir)) { return }
    $files = @(Get-ChildItem -Path $instrDir -File -Filter '*.md' | Sort-Object Name)
    if ($files.Count -eq 0) { return }

    Write-Host ""
    Write-Host "  Appending override instructions from planifest-overrides/instructions/"

    $block = "`n`n$startMarker`n"
    foreach ($file in $files) {
        $block += "`n" + (Get-Content -Path $file.FullName -Raw).TrimEnd() + "`n"
        Write-Host "  + $($file.Name)"
    }
    $block += "`n$endMarker"

    Add-Content -Path $bootPath -Value $block -Encoding UTF8
    Write-Host "  ~ $BootFilePath updated with override instructions"
}

function Invoke-PlanifestSetup {
    param($ToolName)

    $toolConfigPath = Join-Path $SetupDir "$ToolName.ps1"
    if (-not (Test-Path $toolConfigPath)) {
        Write-Host "Error: no config file at setup/$ToolName.ps1"
        exit 1
    }

    # Load tool-specific config
    $toolConfig = & $toolConfigPath

    $skillsDir = Join-Path $ProjectRoot $toolConfig.SkillsDir

    Write-Host ""
    Write-Host "  Setting up $ToolName"
    Write-Host "  Skills directory: $($toolConfig.SkillsDir)/"

    # Manifest cleanup — remove only previously installed directories on re-run
    $manifest = Join-Path $skillsDir ".planifest-manifest"
    if (Test-Path $manifest) {
        Write-Host "  Re-run detected — removing previously installed directories"
        Get-Content -Path $manifest | Where-Object { $_ -ne '' } | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item -Path $_ -Recurse -Force
                Write-Host "  - removed: $(Split-Path -Leaf $_)"
            }
        }
        Remove-Item -Path $manifest -Force
    }

    # Copy skills (now automatically bundles supporting files)
    Copy-PlanifestSkills -TargetDir $skillsDir

    # Copy permanent capability skills from planifest-overrides/ (ADR-006)
    Copy-CapabilitySkills -TargetDir $skillsDir

    # Copy workflows (if tool defines a workflow dir)
    if ($toolConfig.WorkflowsDir -and (Test-Path $WorkflowsSrc)) {
        $workflowsDir = Join-Path $ProjectRoot $toolConfig.WorkflowsDir
        Get-ChildItem -Path $WorkflowsSrc -Filter '*.md' | ForEach-Object {
            Copy-PlanifestWorkflow -WorkflowFile $_.FullName -TargetDir $workflowsDir
        }
    }

    # Create boot file (if tool defines one)
    if ($toolConfig.BootFile) {
        $bootContent = $toolConfig.BootContent
        if (-not $bootContent -and $toolConfig.BootTemplate) {
            $bootContentPath = Join-Path $ProjectRoot $toolConfig.BootTemplate
            $bootContent = Get-Content -Raw -Path $bootContentPath
        }
        Write-PlanifestBootFile -RelPath $toolConfig.BootFile -Content $bootContent
    }

    # Append project-specific instructions to boot file (idempotent on re-run)
    if ($toolConfig.BootFile) {
        Append-OverrideInstructions -BootFilePath $toolConfig.BootFile
    }

    # Install Planifest enforcement hooks unconditionally (gate-write, check-design)
    if ($toolConfig.EnforcementHooksSrc -and $toolConfig.EnforcementHooksDir -and $toolConfig.SettingsFile) {
        Install-EnforcementHooks `
            -HooksSrcRel $toolConfig.EnforcementHooksSrc `
            -HooksDirRel $toolConfig.EnforcementHooksDir `
            -SettingsRel $toolConfig.SettingsFile
    }

    # Add Agent to allowedTools so sub-agent dispatch works without per-use confirmation (REQ-002)
    if ($toolConfig.SettingsFile) {
        $settingsPath = Join-Path $ProjectRoot $toolConfig.SettingsFile
        Merge-AllowedTools -SettingsPath $settingsPath
    }

    # Write telemetry opt-in sentinel so skills know emission is authorised (REQ-004)
    if ($StructuredTelemetryMcp) {
        $sentinel = Join-Path $ProjectRoot '.claude\telemetry-enabled'
        $sentinelDir = Split-Path -Parent $sentinel
        if (-not (Test-Path $sentinelDir)) { New-Item -ItemType Directory -Path $sentinelDir -Force | Out-Null }
        if (-not (Test-Path $sentinel)) {
            New-Item -ItemType File -Path $sentinel -Force | Out-Null
            Write-Host "  + .claude/telemetry-enabled (telemetry opt-in sentinel)"
        } else {
            Write-Host "  - .claude/telemetry-enabled (already exists)"
        }
    }

    # Install telemetry hooks whenever --structured-telemetry-mcp is active (0000018 req-001)
    if ($StructuredTelemetryMcp -and
        $toolConfig.TelemetryHooksSrc -and $toolConfig.TelemetryHooksDir -and $toolConfig.SettingsFile) {
        Install-TelemetryHooks `
            -HooksSrcRel  $toolConfig.TelemetryHooksSrc `
            -HooksDirRel  $toolConfig.TelemetryHooksDir `
            -SettingsRel  $toolConfig.SettingsFile `
            -BackendUrl   $BackendUrl
        Test-TelemetryHooksInstalled `
            -SettingsPath (Join-Path $ProjectRoot $toolConfig.SettingsFile) `
            -ScriptDirPath $ScriptDir
    }

    # Write manifest listing all installed skill directories (enables safe re-run cleanup)
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    $installedDirs = @(Get-ChildItem -Path $skillsDir -Directory | ForEach-Object { $_.FullName })
    if ($installedDirs.Count -gt 0) {
        $installedDirs | Set-Content -Path $manifest -Encoding UTF8
        Write-Host "  + .planifest-manifest ($($installedDirs.Count) entries)"
    }

    # Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
    # Guarded on SkillsDir being present so a tool config without one skips silently
    # rather than erroring under $ErrorActionPreference = 'Stop'.
    if ($toolConfig -and $toolConfig.SkillsDir) {
        $toolDir = Split-Path -Parent $toolConfig.SkillsDir
        Write-SetupConfigOverride -ToolName $ToolName | Out-Null
        Write-SetupFlagsMarker -ToolName $ToolName -ToolDir $toolDir
    }

    Write-Host "  Done."
}

# Write planifest-overrides/setup-config/{tool}.md — the tracked, git-versioned source
# of truth for active setup flags/backendUrl (0000025 req-004, ADR-002 decision 1). This
# is additive: it does not replace Write-SetupFlagsMarker, and it is called BEFORE it so
# the gitignored marker is always (re)written to match this file's values for the current
# run (ADR-002 decision 3). On failure to write (e.g. permissions), warns and returns
# $false so the caller falls back to existing marker-only behavior rather than aborting
# setup (req-004 acceptance criteria, sad path).
function Write-SetupConfigOverride {
    param($ToolName)

    $configDir = Join-Path $ProjectRoot 'planifest-overrides\setup-config'
    $configFile = Join-Path $configDir "$ToolName.md"

    $flags = @()
    if ($StructuredTelemetryMcp) { $flags += '--structured-telemetry-mcp' }
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $backendUrlValue = if ($StructuredTelemetryMcp) { $BackendUrl } else { $null }
    $writtenAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $configJson = [ordered]@{
        tool       = $ToolName
        flags      = $flags
        backendUrl = $backendUrlValue
        writtenAt  = $writtenAt
    } | ConvertTo-Json -Depth 10

    $fence = [char]96 + [char]96 + [char]96
    $content = "# Setup config: $ToolName`n`n" +
        "> Tracked source of truth for active setup flags/backend-url for **$ToolName**`n" +
        "> (0000025 req-004, ADR-002). The gitignored ``.planifest-setup-flags`` marker in`n" +
        "> this tool's config directory is a local completion-status cache, reconciled to`n" +
        "> match this file on every ``setup.sh``/``setup.ps1`` run.`n`n" +
        "$fence" + "json`n$configJson`n$fence`n"

    try {
        New-Item -ItemType Directory -Path $configDir -Force -ErrorAction Stop | Out-Null
        Set-Content -Path $configFile -Value $content -Encoding UTF8 -ErrorAction Stop
        Write-Host "  + planifest-overrides\setup-config\$ToolName.md"
        return $true
    } catch {
        Write-Warning "Could not write planifest-overrides/setup-config/$ToolName.md — continuing with .planifest-setup-flags-only behavior"
        return $false
    }
}

# Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
# Called only after a tool's setup completes successfully. $ErrorActionPreference = 'Stop' means
# a failed Invoke-PlanifestSetup call halts the script before this function is ever reached,
# satisfying REQ-008's "a failed install does not write the marker" requirement.
function Write-SetupFlagsMarker {
    param($ToolName, $ToolDir)

    $targetDir = Join-Path $ProjectRoot $ToolDir
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $markerPath = Join-Path $targetDir '.planifest-setup-flags'

    $flags = @()
    if ($StructuredTelemetryMcp) { $flags += '--structured-telemetry-mcp' }
    if ($StrictOrchestrator) { $flags += '--strict-orchestrator' }

    $marker = [ordered]@{
        tool          = $ToolName
        flags         = $flags
        backendUrl    = if ($StructuredTelemetryMcp) { $BackendUrl } else { $null }
        writtenAt     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        attemptStatus = 'completed'
    }

    $marker | ConvertTo-Json -Depth 10 | Set-Content -Path $markerPath -Encoding UTF8
    Write-Host "  + $ToolDir\.planifest-setup-flags"
}

# --- Main ---

if (-not $Tool) {
    Write-Host ""
    Write-Host "Planifest Setup"
    Write-Host ""
    Write-Host "Usage: .\planifest-framework\setup.ps1 claude-code [flags]"
    Write-Host ""
    Write-Host "Tools:"
    foreach ($t in $ValidTools) {
        Write-Host "  $t"
    }
    Write-Host ""
    Write-Host "Flags:"
    Write-Host "  --structured-telemetry-mcp   Install structured telemetry hooks."
    Write-Host "  --backend-url <url>          Override telemetry backend URL (default: http://localhost:3741)"
    Write-Host "  --strict-orchestrator        Write plan/.orchestrator-strict to enable strict mode."
    Write-Host "                               The check-orchestrator-presence hook will require the"
    Write-Host "                               orchestrator to ack each new session before proceeding."
    Write-Host ""
    Write-Host "Run from the repository root."
    Write-Host "Each tool's config: planifest-framework\setup\[tool].ps1"
    exit 0
}

Write-Host "Planifest Setup"
Write-Host ("=" * 40)

Initialize-PlanifestRepo
Invoke-PlanifestGuardrails

# Write strict-mode sentinel if --strict-orchestrator flag was passed (REQ-008)
if ($StrictOrchestrator) {
    $planDir = Join-Path $ProjectRoot 'plan'
    New-Item -ItemType Directory -Path $planDir -Force | Out-Null
    $strictPath = Join-Path $planDir '.orchestrator-strict'
    New-Item -ItemType File -Path $strictPath -Force | Out-Null
    Write-Host "  + plan/.orchestrator-strict (strict orchestrator mode enabled)"
}

$ToolLower = $Tool.ToLower()

if ($ValidTools -contains $ToolLower) {
    Invoke-PlanifestSetup -ToolName $ToolLower
}
else {
    Write-Host "Unknown tool: $Tool"
    Write-Host "Valid tools: $($ValidTools -join ', ')"
    exit 1
}

Write-Host ""
Write-Host "Setup complete."
Write-Host "  Source of truth: planifest-framework/"
Write-Host "  Re-run after updating framework files."

