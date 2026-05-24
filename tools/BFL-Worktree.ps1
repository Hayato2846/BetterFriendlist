param(
    [ValidateSet('Create', 'List', 'Prune')]
    [string]$Action = 'List',

    [string]$Name,
    [string]$Branch,
    [string]$Base = 'main',
    [string]$Root,
    [string]$Repo,
    [switch]$SkipVSCodeCopy
)

. "$PSScriptRoot\BFL-Paths.ps1"

$rootPath = Resolve-BFLRoot $Root
if ([string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Join-Path $rootPath 'repos\BetterFriendlist'
}
$repoPath = [System.IO.Path]::GetFullPath($Repo)
$worktreeRoot = Join-Path $rootPath 'worktrees\BetterFriendlist'

switch ($Action) {
    'List' {
        & git -C $repoPath worktree list
    }
    'Prune' {
        & git -C $repoPath worktree prune
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
    }
}
