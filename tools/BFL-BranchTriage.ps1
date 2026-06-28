param(
    [string]$Base = 'main',
    [string]$Root,
    [string]$Repo,
    [switch]$IncludeRemote
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\BFL-Paths.ps1"

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

function Get-BFLWorktreeBranchMap {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    $map = @{}
    $output = & git -C $RepositoryPath worktree list --porcelain
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $currentPath = $null
    foreach ($line in $output) {
        if ($line.StartsWith('worktree ', [System.StringComparison]::Ordinal)) {
            $currentPath = $line.Substring(9)
            continue
        }
        if ($line.StartsWith('branch ', [System.StringComparison]::Ordinal)) {
            $branch = Get-BFLBranchNameFromRef $line.Substring(7)
            if (-not [string]::IsNullOrWhiteSpace($branch)) {
                $map[$branch] = $currentPath
            }
        }
    }

    return $map
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

function Get-BFLGitLine {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = & git -C $RepositoryPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    return ($output | Select-Object -First 1)
}

$rootPath = Resolve-BFLRoot $Root
if ([string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Join-Path $rootPath 'repos\BetterFriendlist'
}
$repoPath = [System.IO.Path]::GetFullPath($Repo)

Write-Host "[BFL] Branch triage for $repoPath"
Write-Host "[BFL] Base: $Base"
Write-Host ''

& git -C $repoPath rev-parse --verify $Base | Out-Null
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$currentBranch = Get-BFLGitLine -RepositoryPath $repoPath -Arguments @('branch', '--show-current')
$worktreeBranches = Get-BFLWorktreeBranchMap -RepositoryPath $repoPath
$format = '%(refname:short)|%(objectname:short)|%(contents:subject)'
$branchLines = @(& git -C $repoPath for-each-ref --format=$format refs/heads)
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$rows = @()
foreach ($line in $branchLines) {
    $parts = $line -split '\|', 3
    $branch = $parts[0]
    $head = $parts[1]
    $subject = if ($parts.Count -gt 2) { $parts[2] } else { '' }
    $hasWorktree = $worktreeBranches.ContainsKey($branch)
    $isCurrent = $branch.Equals($currentBranch, [System.StringComparison]::Ordinal)
    $isBase = $branch.Equals($Base, [System.StringComparison]::Ordinal)
    $isMerged = Test-BFLBranchMerged -RepositoryPath $repoPath -BranchName $branch -BaseBranch $Base
    $uniqueCount = [int](Get-BFLGitLine -RepositoryPath $repoPath -Arguments @('rev-list', '--count', "$Base..$branch"))
    $category = if ($isBase) {
        'base'
    } elseif ($hasWorktree) {
        'active-worktree'
    } elseif ($isMerged) {
        'merged-delete-candidate'
    } else {
        'unique-review'
    }

    $rows += [PSCustomObject]@{
        Category = $category
        Branch = $branch
        Head = $head
        Unique = $uniqueCount
        Worktree = if ($hasWorktree) { $worktreeBranches[$branch] } else { '' }
        Subject = $subject
        Current = if ($isCurrent) { '*' } else { '' }
    }
}

$rows |
    Sort-Object @{ Expression = 'Category'; Ascending = $true }, @{ Expression = 'Branch'; Ascending = $true } |
    Format-Table Category, Current, Branch, Unique, Head, Subject -AutoSize

Write-Host ''
Write-Host '[BFL] Summary'
foreach ($group in ($rows | Group-Object Category | Sort-Object Name)) {
    Write-Host ("{0}: {1}" -f $group.Name, $group.Count)
}

$deleteCandidates = @($rows | Where-Object { $_.Category -eq 'merged-delete-candidate' })
if ($deleteCandidates.Count -gt 0) {
    Write-Host ''
    Write-Host '[BFL] Merged local branches without worktrees'
    foreach ($row in $deleteCandidates) {
        Write-Host ("git branch -d {0}" -f $row.Branch)
    }
}

if ($IncludeRemote) {
    Write-Host ''
    Write-Host '[BFL] Remote tracking overview'
    & git -C $repoPath branch -vv
}
