param(
    [ValidateSet('Create', 'List', 'Prune', 'Workspace', 'Remove', 'Archive')]
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
    [string[]]$ExcludeImportedFolderName = @(),
    [string]$ArchiveBranch,
    [string]$ArchivePrefix = 'archive',
    [string]$BackupRoot,
    [switch]$DeleteBranch,
    [switch]$Force
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

function Get-BFLBranchNameFromRef {
    param([string]$Ref)

    if ([string]::IsNullOrWhiteSpace($Ref)) {
        return $null
    }
    if ($Ref.StartsWith('refs/heads/', [System.StringComparison]::Ordinal)) {
        return $Ref.Substring(11)
    }
    return $Ref
}

function Get-BFLWorktreeByName {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$WorktreeRoot,
        [Parameter(Mandatory = $true)][string]$WorktreeName
    )

    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $WorktreeRoot $WorktreeName))
    if (-not (Test-BFLPathUnder -Path $targetPath -Root $WorktreeRoot)) {
        throw "Refusing to touch path outside worktree root: $targetPath"
    }

    $entries = @(Get-BFLWorktreeEntries $RepositoryPath)
    $match = @(
        $entries | Where-Object {
            (Get-BFLNormalizedPath $_.Path).Equals((Get-BFLNormalizedPath $targetPath), [System.StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Path $_.Path -Leaf).Equals($WorktreeName, [System.StringComparison]::OrdinalIgnoreCase)
        }
    )

    if ($match.Count -eq 0) {
        throw "Worktree not found: $WorktreeName"
    }
    if ($match.Count -gt 1) {
        throw "Worktree name is ambiguous: $WorktreeName"
    }
    if ((Get-BFLNormalizedPath $match[0].Path).Equals((Get-BFLNormalizedPath $RepositoryPath), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to remove the main repository worktree.'
    }
    if (-not (Test-BFLPathUnder -Path $match[0].Path -Root $WorktreeRoot)) {
        throw "Refusing to remove worktree outside managed root: $($match[0].Path)"
    }

    return $match[0]
}

function Backup-BFLDirtyWorktree {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )

    $status = @(& git -C $Path status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    if ($status.Count -eq 0) {
        return $null
    }

    Ensure-BFLDirectory $DestinationRoot
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeName = $Name -replace '[^A-Za-z0-9._-]', '-'
    $backupPath = Join-Path $DestinationRoot "$timestamp-$safeName"
    Ensure-BFLDirectory $backupPath

    & git -C $Path status --short --branch | Set-Content -LiteralPath (Join-Path $backupPath 'status.txt') -Encoding UTF8
    & git -C $Path diff --binary | Set-Content -LiteralPath (Join-Path $backupPath 'worktree.diff') -Encoding UTF8
    & git -C $Path diff --cached --binary | Set-Content -LiteralPath (Join-Path $backupPath 'index.diff') -Encoding UTF8

    $untrackedRoot = Join-Path $backupPath 'untracked'
    $untrackedFiles = @(& git -C $Path ls-files --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    foreach ($file in $untrackedFiles) {
        $sourcePath = Join-Path $Path $file
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            continue
        }
        $targetPath = Join-Path $untrackedRoot $file
        Ensure-BFLDirectory (Split-Path -Path $targetPath -Parent)
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }

    Write-Host "Backed up dirty worktree changes to $backupPath"
    return $backupPath
}

function Test-BFLBranchMerged {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$BranchName,
        [Parameter(Mandatory = $true)][string]$BaseBranch
    )

    & git -C $RepositoryPath merge-base --is-ancestor $BranchName $BaseBranch
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        return $true
    }
    if ($exitCode -eq 1) {
        return $false
    }
    exit $exitCode
}

function Remove-BFLManagedWorktree {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$WorktreeRoot,
        [Parameter(Mandatory = $true)][string]$WorktreeName,
        [Parameter(Mandatory = $true)][string]$BackupDirectory,
        [Parameter(Mandatory = $true)][string]$BaseBranch,
        [string]$ArchiveTargetBranch,
        [string]$ArchivePrefixName = 'archive',
        [switch]$ShouldDeleteBranch,
        [switch]$ShouldForce
    )

    $entry = Get-BFLWorktreeByName -RepositoryPath $RepositoryPath -WorktreeRoot $WorktreeRoot -WorktreeName $WorktreeName
    $entryPath = [System.IO.Path]::GetFullPath($entry.Path)
    $entryBranch = Get-BFLBranchNameFromRef $entry.Branch

    $backupPath = Backup-BFLDirtyWorktree -Path $entryPath -Name $WorktreeName -DestinationRoot $BackupDirectory
    $removeArgs = @('-C', $RepositoryPath, 'worktree', 'remove')
    if ($null -ne $backupPath) {
        $removeArgs += '--force'
    }
    $removeArgs += $entryPath
    & git @removeArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host "Removed worktree: $entryPath"

    if ([string]::IsNullOrWhiteSpace($entryBranch)) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($ArchiveTargetBranch)) {
        & git -C $RepositoryPath show-ref --verify --quiet "refs/heads/$ArchiveTargetBranch"
        if ($LASTEXITCODE -eq 0) {
            throw "Archive branch already exists: $ArchiveTargetBranch"
        }
        & git -C $RepositoryPath branch -m $entryBranch $ArchiveTargetBranch
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Write-Host "Archived branch: $entryBranch -> $ArchiveTargetBranch"
        return
    }

    if ($ShouldDeleteBranch) {
        $isMerged = Test-BFLBranchMerged -RepositoryPath $RepositoryPath -BranchName $entryBranch -BaseBranch $BaseBranch
        if (-not $isMerged -and -not $ShouldForce) {
            throw "Branch '$entryBranch' is not merged into '$BaseBranch'. Re-run with -Force if deletion is intentional."
        }
        $deleteFlag = if ($ShouldForce) { '-D' } else { '-d' }
        & git -C $RepositoryPath branch $deleteFlag $entryBranch
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Write-Host "Deleted branch: $entryBranch"
    }
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
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $rootPath 'backups\worktree-archives'
} else {
    $BackupRoot = [System.IO.Path]::GetFullPath($BackupRoot)
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
    'Remove' {
        if ([string]::IsNullOrWhiteSpace($Name)) {
            throw '-Name is required for Remove.'
        }
        Remove-BFLManagedWorktree -RepositoryPath $repoPath -WorktreeRoot $worktreeRoot -WorktreeName $Name -BackupDirectory $BackupRoot -BaseBranch $Base -ShouldDeleteBranch:$DeleteBranch -ShouldForce:$Force
        if (-not $SkipVSCodeWorkspace) {
            Update-BFLVSCodeWorkspace -RepositoryPath $repoPath -RootPath $rootPath -WorktreeRoot $worktreeRoot -TargetPath $WorkspacePath -ImportWorkspacePath $ImportWorkspacePath -ExcludeImportedFolderName $ExcludeImportedFolderName
        }
    }
    'Archive' {
        if ([string]::IsNullOrWhiteSpace($Name)) {
            throw '-Name is required for Archive.'
        }
        if ([string]::IsNullOrWhiteSpace($ArchiveBranch)) {
            $ArchiveBranch = "$ArchivePrefix/$Name"
        }
        Remove-BFLManagedWorktree -RepositoryPath $repoPath -WorktreeRoot $worktreeRoot -WorktreeName $Name -BackupDirectory $BackupRoot -BaseBranch $Base -ArchiveTargetBranch $ArchiveBranch -ShouldForce:$Force
        if (-not $SkipVSCodeWorkspace) {
            Update-BFLVSCodeWorkspace -RepositoryPath $repoPath -RootPath $rootPath -WorktreeRoot $worktreeRoot -TargetPath $WorkspacePath -ImportWorkspacePath $ImportWorkspacePath -ExcludeImportedFolderName $ExcludeImportedFolderName
        }
    }
}
