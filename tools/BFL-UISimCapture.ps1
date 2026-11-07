#requires -Version 7.2
[CmdletBinding()]
param(
    [ValidatePattern('^[a-z_]+$')]
    [string]$Profile = 'friends_headers_i18n',
    [ValidateSet('friends', 'nickname_hint')]
    [string]$Scenario = 'friends',
    [ValidateSet('normal', 'narrow', 'modern-collapsed', 'modern-expanded', 'legacy-collapsed', 'legacy-expanded')]
    [string]$Variant,
    [string]$SimulatorHome,
    [string]$WowRoot,
    [string]$OutputDirectory,
    [switch]$RawTextAlignment,
    [switch]$Fade
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/BFL-Paths.ps1"

function Copy-CaptureTree {
    param([string]$Source, [string]$Destination)

    $copyLog = & robocopy $Source $Destination /E /XJ /R:0 /W:0 /NFL /NDL /NJH /NJS /NP 2>&1
    if ($LASTEXITCODE -ge 8) {
        throw "Could not stage '$Source' in '$Destination'. $($copyLog -join ' ')"
    }
}

$source = Assert-BFLAddonRoot (Split-Path -Parent $PSScriptRoot)
$bflRoot = Resolve-BFLRoot
$wowRoot = Resolve-BFLWowRoot $WowRoot
$variants = @('normal', 'narrow')
$crop = '600x850+30+20'
if ($Fade -and $Scenario -ne 'nickname_hint') {
    throw '-Fade requires the nickname_hint scenario.'
}
if ($Scenario -eq 'nickname_hint') {
    $variants = @('modern-collapsed', 'modern-expanded', 'legacy-collapsed', 'legacy-expanded')
    $crop = '850x850+30+20'
}
if ($Variant) {
    if ($Variant -notin $variants) {
        throw "Variant '$Variant' does not belong to scenario '$Scenario'. Available variants: $($variants -join ', ')."
    }
    $variants = @($Variant)
}
if (-not $SimulatorHome) {
    $SimulatorHome = Join-Path $bflRoot 'references/wow-ui-sim-v0.1.40'
}
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $bflRoot 'diagnostics/bfl-ui-tests'
}
$simulator = Join-Path ([IO.Path]::GetFullPath($SimulatorHome)) 'wow-sim.exe'
$SimulatorHome = Split-Path -Parent $simulator
$seed = Join-Path $SimulatorHome 'blizzard-cache/AddOns'
$provenanceFile = '.wow-ui-sim-blizzard-ui-provenance'
$completeFile = '.wow-ui-sim-blizzard-ui-complete'
foreach ($required in @($simulator, (Join-Path $seed $provenanceFile), (Join-Path $seed $completeFile))) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Missing simulator kit file '$required'. Use the prepared Windows Retail v0.1.40 kit with -SimulatorHome."
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $wowRoot 'Data/data') -PathType Container)) {
    throw "WoW game data is missing under '$wowRoot'. Specify the install root with -WowRoot."
}

$localCache = Join-Path $env:LOCALAPPDATA 'wow-ui-sim/blizzard-ui/retail/AddOns'
$localProvenance = Join-Path $localCache $provenanceFile
if ((Test-Path -LiteralPath $localProvenance) -and
    ([IO.File]::ReadAllText($localProvenance) -cne [IO.File]::ReadAllText((Join-Path $seed $provenanceFile)))) {
    throw "The Windows Retail simulator cache already belongs to a different build at '$localCache'. Run in the Codex sandbox with a fresh local cache."
}
Copy-CaptureTree $seed $localCache

$runLabel = if ($Scenario -eq 'friends') { $Profile } else { $Scenario }
$runName = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$runLabel-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
$run = Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) $runName
$addons = Join-Path $run 'AddOns'
$staging = Join-Path $addons 'BetterFriendlist'
$emptyImport = Join-Path $run 'empty-import'
Ensure-BFLDirectory $staging
Ensure-BFLDirectory $emptyImport
Write-Host "[BFL UI] Capturing $runLabel in $run"

Get-ChildItem -LiteralPath $source -File | Where-Object Extension -in '.lua', '.xml', '.toc' |
    Copy-Item -Destination $staging
foreach ($folder in 'Data', 'Icons', 'Libs', 'Locales', 'Modules', 'TestData', 'Textures', 'UI', 'Utils') {
    Copy-CaptureTree (Join-Path $source $folder) (Join-Path $staging $folder)
}

# Only enable the simulator override for fields the current template declares as left-aligned.
$leftAlignedFields = @()
if (-not $RawTextAlignment) {
    [xml]$templates = Get-Content -LiteralPath (Join-Path $staging 'BetterFriendlist_Modern.xml') -Raw
    $card = $templates.SelectSingleNode("//*[@name='BFLModernFriendCardTemplate']")
    if ($card) {
        foreach ($field in 'Name', 'Info') {
            if ($card.SelectSingleNode(".//*[local-name()='FontString' and @parentKey='$field' and @justifyH='LEFT']")) {
                $leftAlignedFields += "'$field'"
            }
        }
    }
}

$enableFile = Join-Path $run 'AddOns.txt'
Set-Content -LiteralPath $enableFile -Value 'BetterFriendlist: enabled' -Encoding utf8NoBOM
$scene = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'BFL-UISimCapture.lua') -Raw
foreach ($captureVariant in $variants) {
    $narrow = ($captureVariant -eq 'narrow').ToString().ToLowerInvariant()
    $hintStyle = if ($Scenario -eq 'nickname_hint') { "'$($captureVariant.Split('-')[0])'" } else { 'nil' }
    $hintExpanded = $captureVariant.EndsWith('-expanded').ToString().ToLowerInvariant()
    $hintFade = $Fade.IsPresent.ToString().ToLowerInvariant()
    $configuration = "local profile, narrow, leftAlignedFields, hintStyle, hintExpanded, hintFade = '$Profile', $narrow, {$($leftAlignedFields -join ', ')}, $hintStyle, $hintExpanded, $hintFade"
    $lua = Join-Path $run "$captureVariant.lua"
    $png = Join-Path $run "$captureVariant.png"
    $log = Join-Path $run "$captureVariant.log"
    [IO.File]::WriteAllText($lua, "$configuration`n$scene")

    $process = [Diagnostics.ProcessStartInfo]::new($simulator)
    $process.UseShellExecute = $false
    $process.CreateNoWindow = $true
    $process.RedirectStandardOutput = $true
    $process.RedirectStandardError = $true
    $process.StandardOutputEncoding = [Text.Encoding]::UTF8
    $process.StandardErrorEncoding = [Text.Encoding]::UTF8
    $process.Environment['WOW_SIM_NO_ERROR_DIALOG'] = '1'
    $process.Environment['WOW_SIM_NO_SOUND'] = '1'
    $process.Environment['WOW_INSTALL_PATH'] = $wowRoot
    $process.Environment['APPDATA'] = Join-Path $run 'appdata'
    $process.Environment['ASSET_RESOLVER_CACHE_DIR'] = Join-Path $SimulatorHome 'asset-cache'
    $process.Environment['WOW_SIM_WTF_PATH'] = $emptyImport
    $process.Environment['WOW_SIM_ADDONS_TXT'] = $enableFile
    $arguments = @('--no-saved-vars', '--addons-path', $addons, '--session-wtf-path',
        (Join-Path $run "session-$captureVariant"), '--exec-lua', "@$lua", 'screenshot', '--png',
        '--width', '1600', '--height', '900', '-f', 'BetterFriendsFrame',
        '--dump-tree', 'BetterFriendsFrame', '--crop', $crop, '-o', $png)
    foreach ($argument in $arguments) {
        $process.ArgumentList.Add($argument)
    }

    Write-Host "[BFL UI] Rendering $captureVariant"
    $capture = [Diagnostics.Process]::Start($process)
    try {
        $stdout = $capture.StandardOutput.ReadToEndAsync()
        $stderr = $capture.StandardError.ReadToEndAsync()
        $finished = $capture.WaitForExit(180000)
        if (-not $finished) {
            $capture.Kill()
            $capture.WaitForExit()
        }
        [IO.File]::WriteAllText($log, "$($stderr.GetAwaiter().GetResult())`n$($stdout.GetAwaiter().GetResult())")
        if (-not $finished) {
            throw "The $captureVariant capture timed out after three minutes. See '$log'."
        }
        $frame = Select-String -LiteralPath $log -Pattern '^BetterFriendsFrame \[Frame\] .* visible ' | Select-Object -First 1
        if ($capture.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $png) -or -not $frame -or
            -not (Select-String -LiteralPath $log -SimpleMatch 'BFLUISimCaptureComplete' -Quiet)) {
            throw "The $captureVariant capture did not finish the BFL scene. See '$log'."
        }
        Write-Host "[BFL UI] $($frame.Line.Trim())"
        Write-Host "[BFL UI] $png"
    } finally {
        $capture.Dispose()
    }
}
