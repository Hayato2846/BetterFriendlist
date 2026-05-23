param(
    [ValidateSet('Backup', 'Restore', 'List')]
    [string]$Action = 'List',

    [ValidateSet('retail', 'ptr', 'xptr', 'beta', 'classic', 'classic_ptr', 'classic_era', 'anniversary')]
    [string]$Client = 'retail',

    [string]$ProfileName,
    [string]$Account,
    [string]$Root,
    [string]$WowRoot,
    [switch]$Force
)

. "$PSScriptRoot\BFL-Paths.ps1"

function Get-BFLSavedVariablesPath {
    param(
        [Parameter(Mandatory = $true)]$ClientInfo,
        [string]$AccountName
    )

    if (-not (Test-Path -LiteralPath $ClientInfo.SavedVariablesRoot)) {
        throw "No WTF account folder for $($ClientInfo.Key): $($ClientInfo.SavedVariablesRoot)"
    }

    if (-not [string]::IsNullOrWhiteSpace($AccountName)) {
        return Join-Path (Join-Path $ClientInfo.SavedVariablesRoot $AccountName) 'SavedVariables\BetterFriendlist.lua'
    }

    $matches = Get-ChildItem -LiteralPath $ClientInfo.SavedVariablesRoot -Directory |
        ForEach-Object { Join-Path $_.FullName 'SavedVariables\BetterFriendlist.lua' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }

    if ($matches.Count -eq 0) {
        throw "No BetterFriendlist SavedVariables found for $($ClientInfo.Key)."
    }
    if ($matches.Count -gt 1) {
        throw "Multiple accounts found. Re-run with -Account. Matches: $($matches -join '; ')"
    }
    return $matches[0]
}

$rootPath = Resolve-BFLRoot $Root
$info = Get-BFLClientInfo -Client $Client -Root $rootPath -WowRoot $WowRoot
$backupRoot = Join-Path (Join-Path $rootPath 'savedvariables\BetterFriendlist') $Client
Ensure-BFLDirectory $backupRoot

switch ($Action) {
    'List' {
        Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue |
            Select-Object Name, FullName, LastWriteTime
    }
    'Backup' {
        if ([string]::IsNullOrWhiteSpace($ProfileName)) {
            $ProfileName = Get-Date -Format 'yyyyMMdd-HHmmss'
        }
        $source = Get-BFLSavedVariablesPath -ClientInfo $info -AccountName $Account
        $targetDir = Join-Path $backupRoot $ProfileName
        if ((Test-Path -LiteralPath $targetDir) -and -not $Force) {
            throw "Backup profile exists. Use -Force to replace: $targetDir"
        }
        Ensure-BFLDirectory $targetDir
        Copy-Item -LiteralPath $source -Destination (Join-Path $targetDir 'BetterFriendlist.lua') -Force
        $sourceBak = "$source.bak"
        if (Test-Path -LiteralPath $sourceBak -PathType Leaf) {
            Copy-Item -LiteralPath $sourceBak -Destination (Join-Path $targetDir 'BetterFriendlist.lua.bak') -Force
        }
        Write-Host "Backed up $source -> $targetDir"
    }
    'Restore' {
        if ([string]::IsNullOrWhiteSpace($ProfileName)) {
            throw '-ProfileName is required for Restore.'
        }
        $sourceDir = Join-Path $backupRoot $ProfileName
        $source = Join-Path $sourceDir 'BetterFriendlist.lua'
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Backup profile not found: $sourceDir"
        }
        $target = Get-BFLSavedVariablesPath -ClientInfo $info -AccountName $Account
        Copy-Item -LiteralPath $source -Destination $target -Force
        $sourceBak = Join-Path $sourceDir 'BetterFriendlist.lua.bak'
        if (Test-Path -LiteralPath $sourceBak -PathType Leaf) {
            Copy-Item -LiteralPath $sourceBak -Destination "$target.bak" -Force
        }
        Write-Host "Restored $sourceDir -> $target"
    }
}
