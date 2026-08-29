$repoDir = "C:\d\planifest\framework\"

# Refresh Framework - not required as this IS the framework

# Remove Claude
Remove-Item -Path "$repoDir\.claude\" -Recurse -EA SilentlyContinue
Remove-Item -Path "$repoDir\AGENTS.md" -EA SilentlyContinue
Remove-Item -Path "$repoDir\CLAUDE.md" -EA SilentlyContinue

# Re-add Claude
Set-Location $repoDir
.\planifest-framework\setup.ps1 claude-code --structured-telemetry-mcp
