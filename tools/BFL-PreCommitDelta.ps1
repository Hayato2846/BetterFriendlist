param(
    [string]$BaselinePath,
    [switch]$UpdateBaseline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Normalize-BFLPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return ($Path -replace '\\', '/').TrimStart('/')
}

function Get-BFLPreCommitWarnings {
    param([string[]]$Lines)

    $warnings = @()
    foreach ($line in $Lines) {
        if ($line -match '^\s+\[([A-Z0-9-]+)\]\s+(.+?):(\d+)\s*$') {
            $type = $Matches[1]
            $path = Normalize-BFLPath $Matches[2]
            $lineNumber = [int]$Matches[3]
            $warnings += [PSCustomObject]@{
                Type = $type
                Path = $path
                Line = $lineNumber
                Signature = "$type|$path|$lineNumber"
            }
        }
    }

    return @($warnings | Sort-Object Signature -Unique)
}

function Read-BFLBaselineWarnings {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Baseline is missing. Run with -UpdateBaseline first: $Path"
    }

    $baseline = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    return @($baseline.warnings)
}

$repoRootOutput = @(& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or $repoRootOutput.Count -eq 0) {
    throw 'This script must run inside the BetterFriendlist git repository.'
}

$repoRoot = ($repoRootOutput | Select-Object -First 1).Trim()
Set-Location -LiteralPath $repoRoot

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
    $BaselinePath = Join-Path $repoRoot 'tools\BFL-PreCommitWarningsBaseline.json'
} else {
    $BaselinePath = [System.IO.Path]::GetFullPath($BaselinePath)
}

Write-Host '[BFL] Pre-commit warning delta'
$output = @(& python (Join-Path $repoRoot 'Utils\pre-commit-check.py') 2>&1)
$exitCode = $LASTEXITCODE
$warnings = @(Get-BFLPreCommitWarnings -Lines $output)

$errorLines = @($output | Where-Object { $_ -match '\[ERROR\]' })
if ($errorLines.Count -gt 0) {
    Write-Host '[BFL] Pre-commit errors'
    $errorLines | ForEach-Object { Write-Host $_ }
}

if ($UpdateBaseline) {
    $baseline = [ordered]@{
        generatedAt = (Get-Date).ToString('o')
        source = 'Utils/pre-commit-check.py'
        warningCount = $warnings.Count
        warnings = @($warnings | Select-Object Type, Path, Line, Signature)
    }
    $baseline | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BaselinePath -Encoding UTF8
    Write-Host "Updated baseline: $BaselinePath"
    Write-Host "Baseline warnings: $($warnings.Count)"
    if ($exitCode -ne 0) {
        Write-Warning "pre-commit-check.py exited with code $exitCode while updating the baseline."
    }
    exit $exitCode
}

$baselineWarnings = @(Read-BFLBaselineWarnings -Path $BaselinePath)
$baselineSignatures = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($warning in $baselineWarnings) {
    [void]$baselineSignatures.Add([string]$warning.Signature)
}

$currentSignatures = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($warning in $warnings) {
    [void]$currentSignatures.Add([string]$warning.Signature)
}

$newWarnings = @($warnings | Where-Object { -not $baselineSignatures.Contains([string]$_.Signature) })
$resolvedWarnings = @($baselineWarnings | Where-Object { -not $currentSignatures.Contains([string]$_.Signature) })

Write-Host "Baseline warnings: $($baselineWarnings.Count)"
Write-Host "Current warnings:  $($warnings.Count)"
Write-Host "New warnings:      $($newWarnings.Count)"
Write-Host "Resolved warnings: $($resolvedWarnings.Count)"

if ($newWarnings.Count -gt 0) {
    Write-Host ''
    Write-Host '[BFL] New warning signatures'
    foreach ($warning in $newWarnings) {
        Write-Host ("- {0} {1}:{2}" -f $warning.Type, $warning.Path, $warning.Line)
    }
}

if ($resolvedWarnings.Count -gt 0) {
    Write-Host ''
    Write-Host '[BFL] Resolved baseline signatures'
    foreach ($warning in ($resolvedWarnings | Select-Object -First 20)) {
        Write-Host ("- {0} {1}:{2}" -f $warning.Type, $warning.Path, $warning.Line)
    }
    if ($resolvedWarnings.Count -gt 20) {
        Write-Host "- ...and $($resolvedWarnings.Count - 20) more"
    }
}

if ($exitCode -ne 0) {
    exit $exitCode
}
if ($newWarnings.Count -gt 0) {
    exit 1
}

exit 0
