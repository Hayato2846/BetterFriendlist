param(
    [ValidateSet('Create', 'List', 'Prune', 'Workspace')]
    [string]$Action = 'List',

    [string]$Name,
    [string]$Branch,
    [string]$Base = 'main',
    [string]$Root,
    [string]$Repo,
    [switch]$SkipVSCodeCopy,
    [switch]$SkipVSCodeWorkspace,
    [string]$WorkspacePath,
    [string]$ImportWorkspacePath,
    [string[]]$ExcludeImportedFolderName = @()
)

. "$PSScriptRoot\BFL-Paths.ps1"

function Get-BFLNormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function ConvertTo-BFLJsonValue {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $result = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-BFLJsonValue $property.Value
        }
        return $result
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $result[$key] = ConvertTo-BFLJsonValue $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += ConvertTo-BFLJsonValue $item
        }
        return @($items)
    }

    return $Value
}

function Get-BFLWorktreeEntries {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    $output = & git -C $RepositoryPath worktree list --porcelain
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $current = $null
    foreach ($line in $output) {
        if ($line.StartsWith('worktree ', [System.StringComparison]::Ordinal)) {
            if ($null -ne $current) {
                $entries.Add([PSCustomObject]$current)
            }
            $current = [ordered]@{
                Path = $line.Substring(9)
                Head = $null
                Branch = $null
            }
        } elseif ($null -ne $current -and $line.StartsWith('HEAD ', [System.StringComparison]::Ordinal)) {
            $current.Head = $line.Substring(5)
        } elseif ($null -ne $current -and $line.StartsWith('branch ', [System.StringComparison]::Ordinal)) {
            $current.Branch = $line.Substring(7)
        }
    }

    if ($null -ne $current) {
        $entries.Add([PSCustomObject]$current)
    }

    return @($entries | Sort-Object Path)
}

function Get-BFLWorkspaceFolderName {
    param(
        [Parameter(Mandatory = $true)]$Entry,
        [Parameter(Mandatory = $true)][string]$RepositoryPath
    )

    $entryPath = [System.IO.Path]::GetFullPath($Entry.Path).TrimEnd('\')
    $repoPath = [System.IO.Path]::GetFullPath($RepositoryPath).TrimEnd('\')
    if ($entryPath.Equals($repoPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return 'main'
    }

    return "wt-$(Split-Path -Path $entryPath -Leaf)"
}

function Get-BFLWorkspaceFoldersFromFile {
    param([Parameter(Mandatory = $true)][string]$WorkspaceFilePath)

    $workspaceFullPath = [System.IO.Path]::GetFullPath($WorkspaceFilePath)
    if (-not (Test-Path -LiteralPath $workspaceFullPath -PathType Leaf)) {
        return @()
    }

    $workspace = Get-Content -Raw -LiteralPath $workspaceFullPath | ConvertFrom-Json
    $basePath = Split-Path -Path $workspaceFullPath -Parent
    $folders = @()
    foreach ($folder in @($workspace.folders)) {
        $folderName = $null
        $folderPath = $null

        if ($folder -is [string]) {
            $folderPath = $folder
        } else {
            $folderName = $folder.name
            $folderPath = $folder.path
        }

        if ([string]::IsNullOrWhiteSpace($folderPath)) {
            continue
        }

        if ([System.IO.Path]::IsPathRooted($folderPath)) {
            $resolvedPath = [System.IO.Path]::GetFullPath($folderPath)
        } else {
            $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $basePath $folderPath))
        }

        if ([string]::IsNullOrWhiteSpace($folderName)) {
            $folderName = Split-Path -Path $resolvedPath -Leaf
        }

        $folders += [ordered]@{
            name = $folderName
            path = $resolvedPath
        }
    }

    return @($folders)
}

function Get-BFLWorkspaceSettings {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$WorktreeRoot
    )

    $settings = [ordered]@{}
    $repoSettingsPath = Join-Path $RepositoryPath '.vscode\settings.json'
    if (Test-Path -LiteralPath $repoSettingsPath -PathType Leaf) {
        $repoSettings = Get-Content -Raw -LiteralPath $repoSettingsPath | ConvertFrom-Json
        foreach ($property in $repoSettings.PSObject.Properties) {
            $settings[$property.Name] = ConvertTo-BFLJsonValue $property.Value
        }
    }

    $settings['git.autoRepositoryDetection'] = $true
    $settings['git.scanRepositories'] = @(
        [System.IO.Path]::GetFullPath($RepositoryPath),
        [System.IO.Path]::GetFullPath($WorktreeRoot)
    )
    $settings['git.repositoryScanMaxDepth'] = 2

    return $settings
}

function Add-BFLLuaIgnoredPaths {
    param(
        [Parameter(Mandatory = $true)]$Settings,
        [string[]]$Paths
    )

    if (-not $Paths -or $Paths.Count -eq 0) {
        return
    }

    $key = 'Lua.workspace.ignoreDir'
    $ignoredPaths = @()
    if ($Settings.Contains($key)) {
        $ignoredPaths = @($Settings[$key])
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $merged = @()
    foreach ($path in @($ignoredPaths + $Paths)) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        if ($seen.Add($path)) {
            $merged += $path
        }
    }

    $Settings[$key] = @($merged)
}

function Update-BFLVSCodeWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][string]$WorktreeRoot,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [string]$ImportWorkspacePath,
        [string[]]$ExcludeImportedFolderName = @()
    )

    $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
    Ensure-BFLDirectory (Split-Path -Path $targetFullPath -Parent)

    $folders = [System.Collections.Generic.List[object]]::new()
    $knownPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $excludedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($folderName in $ExcludeImportedFolderName) {
        if (-not [string]::IsNullOrWhiteSpace($folderName)) {
            [void]$excludedNames.Add($folderName)
        }
    }

    foreach ($entry in Get-BFLWorktreeEntries $RepositoryPath) {
        $entryPath = [System.IO.Path]::GetFullPath($entry.Path)
        if (-not (Test-Path -LiteralPath $entryPath -PathType Container)) {
            Write-Warning "Skipping missing worktree path in VSCode workspace: $entryPath"
            continue
        }

        [void]$knownPaths.Add((Get-BFLNormalizedPath $entryPath))
        $folders.Add([ordered]@{
            name = Get-BFLWorkspaceFolderName -Entry $entry -RepositoryPath $RepositoryPath
            path = $entryPath
        })
    }

    $rootNormalizedPath = Get-BFLNormalizedPath $RootPath
    $extraIgnoredPaths = @()
    $extraSources = @($targetFullPath)
    if (-not [string]::IsNullOrWhiteSpace($ImportWorkspacePath)) {
        $extraSources += [System.IO.Path]::GetFullPath($ImportWorkspacePath)
    }

    foreach ($sourcePath in $extraSources) {
        foreach ($folder in Get-BFLWorkspaceFoldersFromFile $sourcePath) {
            $folderNormalizedPath = Get-BFLNormalizedPath $folder.path
            if ($knownPaths.Contains($folderNormalizedPath)) {
                continue
            }
            if ($folderNormalizedPath.Equals($rootNormalizedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Host "Skipped nested BFL root in VSCode workspace: $($folder.path)"
                continue
            }
            if ($excludedNames.Contains($folder.name)) {
                Write-Host "Skipped imported VSCode workspace folder by name: $($folder.name)"
                continue
            }
            if (-not (Test-Path -LiteralPath $folder.path -PathType Container)) {
                Write-Warning "Skipping missing imported VSCode workspace folder: $($folder.path)"
                continue
            }

            [void]$knownPaths.Add($folderNormalizedPath)
            $folders.Add([ordered]@{
                name = $folder.name
                path = [System.IO.Path]::GetFullPath($folder.path)
            })
            $extraIgnoredPaths += [System.IO.Path]::GetFullPath($folder.path)
        }
    }

    $settings = Get-BFLWorkspaceSettings -RepositoryPath $RepositoryPath -WorktreeRoot $WorktreeRoot
    Add-BFLLuaIgnoredPaths -Settings $settings -Paths $extraIgnoredPaths

    $workspace = [ordered]@{
        folders = @($folders)
        settings = $settings
    }

    $json = $workspace | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath $targetFullPath -Value $json -Encoding UTF8
    Write-Host "Updated VSCode workspace: $targetFullPath"
}

$rootPath = Resolve-BFLRoot $Root
if ([string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Join-Path $rootPath 'repos\BetterFriendlist'
}
$repoPath = [System.IO.Path]::GetFullPath($Repo)
$worktreeRoot = Join-Path $rootPath 'worktrees\BetterFriendlist'
if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
    $WorkspacePath = Join-Path $repoPath 'BetterFriendlist.code-workspace'
} else {
    $WorkspacePath = [System.IO.Path]::GetFullPath($WorkspacePath)
}

switch ($Action) {
    'List' {
        & git -C $repoPath worktree list
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    'Prune' {
        & git -C $repoPath worktree prune
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        if (-not $SkipVSCodeWorkspace) {
            Update-BFLVSCodeWorkspace -RepositoryPath $repoPath -RootPath $rootPath -WorktreeRoot $worktreeRoot -TargetPath $WorkspacePath -ImportWorkspacePath $ImportWorkspacePath -ExcludeImportedFolderName $ExcludeImportedFolderName
        }
    }
    'Workspace' {
        Update-BFLVSCodeWorkspace -RepositoryPath $repoPath -RootPath $rootPath -WorktreeRoot $worktreeRoot -TargetPath $WorkspacePath -ImportWorkspacePath $ImportWorkspacePath -ExcludeImportedFolderName $ExcludeImportedFolderName
    }
    'Create' {
        if ([string]::IsNullOrWhiteSpace($Name)) {
            throw '-Name is required for Create.'
        }
        if ([string]::IsNullOrWhiteSpace($Branch)) {
            $Branch = "feat/$Name"
        }
        Ensure-BFLDirectory $worktreeRoot
        $target = Join-Path $worktreeRoot $Name
        if (Test-Path -LiteralPath $target) {
            throw "Worktree target already exists: $target"
        }
        & git -C $repoPath worktree add $target -b $Branch $Base
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }

        $sourceVSCode = Join-Path $repoPath '.vscode'
        $targetVSCode = Join-Path $target '.vscode'
        if (-not $SkipVSCodeCopy -and (Test-Path -LiteralPath $sourceVSCode) -and -not (Test-Path -LiteralPath $targetVSCode)) {
            Copy-Item -LiteralPath $sourceVSCode -Destination $targetVSCode -Recurse -Force
            Write-Host "Copied local VSCode settings to $targetVSCode"
        }
        if (-not $SkipVSCodeWorkspace) {
            Update-BFLVSCodeWorkspace -RepositoryPath $repoPath -RootPath $rootPath -WorktreeRoot $worktreeRoot -TargetPath $WorkspacePath -ImportWorkspacePath $ImportWorkspacePath -ExcludeImportedFolderName $ExcludeImportedFolderName
        }
    }
}
