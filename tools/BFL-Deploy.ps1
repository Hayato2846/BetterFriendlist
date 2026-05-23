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

. "$PSScriptRoot\BFL-Paths.ps1"

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

    $excludeDirs = @(
        '.git', '.github', '.vscode', '.codex-worktrees', '.ai-context',
        'docs', 'memory-bank', 'old_version', 'plans', 'predecessor',
        'reference', 'tools', 'WoW UI Source'
    )
    $excludeFiles = @(
        '.gitignore', '.pkgmeta', '*.bak', '*.html', '*.log', '*.lua.bak',
        '*.md', '*.png', '*.ps1', '*.txt', '*.zip'
    )

    $args = @($sourceRoot, $destinationRoot, '/MIR', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/XD') +
        $excludeDirs + @('/XF') + $excludeFiles

    & robocopy @args | Out-Null
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }

    Assert-BFLAddonRoot $destinationRoot | Out-Null
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

        Remove-Item -LiteralPath $LinkPath -Recurse -Force
    }

    New-Item -ItemType $Type -Path $LinkPath -Target $resolvedTarget | Out-Null
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
