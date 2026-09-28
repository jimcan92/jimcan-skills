<#
.SYNOPSIS
    Automated AI Agent Skills Setup for Jimcan's Environment (Windows PowerShell)

.DESCRIPTION
    Installs Jimcan's personal preferences, rules, and prompts, and downloads
    curated community skills (Andrej Karpathy guidelines, Svelte 5/UI skills,
    FastAPI/DB backend skills) into the global AI agent skills configuration directory.
    Compatible with Claude Code, Cursor, Windsurf, Antigravity, and other AI coding assistants.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\setup.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   Jimcan's AI Agent Skills & Preferences Installer      " -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# Define destination directories
$geminiConfigDir = Join-Path -Path $HOME -ChildPath ".gemini\config"
$pluginsDir      = Join-Path -Path $geminiConfigDir -ChildPath "plugins"
$globalSkillsDir = Join-Path -Path $geminiConfigDir -ChildPath "skills"
$repoRoot        = $PSScriptRoot

# Ensure base directories exist
foreach ($dir in @($geminiConfigDir, $pluginsDir, $globalSkillsDir)) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Download-SkillFile {
    param(
        [string]$Url,
        [string]$OutFile
    )
    $parent = Split-Path -Path $OutFile -Parent
    if (-not (Test-Path -Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($Url, $OutFile)
        return $true
    }
    catch {
        Write-Warning "Failed to download $Url : $_"
        return $false
    }
}

# -----------------------------------------------------------------------------
# 1. Install Jimcan's Personal Preferences & Rules
# -----------------------------------------------------------------------------
Write-Host "[1/4] Installing jimcan-dev-preferences..." -ForegroundColor Green

$srcPref = Join-Path -Path $repoRoot -ChildPath "plugins\jimcan-dev-preferences"
$destPref = Join-Path -Path $pluginsDir -ChildPath "jimcan-dev-preferences"

if (Test-Path -Path $srcPref) {
    Copy-Item -Path $srcPref -Destination $pluginsDir -Recurse -Force
    
    # Also sync skill to global skills folder
    $skillSrc = Join-Path -Path $srcPref -ChildPath "skills\jimcan-dev-preferences"
    if (Test-Path -Path $skillSrc) {
        $skillDest = Join-Path -Path $globalSkillsDir -ChildPath "jimcan-dev-preferences"
        Copy-Item -Path $skillSrc -Destination $globalSkillsDir -Recurse -Force
    }
    Write-Host "  -> Installed jimcan-dev-preferences (plugin & global skill)" -ForegroundColor DarkGreen
} else {
    Write-Warning "Source directory $srcPref not found!"
}

# Install embedded-esp32-skills
$srcEsp = Join-Path -Path $repoRoot -ChildPath "plugins\embedded-esp32-skills"
if (Test-Path -Path $srcEsp) {
    Copy-Item -Path $srcEsp -Destination $pluginsDir -Recurse -Force
    $espSkillSrc = Join-Path -Path $srcEsp -ChildPath "skills\esp32-embedded-patterns"
    if (Test-Path -Path $espSkillSrc) {
        $espSkillDest = Join-Path -Path $globalSkillsDir -ChildPath "esp32-embedded-patterns"
        Copy-Item -Path $espSkillSrc -Destination $globalSkillsDir -Recurse -Force
    }
    Write-Host "  -> Installed embedded-esp32-skills (plugin & global skill)" -ForegroundColor DarkGreen
}

# -----------------------------------------------------------------------------
# 2. Download / Install Andrej Karpathy Skills
# -----------------------------------------------------------------------------
Write-Host "`n[2/4] Installing andrej-karpathy-skills..." -ForegroundColor Green

$karpathyDest = Join-Path -Path $pluginsDir -ChildPath "andrej-karpathy-skills"
$gitAvailable = (Get-Command git -ErrorAction SilentlyContinue)

if ($gitAvailable) {
    if (Test-Path -Path (Join-Path -Path $karpathyDest -ChildPath ".git")) {
        Write-Host "  -> Updating existing repo at $karpathyDest..." -ForegroundColor DarkGray
        git -C $karpathyDest pull --quiet
    } else {
        if (Test-Path -Path $karpathyDest) {
            Remove-Item -Path $karpathyDest -Recurse -Force
        }
        Write-Host "  -> Cloning https://github.com/multica-ai/andrej-karpathy-skills.git..." -ForegroundColor DarkGray
        git clone --depth 1 https://github.com/multica-ai/andrej-karpathy-skills.git $karpathyDest --quiet
    }
} else {
    Write-Warning "Git not detected in PATH. Skipping git clone for andrej-karpathy-skills."
}

# Sync Karpathy skills to global skills directory if available
$karpathySkillsSrc = Join-Path -Path $karpathyDest -ChildPath "skills"
if (Test-Path -Path $karpathySkillsSrc) {
    Get-ChildItem -Path $karpathySkillsSrc -Directory | ForEach-Object {
        $dest = Join-Path -Path $globalSkillsDir -ChildPath $_.Name
        Copy-Item -Path $_.FullName -Destination $globalSkillsDir -Recurse -Force
    }
    Write-Host "  -> Synced karpathy skills to global directory" -ForegroundColor DarkGreen
}

# -----------------------------------------------------------------------------
# 3. Download & Install UI Design Skills (Svelte 5, daisyUI, shadcn)
# -----------------------------------------------------------------------------
Write-Host "`n[3/4] Downloading UI Design Skills..." -ForegroundColor Green

$uiPluginDir = Join-Path -Path $pluginsDir -ChildPath "ui-design-skills"
$uiManifest = @{
    name        = "ui-design-skills"
    displayName = "UI Design System Skills"
    version     = "1.0.0"
    description = "Svelte, Svelte 5, shadcn-svelte, and daisyUI skills"
} | ConvertTo-Json -Depth 3

$uiPluginJsonPath = Join-Path -Path $uiPluginDir -ChildPath "plugin.json"
$uiParent = Split-Path -Path $uiPluginJsonPath -Parent
if (-not (Test-Path -Path $uiParent)) { New-Item -ItemType Directory -Path $uiParent -Force | Out-Null }
Set-Content -Path $uiPluginJsonPath -Value $uiManifest -Encoding UTF8

$uiSkills = @{
    'shadcn-svelte'             = 'https://raw.githubusercontent.com/huntabyte/shadcn-svelte/main/skills/shadcn-svelte/SKILL.md'
    'svelte-core-bestpractices' = 'https://raw.githubusercontent.com/sveltejs/ai-tools/main/tools/skills/svelte-core-bestpractices/SKILL.md'
    'svelte-code-writer'        = 'https://raw.githubusercontent.com/sveltejs/ai-tools/main/tools/skills/svelte-code-writer/SKILL.md'
    'svelte5-best-practices'    = 'https://raw.githubusercontent.com/ejirocodes/agent-skills/main/svelte/skills/svelte5-best-practices/SKILL.md'
    'daisyui'                   = 'https://raw.githubusercontent.com/saadeghi/daisyui/master/skills/daisyui/SKILL.md'
}

foreach ($skill in $uiSkills.GetEnumerator()) {
    $sName = $skill.Key
    $sUrl  = $skill.Value
    
    $pluginSkillPath = Join-Path -Path $uiPluginDir -ChildPath "skills\$sName\SKILL.md"
    $globalSkillPath = Join-Path -Path $globalSkillsDir -ChildPath "$sName\SKILL.md"

    if (Download-SkillFile -Url $sUrl -OutFile $pluginSkillPath) {
        Copy-Item -Path $pluginSkillPath -Destination $globalSkillPath -Force
        Write-Host "  -> Downloaded: $sName" -ForegroundColor DarkGreen
    }
}

# -----------------------------------------------------------------------------
# 4. Download & Install Backend & Database Skills
# -----------------------------------------------------------------------------
Write-Host "`n[4/4] Downloading Backend & Database Skills..." -ForegroundColor Green

$backendPluginDir = Join-Path -Path $pluginsDir -ChildPath "backend-db-skills"
$backendManifest = @{
    name        = "backend-db-skills"
    displayName = "Backend & Database Skills"
    version     = "1.0.0"
    description = "FastAPI, Drizzle ORM, Better Auth, PostgreSQL, and MySQL skills"
} | ConvertTo-Json -Depth 3

$backendPluginJsonPath = Join-Path -Path $backendPluginDir -ChildPath "plugin.json"
$backendParent = Split-Path -Path $backendPluginJsonPath -Parent
if (-not (Test-Path -Path $backendParent)) { New-Item -ItemType Directory -Path $backendParent -Force | Out-Null }
Set-Content -Path $backendPluginJsonPath -Value $backendManifest -Encoding UTF8

$backendSkills = @{
    'fastapi-patterns'                 = 'https://raw.githubusercontent.com/affaan-m/ecc/main/skills/fastapi-patterns/SKILL.md'
    'drizzle-best-practices'           = 'https://raw.githubusercontent.com/honra-io/drizzle-best-practices/main/SKILL.md'
    'better-auth-best-practices'       = 'https://raw.githubusercontent.com/better-auth/skills/main/better-auth/best-practices/SKILL.md'
    'postgres-patterns'                = 'https://raw.githubusercontent.com/affaan-m/ecc/main/skills/postgres-patterns/SKILL.md'
    'supabase-postgres-best-practices' = 'https://raw.githubusercontent.com/supabase/agent-skills/main/skills/supabase-postgres-best-practices/SKILL.md'
    'mysql-patterns'                   = 'https://raw.githubusercontent.com/affaan-m/ecc/main/skills/mysql-patterns/SKILL.md'
    'planetscale-mysql'                = 'https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md'
}

foreach ($skill in $backendSkills.GetEnumerator()) {
    $sName = $skill.Key
    $sUrl  = $skill.Value

    $pluginSkillPath = Join-Path -Path $backendPluginDir -ChildPath "skills\$sName\SKILL.md"
    $globalSkillPath = Join-Path -Path $globalSkillsDir -ChildPath "$sName\SKILL.md"

    if (Download-SkillFile -Url $sUrl -OutFile $pluginSkillPath) {
        Copy-Item -Path $pluginSkillPath -Destination $globalSkillPath -Force
        Write-Host "  -> Downloaded: $sName" -ForegroundColor DarkGreen
    }
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   Setup Completed Successfully!                         " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Installed in: $geminiConfigDir" -ForegroundColor Yellow
Write-Host "Your AI agents are now configured with Jimcan's preferences & skills.`n" -ForegroundColor Yellow
