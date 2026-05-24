param(
    [ValidateSet('CleanCopy', 'Link', 'Zip')]
    [string]$Mode = 'CleanCopy',

    [ValidateSet('retail', 'ptr', 'xptr', 'beta', 'classic', 'classic_ptr', 'classic_era', 'anniversary', 'all')]
    [string[]]$Client = @('retail'),

    [string]$Source = (Get-Location).Path,
    [string]$Zip,
    [string]$Root,
    [string]$WowRoot,
    [ValidateSet('Junction', 'SymbolicLink')]
    [string]$LinkType = 'Junction',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\BFL-Paths.ps1"

function Invoke-BFLAddonMirror {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    Ensure-BFLDirectory (Split-Path -Parent $DestinationRoot)

    if ((Test-Path -LiteralPath $DestinationRoot) -and
        ((Get-Item -LiteralPath $DestinationRoot -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Deployment destination is a link. Remove it before mirroring: $DestinationRoot"
    }

    $excludeDirs = @(
        '.git', '.github', '.vscode', '.codex-worktrees', '.ai-context',
        'docs', 'memory-bank', 'old_version', 'plans', 'predecessor',
        'reference', 'tools', 'WoW UI Source'
    )
    $excludeFiles = @(
        '.git', '.gitignore', '.pkgmeta', '*.bak', '*.html', '*.log', '*.lua.bak',
        '*.md', '*.png', '*.ps1', '*.py', '*.txt', '*.zip'
    )

    Remove-BFLExcludedArtifacts -DestinationRoot $DestinationRoot -ExcludeDirs $excludeDirs -ExcludeFiles $excludeFiles

    $args = @($SourceRoot, $DestinationRoot, '/MIR', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/XD') +
        $excludeDirs + @('/XF') + $excludeFiles

    & robocopy @args | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }

    Assert-BFLAddonRoot $DestinationRoot | Out-Null
}

function Remove-BFLExcludedArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [Parameter(Mandatory = $true)][string[]]$ExcludeDirs,
        [Parameter(Mandatory = $true)][string[]]$ExcludeFiles
    )

    $resolvedDestination = [System.IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $resolvedDestination)) {
        return
    }

    foreach ($dir in $ExcludeDirs) {
        $target = Join-Path $resolvedDestination $dir
        if (-not (Test-Path -LiteralPath $target)) {
            continue
        }

        $resolvedTarget = [System.IO.Path]::GetFullPath($target)
        if (-not (Test-BFLPathUnder -Path $resolvedTarget -Root $resolvedDestination)) {
            throw "Refusing to remove excluded directory outside destination: $resolvedTarget"
        }

        Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
    }

    $existingFiles = Get-ChildItem -LiteralPath $resolvedDestination -Recurse -Force -File -ErrorAction SilentlyContinue
    foreach ($file in $existingFiles) {
        $shouldRemove = $false
        foreach ($pattern in $ExcludeFiles) {
            if ($file.Name -like $pattern) {
                $shouldRemove = $true
                break
            }
        }

        if (-not $shouldRemove) {
            continue
        }

        $resolvedFile = [System.IO.Path]::GetFullPath($file.FullName)
        if (-not (Test-BFLPathUnder -Path $resolvedFile -Root $resolvedDestination)) {
            throw "Refusing to remove excluded file outside destination: $resolvedFile"
        }

        Remove-Item -LiteralPath $resolvedFile -Force
    }
}

function Copy-BFLAddon {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To,
        [Parameter(Mandatory = $true)][string]$BFLRoot
    )

    $sourceRoot = Assert-BFLAddonRoot $From
    $destinationRoot = [System.IO.Path]::GetFullPath($To)
    $deployRoot = Join-Path (Resolve-BFLRoot $BFLRoot) 'deploy'

    if (-not (Test-BFLPathUnder -Path $destinationRoot -Root $deployRoot)) {
        throw "Refusing to mirror outside deploy root: $destinationRoot"
    }

    Ensure-BFLDirectory (Split-Path -Parent $destinationRoot)

    if ((Test-Path -LiteralPath $destinationRoot) -and
        ((Get-Item -LiteralPath $destinationRoot -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Deployment slot is a link. Remove it before CleanCopy: $destinationRoot"
    }

    Invoke-BFLAddonMirror -SourceRoot $sourceRoot -DestinationRoot $destinationRoot
}

function Copy-BFLAddonToClientPath {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To,
        [Parameter(Mandatory = $true)][string]$ExpectedPath
    )

    $sourceRoot = Assert-BFLAddonRoot $From
    $destinationRoot = [System.IO.Path]::GetFullPath($To)
    $expectedRoot = [System.IO.Path]::GetFullPath($ExpectedPath)

    if (-not $destinationRoot.Equals($expectedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing direct client mirror to unexpected path: $destinationRoot"
    }

    if (Test-Path -LiteralPath $destinationRoot) {
        $existing = Get-Item -LiteralPath $destinationRoot -Force
        if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Refusing direct client mirror into a link: $destinationRoot"
        }

        $gitPath = Join-Path $existing.FullName '.git'
        if (Test-Path -LiteralPath $gitPath) {
            throw "Refusing direct client mirror into a repository root: $destinationRoot"
        }
    }

    Invoke-BFLAddonMirror -SourceRoot $sourceRoot -DestinationRoot $destinationRoot
}

function Test-BFLDirectClientMirrorTarget {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $existing = Get-Item -LiteralPath $Path -Force
    if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        return $false
    }

    $gitPath = Join-Path $existing.FullName '.git'
    return -not (Test-Path -LiteralPath $gitPath)
}

function Expand-BFLReleaseZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$To,
        [Parameter(Mandatory = $true)][string]$BFLRoot
    )

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw "Release ZIP not found: $ZipPath"
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BFLRelease_' + [System.Guid]::NewGuid().ToString('N'))
    Ensure-BFLDirectory $tempRoot
    try {
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempRoot -Force
        $candidate = Get-ChildItem -LiteralPath $tempRoot -Recurse -Filter 'BetterFriendlist.toc' |
            Select-Object -First 1
        if (-not $candidate) {
            throw "ZIP does not contain BetterFriendlist.toc"
        }
        Copy-BFLAddon -From (Split-Path -Parent $candidate.FullName) -To $To -BFLRoot $BFLRoot
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}
function Set-BFLAddonLink {
    param(
        [Parameter(Mandatory = $true)][string]$LinkPath,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Type,
        [switch]$Force
    )

    $resolvedTarget = Assert-BFLAddonRoot $TargetPath
    Ensure-BFLDirectory (Split-Path -Parent $LinkPath)

    if (Test-Path -LiteralPath $LinkPath) {
        $existing = Get-Item -LiteralPath $LinkPath -Force
        $existingTarget = $existing.Target -join '; '
        if (($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and
            $existingTarget.Equals($resolvedTarget, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "Link already correct: $LinkPath -> $resolvedTarget"
            return
        }

        if (-not $Force) {
            throw "Refusing to replace existing addon path without -Force: $LinkPath"
        }

        if (-not ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            $gitPath = Join-Path $existing.FullName '.git'
            if (Test-Path -LiteralPath $gitPath) {
                throw "Refusing to remove a repository root from the WoW folder: $LinkPath"
            }
        }

        if ($existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            [System.IO.Directory]::Delete($LinkPath)
        } else {
            Remove-Item -LiteralPath $LinkPath -Recurse -Force
        }

        if (Test-Path -LiteralPath $LinkPath) {
            throw "Failed to remove existing addon path: $LinkPath"
        }
    }

    New-Item -ItemType $Type -Path $LinkPath -Target $resolvedTarget -ErrorAction Stop | Out-Null
    Write-Host "Linked $LinkPath -> $resolvedTarget"
}

$clients = Resolve-BFLClients $Client
$rootPath = Resolve-BFLRoot $Root

foreach ($clientName in $clients) {
    $info = Get-BFLClientInfo -Client $clientName -Root $rootPath -WowRoot $WowRoot

    if (-not (Test-Path -LiteralPath $info.ClientRoot)) {
        Write-Host "Skipping missing client $($info.Key): $($info.ClientRoot)"
        continue
    }

    switch ($Mode) {
        'CleanCopy' {
            if (Test-BFLDirectClientMirrorTarget -Path $info.AddOnPath) {
                Write-Host "Mirroring CleanCopy directly to existing client AddOn folder: $($info.AddOnPath)"
                Copy-BFLAddonToClientPath -From $Source -To $info.AddOnPath -ExpectedPath $info.AddOnPath
                continue
            }

            Copy-BFLAddon -From $Source -To $info.DeployPath -BFLRoot $rootPath
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $info.DeployPath -Type $LinkType -Force:$Force
        }
        'Link' {
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $Source -Type $LinkType -Force:$Force
        }
        'Zip' {
            if ([string]::IsNullOrWhiteSpace($Zip)) {
                throw '-Zip is required for Zip mode.'
            }
            Expand-BFLReleaseZip -ZipPath $Zip -To $info.DeployPath -BFLRoot $rootPath
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $info.DeployPath -Type $LinkType -Force:$Force
        }
    }
}
