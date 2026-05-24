param(
    [string]$BaseRef = $env:BFL_REVIEW_BASE,
    [switch]$SkipPackageCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$script:Failures = @()
$script:Warnings = @()
$script:SummaryLines = @()

function Add-SummaryLine {
    param([string]$Line = '')
    $script:SummaryLines += $Line
}

function Write-ReviewLine {
    param([string]$Line = '')
    Write-Host $Line
    Add-SummaryLine $Line
}

function Write-ReviewSection {
    param([string]$Title)
    Write-ReviewLine ''
    Write-ReviewLine "## $Title"
}

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    Add-SummaryLine "- FAIL: $Message"
}

function Add-Warning {
    param([string]$Message)
    $script:Warnings += $Message
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
    Add-SummaryLine "- WARN: $Message"
}

function Normalize-RepoPath {
    param([string]$Path)
    return ($Path -replace '\\', '/').TrimStart('/')
}

function Get-ReviewChangedFiles {
    $files = @()

    if (-not [string]::IsNullOrWhiteSpace($BaseRef)) {
        $baseDiff = @(& git diff --name-only "$BaseRef...HEAD" 2>$null)
        if ($LASTEXITCODE -eq 0) {
            $files += $baseDiff
        } else {
            Add-Warning "Could not diff against base ref '$BaseRef'. Falling back to local working-tree changes."
        }
    }

    if ($files.Count -eq 0) {
        $files += @(& git diff --name-only)
        $files += @(& git diff --name-only --cached)
    }
    $files += @(& git ls-files --others --exclude-standard)

    return @(
        $files |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { Normalize-RepoPath $_ } |
            Sort-Object -Unique
    )
}

function Test-TocReferences {
    param([string]$RepoRoot)

    $tocPath = Join-Path $RepoRoot 'BetterFriendlist.toc'
    if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
        Add-Failure 'BetterFriendlist.toc is missing.'
        return
    }

    $missing = @()
    foreach ($rawLine in Get-Content -LiteralPath $tocPath) {
        $line = $rawLine.Trim().TrimStart([char]0xFEFF)
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#') -or $line.StartsWith('##')) {
            continue
        }

        $entry = [regex]::Replace($line, '\s+\[AllowLoadGameType\s+[^\]]+\]\s*$', '').Trim()
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        $relativePath = $entry -replace '/', '\'
        $absolutePath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            $missing += $entry
        }
    }

    if ($missing.Count -gt 0) {
        Add-Failure "TOC references missing files: $($missing -join ', ')"
    } else {
        Write-ReviewLine '[OK] TOC references all exist.'
    }
}

function Get-LocaleKeysFromContent {
    param([string]$Content)

    return @(
        [regex]::Matches($Content, '\bL\.([A-Z0-9_]+)\s*=') |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique
    )
}

function Get-LocaleKeys {
    param([string]$Path)

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return @(Get-LocaleKeysFromContent $content)
}

function Get-LocaleKeysAtRef {
    param(
        [string]$Ref,
        [string]$RepoPath
    )

    $content = @(& git show "${Ref}:${RepoPath}" 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @(Get-LocaleKeysFromContent ($content -join "`n"))
}

function Test-LocaleKeyCoverage {
    param(
        [string]$RepoRoot,
        [string[]]$ChangedFiles,
        [string]$BaseRef
    )

    $localeDir = Join-Path $RepoRoot 'Locales'
    $expectedLocales = @('enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'ptBR', 'ruRU', 'koKR', 'zhCN', 'zhTW')
    $baselinePath = Join-Path $localeDir 'enUS.lua'
    $changedLocaleFiles = @($ChangedFiles | Where-Object { $_ -match '^Locales/.*\.lua$' })

    if ($changedLocaleFiles.Count -eq 0) {
        Write-ReviewLine '[OK] No locale files changed; locale key coverage skipped.'
        return
    }

    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
        Add-Failure 'Locales/enUS.lua is missing.'
        return
    }

    $baselineKeys = Get-LocaleKeys $baselinePath
    $newEnUSKeys = @()
    if (-not [string]::IsNullOrWhiteSpace($BaseRef) -and ($ChangedFiles -contains 'Locales/enUS.lua')) {
        $baseKeys = @(Get-LocaleKeysAtRef -Ref $BaseRef -RepoPath 'Locales/enUS.lua')
        if ($baseKeys.Count -gt 0) {
            $newEnUSKeys = @($baselineKeys | Where-Object { $baseKeys -notcontains $_ })
        }
    }

    if ($newEnUSKeys.Count -gt 0) {
        foreach ($locale in $expectedLocales | Where-Object { $_ -ne 'enUS' }) {
            $path = Join-Path $localeDir "$locale.lua"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                Add-Failure "Locale file missing: Locales/$locale.lua"
                continue
            }

            $keys = Get-LocaleKeys $path
            $missingNewKeys = @($newEnUSKeys | Where-Object { $keys -notcontains $_ })
            if ($missingNewKeys.Count -gt 0) {
                Add-Failure "Locales/$locale.lua is missing new enUS key(s): $($missingNewKeys -join ', ')"
            }
        }
    } elseif ($ChangedFiles -contains 'Locales/enUS.lua') {
        Add-Warning 'Locales/enUS.lua changed, but no base ref was available for new-key detection. Review all locale files manually.'
    }

    foreach ($locale in $expectedLocales) {
        $path = Join-Path $localeDir "$locale.lua"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Add-Failure "Locale file missing: Locales/$locale.lua"
            continue
        }

        $keys = Get-LocaleKeys $path
        $missing = @($baselineKeys | Where-Object { $keys -notcontains $_ })
        $extra = @($keys | Where-Object { $baselineKeys -notcontains $_ })

        if ($missing.Count -gt 0) {
            $sample = ($missing | Select-Object -First 12) -join ', '
            Add-Warning "Locales/$locale.lua is missing $($missing.Count) baseline key(s): $sample"
        }
        if ($extra.Count -gt 0) {
            $sample = ($extra | Select-Object -First 12) -join ', '
            Add-Warning "Locales/$locale.lua has $($extra.Count) key(s) not present in enUS: $sample"
        }
    }

    if ($newEnUSKeys.Count -gt 0) {
        Write-ReviewLine "[OK] Checked $($newEnUSKeys.Count) new enUS locale key(s) across $($expectedLocales.Count - 1) translated locales."
    } else {
        Write-ReviewLine "[OK] Locale coverage scan completed for changed locale files."
    }
}

function Test-StaticLuaPatterns {
    param(
        [string]$RepoRoot,
        [string[]]$ChangedFiles
    )

    $luaFiles = @(
        $ChangedFiles |
            Where-Object {
                $_ -like '*.lua' -and
                (Normalize-RepoPath $_) -notmatch '^(old_version|reference|predecessor)/'
            }
    )

    if ($luaFiles.Count -eq 0) {
        Write-ReviewLine '[OK] No changed Lua files; static Lua pattern scan skipped.'
        return
    }

    $retailOnlyApis = @(
        @{ Name = 'C_Texture'; Guard = 'C_Texture\s+and|BFL\.IsRetail|BFL\.Has' },
        @{ Name = 'Enum.TitleIconVersion'; Guard = 'Enum\s+and|BFL\.IsRetail|BFL\.Has' },
        @{ Name = 'C_MythicPlus'; Guard = 'C_MythicPlus\s+and|BFL\.IsRetail|BFL\.Has' },
        @{ Name = 'C_ChallengeMode'; Guard = 'C_ChallengeMode\s+and|BFL\.IsRetail|BFL\.Has' }
    )

    foreach ($file in $luaFiles) {
        $path = Join-Path $RepoRoot ($file -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $lines = @(Get-Content -LiteralPath $path -Encoding UTF8)
        $warnedApi = @{}

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $trimmed = $line.Trim()
            if ($trimmed.StartsWith('--')) {
                continue
            }

            $lineNo = $i + 1

            if ($line -match '\bor\s+true\b' -and $line -notmatch 'FIX|or true pattern') {
                Add-Failure "${file}:$lineNo uses 'or true'; use an explicit nil check."
            }

            if ($line -match 'C_Timer\.New(Timer|Ticker)\s*\(' -and $line -notmatch '=\s*C_Timer\.New(Timer|Ticker)\s*\(') {
                Add-Failure "${file}:$lineNo creates a timer without storing the handle."
            }

            if ($line -match '\bprint\s*\(') {
                Add-Failure "${file}:$lineNo uses raw print(); use BFL:DebugPrint() or remove debug output."
            }

            foreach ($api in $retailOnlyApis) {
                $apiName = $api['Name']
                if ($line -notmatch [regex]::Escape($apiName)) {
                    continue
                }
                if ($warnedApi.ContainsKey($apiName)) {
                    continue
                }

                $start = [Math]::Max(0, $i - 5)
                $window = ($lines[$start..$i] -join "`n")
                if ($window -notmatch $api['Guard']) {
                    Add-Warning "${file}:$lineNo uses $apiName; verify Retail/Classic guard or project feature flag."
                    $warnedApi[$apiName] = $true
                }
            }
        }
    }

    Write-ReviewLine "[OK] Static Lua pattern scan completed for $($luaFiles.Count) changed file(s)."
}

function Write-RiskSummary {
    param([string[]]$ChangedFiles)

    if ($ChangedFiles.Count -eq 0) {
        Write-ReviewLine 'No changed files detected for diff-based review hints.'
        return
    }

    $rules = @(
        @{ Name = 'Cross-flavor load'; Regex = '(^BetterFriendlist\.toc$|\.xml$)'; Hint = 'Check AllowLoadGameType, Retail XML, and Classic XML paths.' },
        @{ Name = 'SavedVariables and migration'; Regex = '^Modules/Database\.lua$'; Hint = 'Check defaults, migrations, nil handling, and old profile behavior.' },
        @{ Name = 'Localization'; Regex = '^Locales/'; Hint = 'Check all 11 locale files and UTF-8 text.' },
        @{ Name = 'Secure, taint, combat'; Regex = '(RaidFrame|MenuSystem|GuildFrame|GuildDetails|Tooltip|RAF|QuickJoin)'; Hint = 'Check hooks, protected attributes, combat lockdown, and secret values.' },
        @{ Name = 'Settings and beta isolation'; Regex = '(Settings|SettingsComponents|PreviewMode|FilterSortRegistry|QuickFilters)'; Hint = 'Check beta-disabled behavior, settings cache invalidation, and user-facing strings.' },
        @{ Name = 'Release and packaging'; Regex = '(^\.pkgmeta$|^\.github/|^tools/|^docs/DEPLOYMENT_TESTING\.md$)'; Hint = 'Check package exclusions, CI behavior, and local workflow docs.' }
    )

    $matchedAny = $false
    foreach ($rule in $rules) {
        $matches = @($ChangedFiles | Where-Object { $_ -match $rule['Regex'] })
        if ($matches.Count -eq 0) {
            continue
        }

        $matchedAny = $true
        Write-ReviewLine "- $($rule['Name']): $($rule['Hint'])"
        foreach ($match in ($matches | Select-Object -First 8)) {
            Write-ReviewLine "  - $match"
        }
        if ($matches.Count -gt 8) {
            Write-ReviewLine "  - ...and $($matches.Count - 8) more"
        }
    }

    if (-not $matchedAny) {
        Write-ReviewLine 'Changed files do not match a high-risk review bucket.'
    }

    $runtimeChanges = @(
        $ChangedFiles |
            Where-Object {
                $_ -match '\.(lua|xml|toc)$' -and
                $_ -notmatch '^(old_version|reference|predecessor)/'
            }
    )
    $changelogChanged = $ChangedFiles -contains 'CHANGELOG.md' -or $ChangedFiles -contains 'Modules/Changelog.lua'
    if ($runtimeChanges.Count -gt 0 -and -not $changelogChanged) {
        Add-Warning 'Runtime files changed without CHANGELOG.md or Modules/Changelog.lua changes. Confirm the work is not user-visible.'
    }
}

$repoRootOutput = @(& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or $repoRootOutput.Count -eq 0) {
    throw 'This script must run inside the BetterFriendlist git repository.'
}

$repoRoot = ($repoRootOutput | Select-Object -First 1).Trim()
Set-Location -LiteralPath $repoRoot

Write-ReviewLine '# BetterFriendlist Review Check'
Write-ReviewLine "Repository: $repoRoot"
if (-not [string]::IsNullOrWhiteSpace($BaseRef)) {
    Write-ReviewLine "Base ref: $BaseRef"
}

Write-ReviewSection 'Git Status'
& git status --short --branch

Write-ReviewSection 'Changed File Risk Summary'
$changedFiles = @(Get-ReviewChangedFiles)
Write-RiskSummary $changedFiles

if (-not $SkipPackageCheck) {
    Write-ReviewSection 'Package Check'
    try {
        & (Join-Path $repoRoot 'tools/BFL-PackageCheck.ps1')
        if ($LASTEXITCODE -ne 0) {
            Add-Failure "BFL-PackageCheck.ps1 exited with code $LASTEXITCODE."
        }
    } catch {
        Add-Failure "BFL-PackageCheck.ps1 failed: $($_.Exception.Message)"
    }
}

Write-ReviewSection 'TOC References'
Test-TocReferences $repoRoot

Write-ReviewSection 'Locale Key Coverage'
Test-LocaleKeyCoverage -RepoRoot $repoRoot -ChangedFiles $changedFiles -BaseRef $BaseRef

Write-ReviewSection 'Static Lua Patterns'
Test-StaticLuaPatterns -RepoRoot $repoRoot -ChangedFiles $changedFiles

Write-ReviewSection 'Result'
Write-ReviewLine "Failures: $($script:Failures.Count)"
Write-ReviewLine "Warnings: $($script:Warnings.Count)"

if ($env:GITHUB_STEP_SUMMARY) {
    $script:SummaryLines | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding UTF8
}

if ($script:Failures.Count -gt 0) {
    exit 1
}

exit 0
