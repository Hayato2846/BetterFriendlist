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
    [ValidateRange(0, 10)]
    [int]$MirrorRetries = 1,
    [ValidateRange(0, 30)]
    [int]$MirrorWaitSeconds = 1,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\BFL-Paths.ps1"

function Invoke-BFLAddonMirror {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRoot,
        [Parameter(Mandatory = $true)][string]$DestinationRoot,
        [string]$TocFile = 'BetterFriendlist.toc',
        [string[]]$ExtraExcludeDirs = @()
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
    if ($ExtraExcludeDirs.Count -gt 0) {
        $excludeDirs += $ExtraExcludeDirs
    }
    $excludeDirs = @($excludeDirs | Select-Object -Unique)

    $excludeFiles = @(
        '.git', '.gitignore', '.pkgmeta', '*.bak', '*.html', '*.log', '*.lua.bak',
        '*.md', '*.png', '*.ps1', '*.py', '*.txt', '*.zip'
    )

    Remove-BFLExcludedArtifacts -DestinationRoot $DestinationRoot -ExcludeDirs $excludeDirs -ExcludeFiles $excludeFiles

    $args = @(
        $SourceRoot, $DestinationRoot,
        '/MIR',
        "/R:$MirrorRetries",
        "/W:$MirrorWaitSeconds",
        '/NFL', '/NDL', '/NJH', '/NJS', '/NP',
        '/XD'
    ) +
        $excludeDirs + @('/XF') + $excludeFiles

    $robocopyOutput = & robocopy @args 2>&1
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -ge 8) {
        $details = @($robocopyOutput | Select-String -Pattern 'ERROR|FEHLER|Access denied|Zugriff verweigert' |
            Select-Object -First 8)
        if ($details.Count -eq 0) {
            $details = @($robocopyOutput | Select-Object -Last 12)
        }

        $detailText = ($details | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "robocopy failed with exit code $robocopyExitCode while mirroring '$SourceRoot' to '$DestinationRoot'. $detailText"
    }

    Assert-BFLAddonRootByToc -Path $DestinationRoot -TocFile $TocFile | Out-Null
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
        [Parameter(Mandatory = $true)][string]$BFLRoot,
        [string]$TocFile = 'BetterFriendlist.toc',
        [string[]]$ExtraExcludeDirs = @()
    )

    $sourceRoot = Assert-BFLAddonRootByToc -Path $From -TocFile $TocFile
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

    Invoke-BFLAddonMirror -SourceRoot $sourceRoot -DestinationRoot $destinationRoot -TocFile $TocFile -ExtraExcludeDirs $ExtraExcludeDirs
}

function Copy-BFLAddonToClientPath {
    param(
        [Parameter(Mandatory = $true)][string]$From,
        [Parameter(Mandatory = $true)][string]$To,
        [Parameter(Mandatory = $true)][string]$ExpectedPath,
        [string]$TocFile = 'BetterFriendlist.toc',
        [string[]]$ExtraExcludeDirs = @()
    )

    $sourceRoot = Assert-BFLAddonRootByToc -Path $From -TocFile $TocFile
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

    Invoke-BFLAddonMirror -SourceRoot $sourceRoot -DestinationRoot $destinationRoot -TocFile $TocFile -ExtraExcludeDirs $ExtraExcludeDirs
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

function Find-BFLAddonRootInExpandedZip {
    param(
        [Parameter(Mandatory = $true)][string]$TempRoot,
        [Parameter(Mandatory = $true)][string]$TocFile,
        [switch]$Required
    )

    $candidate = Get-ChildItem -LiteralPath $TempRoot -Recurse -Filter $TocFile |
        Select-Object -First 1
    if (-not $candidate) {
        if ($Required) {
            throw "ZIP does not contain $TocFile"
        }
        return $null
    }

    return Split-Path -Parent $candidate.FullName
}

function Expand-BFLReleaseZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$To,
        [string]$MenuBridgeTo,
        [Parameter(Mandatory = $true)][string]$BFLRoot
    )

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw "Release ZIP not found: $ZipPath"
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BFLRelease_' + [System.Guid]::NewGuid().ToString('N'))
    Ensure-BFLDirectory $tempRoot
    try {
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $tempRoot -Force
        $candidateRoot = Find-BFLAddonRootInExpandedZip -TempRoot $tempRoot -TocFile 'BetterFriendlist.toc' -Required
        Copy-BFLAddon -From $candidateRoot -To $To -BFLRoot $BFLRoot -ExtraExcludeDirs @('!BetterFriendlist_MenuBridge')

        $menuBridgeDeployed = $false
        if (-not [string]::IsNullOrWhiteSpace($MenuBridgeTo)) {
            $menuBridgeRoot = Find-BFLAddonRootInExpandedZip -TempRoot $tempRoot -TocFile '!BetterFriendlist_MenuBridge.toc'
            if ($menuBridgeRoot) {
                Copy-BFLAddon `
                    -From $menuBridgeRoot `
                    -To $MenuBridgeTo `
                    -BFLRoot $BFLRoot `
                    -TocFile '!BetterFriendlist_MenuBridge.toc'
                $menuBridgeDeployed = $true
            }
        }

        return [PSCustomObject]@{
            MenuBridgeDeployed = $menuBridgeDeployed
        }
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
        [string]$TocFile = 'BetterFriendlist.toc',
        [switch]$Force
    )

    $resolvedTarget = Assert-BFLAddonRootByToc -Path $TargetPath -TocFile $TocFile
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
            $menuBridgeSource = Join-Path ([System.IO.Path]::GetFullPath($Source)) '!BetterFriendlist_MenuBridge'
            if (Test-BFLDirectClientMirrorTarget -Path $info.AddOnPath) {
                Write-Host "Mirroring CleanCopy directly to existing client AddOn folder: $($info.AddOnPath)"
                Copy-BFLAddonToClientPath `
                    -From $Source `
                    -To $info.AddOnPath `
                    -ExpectedPath $info.AddOnPath `
                    -ExtraExcludeDirs @('!BetterFriendlist_MenuBridge')
                Write-Host "Mirroring CleanCopy directly to companion AddOn folder: $($info.MenuBridgeAddOnPath)"
                Copy-BFLAddonToClientPath `
                    -From $menuBridgeSource `
                    -To $info.MenuBridgeAddOnPath `
                    -ExpectedPath $info.MenuBridgeAddOnPath `
                    -TocFile '!BetterFriendlist_MenuBridge.toc'
                continue
            }

            Copy-BFLAddon -From $Source -To $info.DeployPath -BFLRoot $rootPath -ExtraExcludeDirs @('!BetterFriendlist_MenuBridge')
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $info.DeployPath -Type $LinkType -Force:$Force
            Copy-BFLAddon `
                -From $menuBridgeSource `
                -To $info.MenuBridgeDeployPath `
                -BFLRoot $rootPath `
                -TocFile '!BetterFriendlist_MenuBridge.toc'
            Set-BFLAddonLink `
                -LinkPath $info.MenuBridgeAddOnPath `
                -TargetPath $info.MenuBridgeDeployPath `
                -Type $LinkType `
                -TocFile '!BetterFriendlist_MenuBridge.toc' `
                -Force:$Force
        }
        'Link' {
            $menuBridgeSource = Join-Path ([System.IO.Path]::GetFullPath($Source)) '!BetterFriendlist_MenuBridge'
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $Source -Type $LinkType -Force:$Force
            Set-BFLAddonLink `
                -LinkPath $info.MenuBridgeAddOnPath `
                -TargetPath $menuBridgeSource `
                -Type $LinkType `
                -TocFile '!BetterFriendlist_MenuBridge.toc' `
                -Force:$Force
        }
        'Zip' {
            if ([string]::IsNullOrWhiteSpace($Zip)) {
                throw '-Zip is required for Zip mode.'
            }
            $zipDeploy = Expand-BFLReleaseZip `
                -ZipPath $Zip `
                -To $info.DeployPath `
                -MenuBridgeTo $info.MenuBridgeDeployPath `
                -BFLRoot $rootPath
            Set-BFLAddonLink -LinkPath $info.AddOnPath -TargetPath $info.DeployPath -Type $LinkType -Force:$Force
            if ($zipDeploy.MenuBridgeDeployed) {
                Set-BFLAddonLink `
                    -LinkPath $info.MenuBridgeAddOnPath `
                    -TargetPath $info.MenuBridgeDeployPath `
                    -Type $LinkType `
                    -TocFile '!BetterFriendlist_MenuBridge.toc' `
                    -Force:$Force
            } else {
                Write-Warning "ZIP does not contain !BetterFriendlist_MenuBridge; companion deployment skipped for $($info.Key)."
            }
        }
    }
}
