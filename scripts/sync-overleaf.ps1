#Requires -Version 5.1
<#
.SYNOPSIS
    Safe, optional Overleaf synchronization helper (PowerShell version).
.DESCRIPTION
    Adapted from kashifSlrRBAAIGC/scripts/sync-overleaf.ps1.

    Usage:
      scripts/sync-overleaf.ps1 run

    This script never stores, prints, or requests a username, password,
    GitHub PAT, or Overleaf Git token. Git's normal credential manager or
    interactive prompt handles authentication.
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet('run')]
    [string]$Command = 'run'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

function Assert-GitRepo {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Not inside a Git repository."
        exit 1
    }
}

function Assert-MainBranch {
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($currentBranch -ne 'main') {
        Write-Error "ERROR: Current branch is '$currentBranch', but 'main' is required."
        exit 1
    }
}

# Safety check: refuse to push unless 'origin' points at the expected
# personal GitHub account (andylegear). This guards against accidentally
# pushing this manuscript to the wrong remote/account.
function Assert-OriginIsAndylegear {
    $originUrl = (git remote get-url origin).Trim()
    if ($originUrl -notmatch '(?i)(^|[/:@])andylegear(/|$)') {
        Write-Error @"
ERROR: Refusing to push. Remote 'origin' does not appear to point at
  the andylegear GitHub account (origin = $originUrl).
  If this is intentional, update this check in scripts/sync-overleaf.ps1.
"@
        exit 1
    }
}

function Invoke-Run {
    Assert-GitRepo
    Assert-MainBranch

    git remote get-url origin *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Remote 'origin' is not configured."
        exit 1
    }

    Assert-OriginIsAndylegear

    if ((git status --porcelain)) {
        Write-Error "ERROR: Working tree is not clean. Commit or stash changes before syncing."
        exit 1
    }

    Write-Host "Pulling from GitHub (origin/main) with merge..."
    git pull --no-rebase origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: 'git pull --no-rebase origin main' failed or produced a conflict. Resolve manually, then re-run this script."
        exit 1
    }

    git remote get-url overleaf *> $null
    $overleafConfigured = ($LASTEXITCODE -eq 0)

    if (-not $overleafConfigured) {
        Write-Host "No 'overleaf' remote configured; syncing GitHub only."
        git push origin main
        exit 0
    }

    Write-Host "Pulling from Overleaf (overleaf/main)..."
    $overleafPullOutput = git pull overleaf main --allow-unrelated-histories --rebase=false 2>&1
    $overleafPullStatus = $LASTEXITCODE
    Write-Host $overleafPullOutput

    if ($overleafPullStatus -ne 0) {
        $unresolvedConflicts = git status --porcelain=v2 2>$null | Select-String '^u '
        if ($unresolvedConflicts) {
            Write-Error "ERROR: Overleaf pull produced unresolved merge conflicts. Resolve manually; no automatic resolution, force-push, or push was performed."
            exit 1
        }

        Write-Warning "Overleaf was not synchronized (pull failed, likely authentication/connectivity/missing token)."
        git push origin main
        Write-Host "GitHub push completed. Overleaf was NOT synchronized; the two remotes are not confirmed to be in sync."
        exit 0
    }

    $originPushOk = $true
    $overleafPushOk = $true

    git push origin main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Pushed main to origin."
    }
    else {
        $originPushOk = $false
        Write-Warning "FAILURE: Push to origin failed."
    }

    git push overleaf main:main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Pushed main to overleaf."
    }
    else {
        $overleafPushOk = $false
        Write-Warning "FAILURE: Push to overleaf failed."
    }

    if (-not ($originPushOk -and $overleafPushOk)) {
        exit 1
    }
}

switch ($Command) {
    'run' { Invoke-Run }
}
