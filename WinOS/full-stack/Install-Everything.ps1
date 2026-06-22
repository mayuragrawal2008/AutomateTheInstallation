# ==============================================================================
# Claude Code Full Stack Installer  (UI/UX Resources doc - everything)
# ------------------------------------------------------------------------------
# AUTHOR: Mayur Agrawal
# LAST REVIEW: 22 June 2026 14:30
# ------------------------------------------------------------------------------
# Installs, with no prompts where possible:
#   - Prerequisites : Git for Windows, Node.js LTS (via winget if missing)
#   - Claude Code    : Anthropic official native installer
#   - Skills         : git-cloned into the personal skills folder
#   - caveman plugin : token compression
#   - MCP servers    : supermemory, Supabase, 21st.dev Magic, TestSprite, Vercel
#
# FULLY UNATTENDED ONLY IF the matching secrets are supplied (see CONFIG below).
# Servers that are OAuth-only (supermemory, Vercel, Stitch) are registered
# silently; they still need a single browser sign-in the first time you use them.
#
# HOW TO RUN: double-click Install-Everything.cmd  (recommended).
# Administrator rights are NOT required. Safe to re-run; existing items skip.
# ==============================================================================

$ErrorActionPreference = 'Continue'

# ------------------------------------------------------------------------------
# CONFIG - secrets default to environment variables (recommended, keeps them out
# of this file). You may hard-code values instead, but they will sit in plaintext.
# Leave a value blank to skip that piece.
# ------------------------------------------------------------------------------
$Config = @{
    # Set this to make 'claude' run without a browser login (uses API billing,
    # NOT a Pro/Max subscription). Leave blank to sign in manually once.
    AnthropicApiKey         = $env:ANTHROPIC_API_KEY

    # Supabase: project ref alone = OAuth on first use. Add a PAT for headless.
    SupabaseProjectRef      = $env:SUPABASE_PROJECT_REF
    SupabasePat             = $env:SUPABASE_ACCESS_TOKEN

    MagicApiKey             = $env:TWENTYFIRST_API_KEY    # 21st.dev Magic
    TestSpriteApiKey        = $env:TESTSPRITE_API_KEY

    InstallVercelMcp        = $true                       # OAuth on first use
    IncludeMegaSkillLibrary = $false                      # 338+ skills; off by default
}

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
function Write-Section {
    param([string]$Text)
    Write-Host ''
    Write-Host '======================================================'
    Write-Host $Text
    Write-Host '======================================================'
}

function Get-ConfigValue {
    param($Value)
    if ($null -eq $Value) { return '' }
    return ([string]$Value).Trim()
}

function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($machinePath, $userPath | Where-Object { $_ })
    $env:Path = ($parts -join ';')
}

function Test-CommandExists {
    param([string]$Name)
    $found = Get-Command $Name -ErrorAction SilentlyContinue
    return [bool]$found
}

function Get-NodeMajorVersion {
    if (-not (Test-CommandExists 'node')) { return 0 }
    try {
        $raw = (& node -v) 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $raw) { return 0 }
        $clean = $raw.Trim().TrimStart('v')
        return [int]($clean.Split('.')[0])
    } catch {
        return 0
    }
}

function Invoke-WingetInstall {
    param([string]$PackageId, [string]$FriendlyName)
    if (-not (Test-CommandExists 'winget')) {
        Write-Host ('winget not available - cannot auto-install {0}.' -f $FriendlyName)
        return $false
    }
    Write-Host ('Installing {0} via winget (a UAC prompt may appear) ...' -f $FriendlyName)
    try {
        & winget install --id $PackageId -e --accept-source-agreements --accept-package-agreements --silent
        Update-SessionPath
        return $true
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ('Automatic {0} install failed: {1}' -f $FriendlyName, $errMsg)
        return $false
    }
}

function Resolve-ClaudeCommand {
    Update-SessionPath
    $cmd = Get-Command 'claude' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        (Join-Path $env:USERPROFILE '.local\bin\claude.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\claude\claude.exe'),
        (Join-Path $env:APPDATA 'npm\claude.cmd')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

function Test-McpExists {
    param([string]$ClaudeCmd, [string]$Name)
    try {
        $listOut = & $ClaudeCmd mcp list 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
        $joined = (@($listOut) -join "`n")
        $pattern = '(?im)^\s*' + [regex]::Escape($Name) + '\b'
        return ($joined -match $pattern)
    } catch {
        return $false
    }
}

function Add-RemoteMcp {
    param(
        [string]$ClaudeCmd,
        [string]$Name,
        [string]$Url,
        [string[]]$ExtraArgs = @()
    )
    if (Test-McpExists -ClaudeCmd $ClaudeCmd -Name $Name) {
        Write-Host ('  {0} already registered - skipping.' -f $Name)
        return
    }
    $cmdArgs = @('mcp', 'add', $Name, '--transport', 'http', $Url, '--scope', 'user')
    if ($ExtraArgs.Count -gt 0) { $cmdArgs += $ExtraArgs }
    & $ClaudeCmd @cmdArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Host ('  {0} registered.' -f $Name)
    } else {
        Write-Host ('  {0} registration returned a non-zero exit code.' -f $Name)
    }
}

function Add-LocalMcp {
    param(
        [string]$ClaudeCmd,
        [string]$Name,
        [string]$EnvPair,
        [string[]]$CommandParts
    )
    if (Test-McpExists -ClaudeCmd $ClaudeCmd -Name $Name) {
        Write-Host ('  {0} already registered - skipping.' -f $Name)
        return
    }
    $cmdArgs = @('mcp', 'add', $Name, '--scope', 'user')
    if ($EnvPair) { $cmdArgs += @('--env', $EnvPair) }
    $cmdArgs += '--'
    $cmdArgs += $CommandParts
    & $ClaudeCmd @cmdArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Host ('  {0} registered.' -f $Name)
    } else {
        Write-Host ('  {0} registration returned a non-zero exit code.' -f $Name)
    }
}

function Install-Skill {
    param(
        [string]$Name,
        [string]$GitUrl,
        [string]$SkillsRoot,
        [string]$CacheRoot
    )
    $dest = Join-Path $CacheRoot $Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host ('  Cloning {0} ...' -f $Name)
    & git clone --depth 1 $GitUrl $dest 2>$null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $dest)) {
        Write-Host ('  Clone failed for {0} (repo may have moved) - skipping.' -f $Name)
        return
    }
    $skillFiles = @(Get-ChildItem -Path $dest -Recurse -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue)
    if ($skillFiles.Count -eq 0) {
        Write-Host ('  No SKILL.md in {0} - not a drop-in skill. Left in cache.' -f $Name)
        return
    }
    if (-not (Test-Path $SkillsRoot)) {
        New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
    }
    foreach ($sf in $skillFiles) {
        $srcDir = $sf.Directory.FullName
        if ($srcDir -eq $dest) { $targetName = $Name } else { $targetName = (Split-Path $srcDir -Leaf) }
        $target = Join-Path $SkillsRoot $targetName
        if (Test-Path $target) { Remove-Item $target -Recurse -Force -ErrorAction SilentlyContinue }
        Copy-Item -Path $srcDir -Destination $target -Recurse -Force
        Write-Host ('  Installed skill: {0}' -f $targetName)
    }
}

# ------------------------------------------------------------------------------
# Begin
# ------------------------------------------------------------------------------
Write-Section 'Claude Code Full Stack Installer'
Write-Host 'Installing the toolset from the UI/UX Resources doc.'
Write-Host 'Administrator rights are not required.'

$skillsRoot = Join-Path $env:USERPROFILE '.claude\skills'
$cacheRoot = Join-Path $env:TEMP 'cc-fullstack-cache'
if (-not (Test-Path $cacheRoot)) { New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null }

# --- Step 1: Prerequisites ----------------------------------------------------
Write-Section 'Step 1 of 5 - Prerequisites (Git, Node.js)'
if (Test-CommandExists 'git') {
    Write-Host 'Git: already installed.'
} else {
    [void](Invoke-WingetInstall -PackageId 'Git.Git' -FriendlyName 'Git for Windows')
}
$gitOk = Test-CommandExists 'git'
if (-not $gitOk) {
    Write-Host 'Git is not available. Skills cannot be cloned without it.'
    Write-Host 'Install from https://git-scm.com/download/win and re-run.'
}

$nodeMajor = Get-NodeMajorVersion
if ($nodeMajor -ge 18) {
    Write-Host ('Node.js: version {0} detected.' -f $nodeMajor)
} else {
    Write-Host 'Node.js 18+ not found. It is needed for caveman and the npx MCP servers.'
    [void](Invoke-WingetInstall -PackageId 'OpenJS.NodeJS.LTS' -FriendlyName 'Node.js LTS')
    $nodeMajor = Get-NodeMajorVersion
}

# --- Step 2: Claude Code ------------------------------------------------------
Write-Section 'Step 2 of 5 - Claude Code'
$claudeCmd = Resolve-ClaudeCommand
if ($claudeCmd) {
    Write-Host ('Claude Code already present at: {0}' -f $claudeCmd)
} else {
    Write-Host 'Installing Claude Code using the official native installer ...'
    try {
        $installScript = Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' -ErrorAction Stop
        Invoke-Expression $installScript
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ('Native installer failed: {0}' -f $errMsg)
    }
    $claudeCmd = Resolve-ClaudeCommand
    if (-not $claudeCmd -and $nodeMajor -ge 18) {
        Write-Host 'Falling back to npm install ...'
        try { & npm install -g '@anthropic-ai/claude-code' } catch { Write-Host $_.Exception.Message }
        $claudeCmd = Resolve-ClaudeCommand
    }
    if ($claudeCmd) {
        Write-Host ('Claude Code installed at: {0}' -f $claudeCmd)
    } else {
        Write-Host 'Claude Code could not be installed. Run this by hand and re-run the script:'
        Write-Host '  irm https://claude.ai/install.ps1 | iex'
    }
}

# Optional non-interactive auth via API key.
$anthropicKey = Get-ConfigValue $Config.AnthropicApiKey
if ($anthropicKey) {
    Write-Host 'Anthropic API key supplied - configuring non-interactive auth (API billing).'
    [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $anthropicKey, 'User')
    $env:ANTHROPIC_API_KEY = $anthropicKey
} else {
    Write-Host 'No API key supplied - you will sign in once via browser when you first run claude.'
}

# --- Step 3: Skills -----------------------------------------------------------
Write-Section 'Step 3 of 5 - Skills'
if ($gitOk) {
    $skillRepos = @(
        @{ Name = 'gsap';                 Url = 'https://github.com/greensock/gsap-skills.git' },
        @{ Name = 'frontend-design-audit'; Url = 'https://github.com/mistyhx/frontend-design-audit.git' },
        @{ Name = 'seo-audit-skill';      Url = 'https://github.com/seo-skills/seo-audit-skill.git' },
        @{ Name = 'ai-website-cloner';    Url = 'https://github.com/JCodesMore/ai-website-cloner-template.git' },
        @{ Name = 'frontend-designer';    Url = 'https://github.com/emilkowalski/skill.git' },
        @{ Name = 'impeccable';           Url = 'https://github.com/pbakaus/impeccable.git' },
        @{ Name = 'taste-skill';          Url = 'https://github.com/Leonxlnx/taste-skill.git' },
        @{ Name = 'drawio-skill';         Url = 'https://github.com/Agents365-ai/drawio-skill.git' },
        @{ Name = 'ponytail';             Url = 'https://github.com/DietrichGebert/ponytail.git' },
        @{ Name = 'improve';              Url = 'https://github.com/shadcn/improve.git' },
        @{ Name = 'supermemory-skill';    Url = 'https://github.com/supermemoryai/claude-supermemory.git' }
    )
    if ($Config.IncludeMegaSkillLibrary) {
        $skillRepos += @{ Name = 'claude-skills-library'; Url = 'https://github.com/alirezarezvani/claude-skills.git' }
    }
    foreach ($repo in $skillRepos) {
        Install-Skill -Name $repo.Name -GitUrl $repo.Url -SkillsRoot $skillsRoot -CacheRoot $cacheRoot
    }
    Write-Host ''
    Write-Host 'Not installed as skills (handle manually if you want them):'
    Write-Host '  - UI & UX Pro Max (uupm.cc): a website/product, not a git skill.'
    Write-Host '  - Handy (github.com/cjpais/Handy): a desktop speech-to-text app.'
    Write-Host '  - SkillSpector (github.com/NVIDIA/SkillSpector): a scanner you run, not a skill.'
} else {
    Write-Host 'Skipping skills because Git is not available.'
}

# --- Step 4: caveman plugin ---------------------------------------------------
Write-Section 'Step 4 of 5 - caveman plugin'
if ($nodeMajor -ge 18) {
    Write-Host 'Installing caveman ...'
    try {
        & npx -y claudepluginhub juliusbrussee/caveman --plugin caveman
        if ($LASTEXITCODE -ne 0) { Write-Host 'caveman returned a non-zero exit code - skipped.' }
    } catch {
        Write-Host ('caveman skipped: {0}' -f $_.Exception.Message)
    }
} else {
    Write-Host 'Node.js not available - skipping caveman.'
}

# --- Step 5: MCP servers ------------------------------------------------------
Write-Section 'Step 5 of 5 - MCP servers'
$needsLogin = @()
if (-not $claudeCmd) {
    Write-Host 'Claude Code is not on PATH yet - skipping MCP registration.'
    Write-Host 'Re-run this script after opening a new terminal to add the MCP servers.'
} else {
    # supermemory (OAuth on first use)
    Add-RemoteMcp -ClaudeCmd $claudeCmd -Name 'supermemory' -Url 'https://mcp.supermemory.ai/mcp'
    $needsLogin += 'supermemory'

    # Supabase
    $sbRef = Get-ConfigValue $Config.SupabaseProjectRef
    $sbPat = Get-ConfigValue $Config.SupabasePat
    if ($sbRef) {
        $sbUrl = ('https://mcp.supabase.com/mcp?project_ref={0}' -f $sbRef)
        if ($sbPat) {
            $authHeader = ('Authorization: Bearer {0}' -f $sbPat)
            Add-RemoteMcp -ClaudeCmd $claudeCmd -Name 'supabase' -Url $sbUrl -ExtraArgs @('-H', $authHeader)
        } else {
            Add-RemoteMcp -ClaudeCmd $claudeCmd -Name 'supabase' -Url $sbUrl
            $needsLogin += 'supabase'
        }
    } else {
        Write-Host '  Supabase: no project ref set - skipping.'
    }

    # 21st.dev Magic
    $magicKey = Get-ConfigValue $Config.MagicApiKey
    if ($magicKey -and $nodeMajor -ge 18) {
        $magicEnv = ('API_KEY={0}' -f $magicKey)
        Add-LocalMcp -ClaudeCmd $claudeCmd -Name 'magic' -EnvPair $magicEnv -CommandParts @('npx', '-y', '@21st-dev/magic@latest')
    } else {
        Write-Host '  Magic: no API key (or no Node) - skipping.'
    }

    # TestSprite
    $tsKey = Get-ConfigValue $Config.TestSpriteApiKey
    if ($tsKey -and $nodeMajor -ge 18) {
        $tsEnv = ('API_KEY={0}' -f $tsKey)
        Add-LocalMcp -ClaudeCmd $claudeCmd -Name 'testsprite' -EnvPair $tsEnv -CommandParts @('npx', '-y', '@testsprite/testsprite-mcp@latest')
    } else {
        Write-Host '  TestSprite: no API key (or no Node) - skipping.'
    }

    # Vercel (OAuth on first use)
    if ($Config.InstallVercelMcp) {
        Add-RemoteMcp -ClaudeCmd $claudeCmd -Name 'vercel' -Url 'https://mcp.vercel.com'
        $needsLogin += 'vercel'
    }

    Write-Host ''
    Write-Host '  Stitch (Google Labs): set up manually from'
    Write-Host '    https://stitch.withgoogle.com/docs/mcp/setup'
    Write-Host '    (Google sign-in based; no headless option.)'
}

# --- Summary ------------------------------------------------------------------
Write-Section 'Setup complete'
Write-Host 'Next steps:'
Write-Host ''
Write-Host '  1. CLOSE this window and open a NEW PowerShell window.'
if ($anthropicKey) {
    Write-Host '  2. Run:    claude    (no login needed - API key is set).'
} else {
    Write-Host '  2. Run:    claude    and complete the one-time browser sign-in.'
}
Write-Host ''
if ($needsLogin.Count -gt 0) {
    $loginList = (@($needsLogin) -join ', ')
    Write-Host 'One-time browser sign-in still required the first time you use:'
    Write-Host ('  {0}' -f $loginList)
    Write-Host 'Inside Claude Code, run  /mcp  to trigger each sign-in.'
    Write-Host ''
}
Write-Host 'Useful checks:'
Write-Host '  claude doctor     - install health'
Write-Host '  claude mcp list   - registered MCP servers and their status'
Write-Host '  /context          - pull your Supermemory profile into a chat'
Write-Host '  /caveman          - turn on token-saving mode'
Write-Host ''
