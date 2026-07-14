[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [switch]$Push,
    [switch]$ValidateOnly,
    [string]$Remote = 'origin'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-BFLReleaseStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Script
    )

    Write-Host ''
    Write-Host "== $Name =="
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE. No release tag was created."
    }
}

function Assert-BFLCleanWorktree {
    param([Parameter(Mandatory = $true)][string]$Root)

    $status = @(& git -C $Root status --porcelain --untracked-files=all)
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect the git worktree.'
    }
    if ($status.Count -gt 0) {
        throw "Release tagging requires a clean worktree. Commit or remove these changes first:`n$($status -join "`n")"
    }
}

$repoRootOutput = @(& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or $repoRootOutput.Count -eq 0) {
    throw 'This script must run inside the BetterFriendlist git repository.'
}

$repoRoot = [System.IO.Path]::GetFullPath(($repoRootOutput | Select-Object -First 1).Trim())
Set-Location -LiteralPath $repoRoot

$cleanVersion = $Version.Trim()
if ($cleanVersion.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
    $cleanVersion = $cleanVersion.Substring(1)
}
if ($cleanVersion -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$') {
    throw "Version must be a semantic version such as 2.7.0 or 2.7.0-beta1: $Version"
}
$tagName = "v$cleanVersion"

Write-Host '# BetterFriendlist Local Release Tag Gate'
Write-Host "Repository: $repoRoot"
Write-Host "Version: $cleanVersion"
Write-Host "Tag: $tagName"
Write-Host "Push: $Push"
Write-Host "Validate only: $ValidateOnly"

Assert-BFLCleanWorktree -Root $repoRoot

& git -C $repoRoot show-ref --verify --quiet "refs/tags/$tagName"
if ($LASTEXITCODE -eq 0) {
    throw "Tag already exists locally: $tagName"
}
if ($LASTEXITCODE -ne 1) {
    throw "Could not inspect existing tags (git exit code $LASTEXITCODE)."
}

$tocPath = Join-Path $repoRoot 'BetterFriendlist.toc'
$tocText = Get-Content -LiteralPath $tocPath -Raw -Encoding UTF8
$tocVersionMatch = [regex]::Match($tocText, '(?m)^## Version:\s*(\S+)\s*$')
if (-not $tocVersionMatch.Success) {
    throw 'BetterFriendlist.toc does not contain a ## Version entry.'
}
$tocVersion = $tocVersionMatch.Groups[1].Value
if ($tocVersion -cne $cleanVersion) {
    throw "TOC version '$tocVersion' does not match requested release '$cleanVersion'."
}

$changelogPath = Join-Path $repoRoot 'CHANGELOG.md'
$changelogText = Get-Content -LiteralPath $changelogPath -Raw -Encoding UTF8
$escapedVersion = [regex]::Escape($cleanVersion)
if ($changelogText -notmatch "(?m)^## \[$escapedVersion\]\s+-\s+\d{4}-\d{2}-\d{2}\s*$") {
    throw "CHANGELOG.md has no dated release heading for $cleanVersion."
}
if ($changelogText -match '(?m)^## \[DRAFT\]') {
    throw 'CHANGELOG.md still contains a [DRAFT] section. Promote it before tagging.'
}

$previousTagOutput = @(& git -C $repoRoot describe --tags --abbrev=0 --match 'v*' HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $previousTagOutput.Count -eq 0) {
    throw 'No previous v* release tag is reachable from HEAD; cannot verify translation freshness.'
}
$previousTag = ($previousTagOutput | Select-Object -First 1).Trim()
Write-Host "Previous release tag: $previousTag"

Invoke-BFLReleaseStep 'Full localization contract' {
    & (Join-Path $repoRoot 'tools/BFL-LocalizationCheck.ps1') -Mode Full
}

Invoke-BFLReleaseStep "Localization freshness since $previousTag" {
    & (Join-Path $repoRoot 'tools/BFL-LocalizationCheck.ps1') -Mode Changed -BaseRef $previousTag
}

Invoke-BFLReleaseStep 'Localization runtime smoke' {
    $luaCommand = Get-Command lua -ErrorAction SilentlyContinue
    if ($null -eq $luaCommand) {
        throw 'The local release tag gate requires a Lua interpreter on PATH for localization runtime validation.'
    }
    & $luaCommand.Source (Join-Path $repoRoot 'tools/BFL-LocalizationRuntimeSmoke.lua') $repoRoot
}

Invoke-BFLReleaseStep 'Ready for QA' {
    & (Join-Path $repoRoot 'tools/BFL-ReadyForQA.ps1') -BaseRef $previousTag -SkipBranchTriage
}

Assert-BFLCleanWorktree -Root $repoRoot

if ($ValidateOnly) {
    Write-Host ''
    Write-Host "[OK] $tagName is ready to be created. ValidateOnly left the repository unchanged." -ForegroundColor Green
    exit 0
}

if ($PSCmdlet.ShouldProcess($tagName, 'Create annotated release tag')) {
    & git -C $repoRoot tag -a $tagName -m "BetterFriendlist $cleanVersion"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create release tag $tagName."
    }
    Write-Host "[OK] Created local release tag $tagName." -ForegroundColor Green
}

if ($Push) {
    if ($PSCmdlet.ShouldProcess("$Remote/$tagName", 'Push release tag and start release automation')) {
        & git -C $repoRoot push $Remote "refs/tags/$tagName"
        if ($LASTEXITCODE -ne 0) {
            throw "Tag $tagName exists locally, but pushing it to $Remote failed."
        }
        Write-Host "[OK] Pushed $tagName to $Remote." -ForegroundColor Green
    }
} else {
    Write-Host "Tag was not pushed. Re-run with -Push only when publication is intended."
}
