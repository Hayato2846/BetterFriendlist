Set-StrictMode -Version Latest

$script:BFLDefaultRoot = Join-Path $env:USERPROFILE 'Documents\BFL'
$script:BFLDefaultWowRoot = 'C:\Program Files (x86)\World of Warcraft'

function Get-BFLClientMap {
    [ordered]@{
        retail = '_retail_'
        ptr = '_ptr_'
        xptr = '_xptr_'
        beta = '_beta_'
        classic = '_classic_'
        classic_ptr = '_classic_ptr_'
        classic_era = '_classic_era_'
        anniversary = '_anniversary_'
    }
}

function Resolve-BFLRoot {
    param([string]$Root)

    if ([string]::IsNullOrWhiteSpace($Root)) {
        return $script:BFLDefaultRoot
    }
    return [System.IO.Path]::GetFullPath($Root)
}

function Resolve-BFLWowRoot {
    param([string]$WowRoot)

    if ([string]::IsNullOrWhiteSpace($WowRoot)) {
        return $script:BFLDefaultWowRoot
    }
    return [System.IO.Path]::GetFullPath($WowRoot)
}

function Resolve-BFLClients {
    param([string[]]$Client)

    $map = Get-BFLClientMap
    if (-not $Client -or $Client.Count -eq 0 -or $Client -contains 'all') {
        return @($map.Keys)
    }

    foreach ($name in $Client) {
        if (-not $map.Contains($name)) {
            throw "Unknown client '$name'. Valid values: $($map.Keys -join ', '), all"
        }
    }
    return $Client
}

function Get-BFLClientInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Client,
        [string]$Root,
        [string]$WowRoot
    )

    $map = Get-BFLClientMap
    if (-not $map.Contains($Client)) {
        throw "Unknown client '$Client'."
    }

    $rootPath = Resolve-BFLRoot $Root
    $wowRootPath = Resolve-BFLWowRoot $WowRoot
    $folderName = $map[$Client]
    $clientRoot = Join-Path $wowRootPath $folderName
    $addOnsRoot = Join-Path $clientRoot 'Interface\AddOns'
    $deployPath = Join-Path (Join-Path $rootPath "deploy\$Client") 'BetterFriendlist'
    $menuBridgeAddonName = '!BetterFriendlist_MenuBridge'
    $menuBridgeDeployPath = Join-Path (Join-Path $rootPath "deploy\$Client") $menuBridgeAddonName

    [PSCustomObject]@{
        Key = $Client
        FolderName = $folderName
        ClientRoot = $clientRoot
        AddOnsRoot = $addOnsRoot
        AddOnPath = Join-Path $addOnsRoot 'BetterFriendlist'
        DeployPath = $deployPath
        MenuBridgeAddOnPath = Join-Path $addOnsRoot $menuBridgeAddonName
        MenuBridgeDeployPath = $menuBridgeDeployPath
        SavedVariablesRoot = Join-Path $clientRoot 'WTF\Account'
    }
}

function Assert-BFLAddonRootByToc {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TocFile,
        [string]$Label = 'addon root'
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $tocPath = Join-Path $fullPath $TocFile
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
        throw "Not a $Label ($TocFile missing): $fullPath"
    }
    return $fullPath
}

function Assert-BFLAddonRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    return Assert-BFLAddonRootByToc -Path $Path -TocFile 'BetterFriendlist.toc' -Label 'BetterFriendlist addon root'
}

function Assert-BFLMenuBridgeAddonRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    return Assert-BFLAddonRootByToc -Path $Path -TocFile '!BetterFriendlist_MenuBridge.toc' -Label 'BetterFriendlist menu bridge addon root'
}

function Ensure-BFLDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Test-BFLPathUnder {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    return $fullPath.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
        $fullPath.StartsWith($fullRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
}
