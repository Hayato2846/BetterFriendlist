param(
    [switch]$Restore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    Write-Error "Run this script from the BetterFriendlist repository or a worktree."
    exit 1
}

$changedFiles = @(& git -C $repoRoot diff --name-only --)
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($changedFiles.Count -eq 0) {
    Write-Host "No tracked file changes found."
    exit 0
}

$perfyMarkers = @(
    '--[[Perfy has instrumented this file]]',
    'Perfy_Trace(',
    'Perfy_Trace_Passthrough(',
    '## X-Perfy-Instrumented: true'
)

$safeFiles = [System.Collections.Generic.List[string]]::new()
$blockedFiles = [System.Collections.Generic.List[string]]::new()

foreach ($file in $changedFiles) {
    $fullPath = Join-Path $repoRoot $file
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $blockedFiles.Add($file)
        continue
    }

    $text = Get-Content -LiteralPath $fullPath -Raw
    $hasMarker = $false
    foreach ($marker in $perfyMarkers) {
        if ($text.Contains($marker)) {
            $hasMarker = $true
            break
        }
    }

    if ($hasMarker) {
        $safeFiles.Add($file)
    } else {
        $blockedFiles.Add($file)
    }
}

Write-Host "Changed tracked files:"
foreach ($file in $changedFiles) {
    Write-Host "  $file"
}

if ($safeFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Perfy cleanup candidates:"
    foreach ($file in $safeFiles) {
        Write-Host "  $file"
    }
}

if ($blockedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Blocked files without Perfy markers:"
    foreach ($file in $blockedFiles) {
        Write-Host "  $file"
    }
}

if (-not $Restore) {
    Write-Host ""
    Write-Host "Preview only. Re-run with -Restore to restore only when every changed tracked file is marked as Perfy instrumentation."
    exit 0
}

if ($blockedFiles.Count -gt 0) {
    Write-Error "Refusing to restore because at least one changed tracked file does not contain a Perfy instrumentation marker."
    exit 1
}

Write-Host ""
Write-Host "Restoring Perfy-instrumented tracked files..."
$restoreFiles = @($safeFiles.ToArray())
& git -C $repoRoot restore -- $restoreFiles
exit $LASTEXITCODE
