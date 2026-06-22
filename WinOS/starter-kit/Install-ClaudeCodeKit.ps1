# ==============================================================================
# Claude Code Starter Kit Installer
# ------------------------------------------------------------------------------
# AUTHOR: Mayur Agrawal
# LAST REVIEW: 22 June 2026 14:30
# ------------------------------------------------------------------------------
# Sets up Claude Code on a fresh Windows machine:
#   1. Git for Windows  (recommended - installed via winget if missing)
#   2. Claude Code       (Anthropic official native installer - no Node.js needed)
#   3. Supermemory MCP   (persistent memory - each user signs into their own account)
#   4. caveman plugin    (optional token saver - needs Node.js 18+)
#
# HOW TO RUN:
#   Double-click  Setup-ClaudeCode.cmd  (recommended), or
#   right-click this file and choose "Run with PowerShell".
#
# Administrator rights are NOT required. Do not run Claude Code as Administrator.
# Safe to re-run: anything already installed is skipped.
# ==============================================================================

# Use Continue (not Stop) globally so harmless stderr output from native tools
# like npm and winget does not abort the script. Risky cmdlet calls below use
# -ErrorAction Stop explicitly inside try/catch.
$ErrorActionPreference = 'Continue'

function Write-Section {
    param([string]$Text)
    Write-Host ''
    Write-Host '======================================================'
    Write-Host $Text
    Write-Host '======================================================'
}

function Update-SessionPath {
    # Re-read Machine and User PATH so tools installed during this run resolve.
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
        $major = [int]($clean.Split('.')[0])
        return $major
    } catch {
        return 0
    }
}

function Invoke-WingetInstall {
    param([string]$PackageId, [string]$FriendlyName)
    if (-not (Test-CommandExists 'winget')) {
        Write-Host ('winget not available - skipping automatic {0} install.' -f $FriendlyName)
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

# ------------------------------------------------------------------------------

Write-Section 'Claude Code Starter Kit Installer'
Write-Host 'This sets up Claude Code and a few extras on this machine.'
Write-Host 'Administrator rights are not required.'

# --- Step 1: Git for Windows (recommended) ------------------------------------
Write-Section 'Step 1 of 4 - Git for Windows (recommended)'
if (Test-CommandExists 'git') {
    Write-Host 'Git is already installed. Good.'
} else {
    Write-Host 'Git lets Claude Code use its Bash tool. Recommended but not required.'
    [void](Invoke-WingetInstall -PackageId 'Git.Git' -FriendlyName 'Git for Windows')
    if (-not (Test-CommandExists 'git')) {
        Write-Host 'Git was not installed automatically. You can add it later from:'
        Write-Host '  https://git-scm.com/download/win'
        Write-Host 'Claude Code still works without it (it falls back to PowerShell).'
    }
}

# --- Step 2: Claude Code ------------------------------------------------------
Write-Section 'Step 2 of 4 - Claude Code'
$claudeCmd = Resolve-ClaudeCommand
if ($claudeCmd) {
    Write-Host ('Claude Code is already present at: {0}' -f $claudeCmd)
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

    if (-not $claudeCmd) {
        # Fallback: npm install if Node.js 18+ is available.
        $nodeMajor = Get-NodeMajorVersion
        if ($nodeMajor -ge 18) {
            Write-Host 'Falling back to npm install ...'
            try {
                & npm install -g '@anthropic-ai/claude-code'
            } catch {
                $errMsg = $_.Exception.Message
                Write-Host ('npm install failed: {0}' -f $errMsg)
            }
            $claudeCmd = Resolve-ClaudeCommand
        }
    }

    if ($claudeCmd) {
        Write-Host ('Claude Code installed at: {0}' -f $claudeCmd)
    } else {
        Write-Host 'Claude Code could not be installed automatically.'
        Write-Host 'Install it by hand, then re-run this script:'
        Write-Host '  irm https://claude.ai/install.ps1 | iex'
    }
}

# --- Step 3: Supermemory MCP --------------------------------------------------
Write-Section 'Step 3 of 4 - Supermemory MCP (persistent memory)'
$supermemoryUrl = 'https://mcp.supermemory.ai/mcp'
if ($claudeCmd) {
    Write-Host 'Registering the Supermemory MCP server with Claude Code ...'
    Write-Host 'You will sign in to your own Supermemory account the first time Claude Code connects.'
    try {
        & $claudeCmd mcp add supermemory --transport http $supermemoryUrl --scope user
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'mcp add returned a non-zero exit code.'
            Write-Host 'It may already be registered. The manual command is shown below.'
        } else {
            Write-Host 'Supermemory MCP registered.'
        }
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ('Could not register Supermemory automatically: {0}' -f $errMsg)
    }
} else {
    Write-Host 'Skipping Supermemory because Claude Code is not on the PATH yet.'
}
Write-Host ''
Write-Host 'Manual command if needed (run in a new terminal):'
Write-Host ('  claude mcp add supermemory --transport http {0} --scope user' -f $supermemoryUrl)

# --- Step 4: caveman plugin (optional) ----------------------------------------
Write-Section 'Step 4 of 4 - caveman plugin (optional, saves tokens)'
$nodeMajor = Get-NodeMajorVersion
if ($nodeMajor -lt 18) {
    Write-Host 'caveman needs Node.js 18 or newer.'
    [void](Invoke-WingetInstall -PackageId 'OpenJS.NodeJS.LTS' -FriendlyName 'Node.js LTS')
    $nodeMajor = Get-NodeMajorVersion
}
if ($nodeMajor -ge 18) {
    Write-Host 'Installing the caveman plugin ...'
    try {
        & npx -y claudepluginhub juliusbrussee/caveman --plugin caveman
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'caveman installer returned a non-zero exit code - skipping.'
        } else {
            Write-Host 'caveman installed. Type /caveman inside Claude Code to switch it on.'
        }
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host ('caveman installation skipped: {0}' -f $errMsg)
    }
} else {
    Write-Host 'Node.js not available - skipping caveman (it is optional).'
    Write-Host 'To add it later, install Node.js 18+ then run:'
    Write-Host '  npx -y claudepluginhub juliusbrussee/caveman --plugin caveman'
}

# --- Done ---------------------------------------------------------------------
Write-Section 'Setup complete'
Write-Host 'Next steps:'
Write-Host ''
Write-Host '  1. CLOSE this window and open a NEW PowerShell window'
Write-Host '     so the updated PATH is loaded.'
Write-Host '  2. Run:    claude'
Write-Host '  3. Complete the browser sign-in when prompted.'
Write-Host ''
Write-Host 'Inside Claude Code:'
Write-Host '  - Type /context to pull your Supermemory profile into a chat.'
Write-Host '  - Type /caveman to switch on token-saving caveman mode.'
Write-Host '  - Run  claude doctor  any time to check the install health.'
Write-Host ''
