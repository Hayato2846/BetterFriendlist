$ErrorActionPreference = 'Stop'

Write-Host '[BFL] Git status'
& git status --short --branch

Write-Host ''
Write-Host '[BFL] Whitespace check'
& git diff --check

Write-Host ''
Write-Host '[BFL] Project pre-commit check'
python Utils/pre-commit-check.py 2>&1 |
    Select-String -Pattern '\[ERROR\]|\[OK\]|\[WARN\] WARN|All checks'

Write-Host ''
Write-Host '[BFL] Release package metadata'

$pkgmetaPath = Join-Path (Get-Location) '.pkgmeta'
if (-not (Test-Path -LiteralPath $pkgmetaPath -PathType Leaf)) {
    throw '.pkgmeta is missing.'
}

$pkgmetaLines = Get-Content -LiteralPath $pkgmetaPath
$ignorePatterns = @()
$inIgnoreBlock = $false

foreach ($line in $pkgmetaLines) {
    if ($line -match '^ignore:\s*$') {
        $inIgnoreBlock = $true
        continue
    }

    if ($inIgnoreBlock -and $line -match '^\S') {
        break
    }

    if ($inIgnoreBlock -and $line -match '^\s*-\s+(.+?)\s*$') {
        $pattern = $Matches[1].Trim()
        if (($pattern.StartsWith('"') -and $pattern.EndsWith('"')) -or
            ($pattern.StartsWith("'") -and $pattern.EndsWith("'"))) {
            $pattern = $pattern.Substring(1, $pattern.Length - 2)
        }
        $ignorePatterns += ($pattern -replace '\\', '/')
    }
}

function Test-PackageIgnoreMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    $normalizedPath = ($Path -replace '\\', '/').TrimStart('/')
    $normalizedPattern = ($Pattern -replace '\\', '/').Trim().TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($normalizedPattern)) {
        return $false
    }

    $leafName = [System.IO.Path]::GetFileName($normalizedPath)

    if ($normalizedPath -like $normalizedPattern -or $leafName -like $normalizedPattern) {
        return $true
    }

    if ($normalizedPath.Equals($normalizedPattern, [System.StringComparison]::OrdinalIgnoreCase) -or
        $normalizedPath.StartsWith($normalizedPattern + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return ($normalizedPath -like "*/$normalizedPattern" -or
        $normalizedPath -like "*/$normalizedPattern/*")
}

$requiredIgnores = @(
    '.git', '.github', '.gitignore', '.pkgmeta', '.vscode', '.codex-worktrees',
    '.ai-context', 'docs', 'memory-bank', 'old_version', 'plans', 'predecessor',
    'reference', 'tools', '*.md', '*.ps1', '*.py', '*.txt', '*.zip', '*.log',
    '*.bak', '*.lua.bak'
)

$missingRequiredIgnores = @(
    foreach ($required in $requiredIgnores) {
        if (-not ($ignorePatterns | Where-Object {
                    $_.Equals($required, [System.StringComparison]::OrdinalIgnoreCase)
                })) {
            $required
        }
    }
)

if ($missingRequiredIgnores.Count -gt 0) {
    throw "Missing .pkgmeta ignore entries: $($missingRequiredIgnores -join ', ')"
}

$trackedFiles = & git ls-files
$internalFiles = @(
    foreach ($file in $trackedFiles) {
        $normalizedFile = ($file -replace '\\', '/')
        if ($normalizedFile -match '^(\.github/|\.vscode/|\.codex-worktrees/|\.ai-context/|docs/|memory-bank/|old_version/|plans/|predecessor/|reference/|tools/)' -or
            $normalizedFile -match '\.(md|ps1|py|txt|zip|log|bak)$' -or
            $normalizedFile -match '\.lua\.bak$' -or
            $normalizedFile -in @('.gitignore', '.pkgmeta')) {
            $normalizedFile
        }
    }
)

$leakingFiles = @(
    foreach ($file in $internalFiles) {
        $matched = $false
        foreach ($pattern in $ignorePatterns) {
            if (Test-PackageIgnoreMatch -Path $file -Pattern $pattern) {
                $matched = $true
                break
            }
        }

        if (-not $matched) {
            $file
        }
    }
)

if ($leakingFiles.Count -gt 0) {
    throw "Tracked internal files are not ignored by .pkgmeta: $($leakingFiles -join ', ')"
}

Write-Host '[OK] Package metadata excludes tracked internal files.'
