param(
    [ValidateSet('none', 'retail', 'ptr', 'xptr', 'beta', 'classic', 'classic_ptr', 'classic_era', 'anniversary', 'all')]
    [string]$DeployClient = 'none',

    [string]$BaseRef = $env:BFL_REVIEW_BASE,
    [switch]$SkipPackageCheck,
    [switch]$SkipPreCommitDelta,
    [switch]$SkipBranchTriage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRootOutput = @(& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or $repoRootOutput.Count -eq 0) {
    throw 'This script must run inside the BetterFriendlist git repository.'
}

$repoRoot = ($repoRootOutput | Select-Object -First 1).Trim()
Set-Location -LiteralPath $repoRoot

function Invoke-BFLStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Script
    )

    Write-Host ''
    Write-Host "== $Name =="
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}

Write-Host '# BetterFriendlist Ready For QA'
Write-Host "Repository: $repoRoot"
if (-not [string]::IsNullOrWhiteSpace($BaseRef)) {
    Write-Host "Base ref: $BaseRef"
}
Write-Host "Deploy client: $DeployClient"

Invoke-BFLStep 'Git status' {
    & git status --short --branch
}

if (-not $SkipBranchTriage) {
    Invoke-BFLStep 'Branch triage' {
        & (Join-Path $repoRoot 'tools\BFL-BranchTriage.ps1')
    }
}

if (-not $SkipPackageCheck) {
    Invoke-BFLStep 'Package check' {
        & (Join-Path $repoRoot 'tools\BFL-PackageCheck.ps1')
    }
}

if (-not $SkipPreCommitDelta) {
    Invoke-BFLStep 'Pre-commit warning delta' {
        & (Join-Path $repoRoot 'tools\BFL-PreCommitDelta.ps1')
    }
}

Invoke-BFLStep 'Review check' {
    $reviewScript = Join-Path $repoRoot 'tools\BFL-ReviewCheck.ps1'
    if (-not [string]::IsNullOrWhiteSpace($BaseRef) -and -not $BaseRef.StartsWith('-', [System.StringComparison]::Ordinal)) {
        & $reviewScript -BaseRef $BaseRef -SkipPackageCheck
    } else {
        & $reviewScript -SkipPackageCheck
    }
}

if ($DeployClient -ne 'none') {
    Invoke-BFLStep "Deploy $DeployClient" {
        & (Join-Path $repoRoot 'tools\BFL-Deploy.ps1') -Mode CleanCopy -Client $DeployClient -Source $repoRoot
    }
}

Write-Host ''
Write-Host '[OK] Ready-for-QA flow completed.'
