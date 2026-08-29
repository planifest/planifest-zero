# Refresh the Claude Code install for this repository.
# Derives the repo directory from the script's own location.
$repoDir = $PSScriptRoot

# Remove the installed tree
Remove-Item -Path (Join-Path $repoDir ".claude") -Recurse -EA SilentlyContinue
Remove-Item -Path (Join-Path $repoDir "AGENTS.md") -EA SilentlyContinue
Remove-Item -Path (Join-Path $repoDir "CLAUDE.md") -EA SilentlyContinue

# Re-add Claude Code
Set-Location $repoDir
.\planifest-zero\setup.ps1 claude-code --structured-telemetry-mcp
