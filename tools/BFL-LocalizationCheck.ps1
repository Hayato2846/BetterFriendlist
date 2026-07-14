param(
    [ValidateSet('Changed', 'Full')]
    [string]$Mode = 'Full',

    [string]$BaseRef,
    [string]$RepoRoot,
    [string]$AllowlistPath,

    [ValidateRange(1, 10000)]
    [int]$MaxReportedFailures = 200
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedLocales = @('enUS', 'deDE', 'esES', 'esMX', 'frFR', 'itIT', 'ptBR', 'ruRU', 'koKR', 'zhCN', 'zhTW')
$translatedLocales = @($expectedLocales | Where-Object { $_ -ne 'enUS' })
$failures = [System.Collections.Generic.List[string]]::new()

function Add-LocalizationFailure {
    param([Parameter(Mandatory = $true)][string]$Message)
    $failures.Add($Message)
}

function Resolve-BFLRepositoryRoot {
    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return [System.IO.Path]::GetFullPath($RepoRoot)
    }

    $rootOutput = @(& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or $rootOutput.Count -eq 0) {
        throw 'This script must run inside the BetterFriendlist git repository, or -RepoRoot must be provided.'
    }
    return [System.IO.Path]::GetFullPath(($rootOutput | Select-Object -First 1).Trim())
}

function Read-StrictUtf8File {
    param([Parameter(Mandatory = $true)][string]$Path)

    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    return [System.IO.File]::ReadAllText($Path, $encoding)
}

function Skip-LuaTrivia {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][ref]$Index
    )

    while ($Index.Value -lt $Content.Length) {
        $character = $Content[$Index.Value]
        if ([char]::IsWhiteSpace($character)) {
            $Index.Value++
            continue
        }

        if ($Index.Value + 1 -lt $Content.Length -and $Content.Substring($Index.Value, 2) -eq '--') {
            $Index.Value += 2
            while ($Index.Value -lt $Content.Length -and $Content[$Index.Value] -notin @("`r", "`n")) {
                $Index.Value++
            }
            continue
        }

        break
    }
}

function Read-LuaStaticStringExpression {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][int]$StartIndex,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$SourceLabel
    )

    $index = $StartIndex
    $value = [System.Text.StringBuilder]::new()
    $pieceCount = 0

    while ($true) {
        Skip-LuaTrivia -Content $Content -Index ([ref]$index)
        if ($index -ge $Content.Length -or ($Content[$index] -ne '"' -and $Content[$index] -ne "'")) {
            throw "$SourceLabel key $Key must use a static quoted Lua string expression."
        }

        $quote = $Content[$index]
        $index++
        $closed = $false
        while ($index -lt $Content.Length) {
            $character = $Content[$index]
            if ($character -eq '\') {
                if ($index + 1 -ge $Content.Length) {
                    throw "$SourceLabel key $Key ends with an incomplete Lua escape."
                }
                [void]$value.Append($character)
                [void]$value.Append($Content[$index + 1])
                $index += 2
                continue
            }
            if ($character -eq $quote) {
                $closed = $true
                $index++
                break
            }
            if ($character -in @("`r", "`n")) {
                throw "$SourceLabel key $Key contains a physical newline inside a quoted Lua string."
            }
            [void]$value.Append($character)
            $index++
        }

        if (-not $closed) {
            throw "$SourceLabel key $Key has an unterminated Lua string."
        }

        $pieceCount++
        Skip-LuaTrivia -Content $Content -Index ([ref]$index)
        if ($index + 1 -lt $Content.Length -and $Content.Substring($index, 2) -eq '..') {
            $index += 2
            continue
        }
        break
    }

    return [PSCustomObject]@{
        Value = $value.ToString()
        Pieces = $pieceCount
    }
}

function ConvertFrom-BFLLocaleContent {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$SourceLabel
    )

    $values = @{}
    $counts = @{}
    $assignmentPattern = [regex]'(?m)^\s*L\.([A-Z0-9_]+)\s*=\s*'
    foreach ($match in $assignmentPattern.Matches($Content)) {
        $key = $match.Groups[1].Value
        if (-not $counts.ContainsKey($key)) {
            $counts[$key] = 0
        }
        $counts[$key]++

        try {
            $parsed = Read-LuaStaticStringExpression -Content $Content -StartIndex ($match.Index + $match.Length) -Key $key -SourceLabel $SourceLabel
            $values[$key] = $parsed.Value
        } catch {
            Add-LocalizationFailure $_.Exception.Message
        }
    }

    return [PSCustomObject]@{
        Values = $values
        Counts = $counts
    }
}

function Get-CurrentLocaleCatalog {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Locale
    )

    $path = Join-Path $Root "Locales/$Locale.lua"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-LocalizationFailure "Missing locale file: Locales/$Locale.lua"
        return [PSCustomObject]@{ Values = @{}; Counts = @{} }
    }

    try {
        $content = Read-StrictUtf8File $path
    } catch {
        Add-LocalizationFailure "Locales/$Locale.lua is not valid UTF-8: $($_.Exception.Message)"
        return [PSCustomObject]@{ Values = @{}; Counts = @{} }
    }

    return ConvertFrom-BFLLocaleContent -Content $content -SourceLabel "Locales/$Locale.lua"
}

function Get-RefLocaleCatalog {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$Locale
    )

    $content = @(& git -C $Root show "${Ref}:Locales/$Locale.lua" 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return [PSCustomObject]@{ Values = @{}; Counts = @{} }
    }
    return ConvertFrom-BFLLocaleContent -Content ($content -join "`n") -SourceLabel "$Ref`:Locales/$Locale.lua"
}

function Get-ChangedCatalogKeys {
    param(
        [Parameter(Mandatory = $true)]$Before,
        [Parameter(Mandatory = $true)]$After
    )

    $keys = @($Before.Values.Keys) + @($After.Values.Keys) | Sort-Object -Unique
    return @(
        foreach ($key in $keys) {
            $beforeExists = $Before.Values.ContainsKey($key)
            $afterExists = $After.Values.ContainsKey($key)
            if ($beforeExists -ne $afterExists -or ($beforeExists -and $Before.Values[$key] -cne $After.Values[$key])) {
                $key
            }
        }
    )
}

function Get-LocalizationAllowlist {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$EnglishCatalog
    )

    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-LocalizationFailure "Localization allowlist is missing: $Path"
        return $map
    }

    try {
        $document = Read-StrictUtf8File $Path | ConvertFrom-Json
    } catch {
        Add-LocalizationFailure "Localization allowlist is invalid: $($_.Exception.Message)"
        return $map
    }

    if ($document.schemaVersion -ne 1) {
        Add-LocalizationFailure "Localization allowlist schemaVersion must be 1."
    }

    foreach ($entry in @($document.entries)) {
        $locale = [string]$entry.locale
        $key = [string]$entry.key
        $reason = [string]$entry.reason
        if ($locale -ne '*' -and $translatedLocales -notcontains $locale) {
            Add-LocalizationFailure "Allowlist entry $locale/$key has an unknown target locale."
            continue
        }
        if ([string]::IsNullOrWhiteSpace($key) -or -not $EnglishCatalog.Values.ContainsKey($key)) {
            Add-LocalizationFailure "Allowlist entry $locale/$key references an unknown enUS key."
            continue
        }
        if ([string]::IsNullOrWhiteSpace($reason)) {
            Add-LocalizationFailure "Allowlist entry $locale/$key must include a reason."
            continue
        }
        foreach ($check in @($entry.checks)) {
            if ($check -notin @('source-identical', 'english-language', 'source-change-no-target-change')) {
                Add-LocalizationFailure "Allowlist entry $locale/$key contains unknown check '$check'."
                continue
            }
            $map["$locale|$key|$check"] = $reason
        }
    }

    foreach ($entry in @($document.values)) {
        $value = [string]$entry.value
        $reason = [string]$entry.reason
        if ([string]::IsNullOrWhiteSpace($value)) {
            Add-LocalizationFailure 'Value allowlist entries must include a non-empty exact value.'
            continue
        }
        if ([string]::IsNullOrWhiteSpace($reason)) {
            Add-LocalizationFailure "Value allowlist entry '$value' must include a reason."
            continue
        }

        $encodedValue = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
        foreach ($locale in @($entry.locales)) {
            if ($locale -ne '*' -and $translatedLocales -notcontains $locale) {
                Add-LocalizationFailure "Value allowlist entry '$value' has an unknown target locale '$locale'."
                continue
            }
            foreach ($check in @($entry.checks)) {
                if ($check -notin @('source-identical', 'english-language')) {
                    Add-LocalizationFailure "Value allowlist entry '$value' contains unsupported check '$check'."
                    continue
                }
                $map["VALUE|$locale|$check|$encodedValue"] = $reason
            }
        }
    }

    foreach ($set in @($document.valueSets)) {
        $reason = [string]$set.reason
        if ([string]::IsNullOrWhiteSpace($reason)) {
            Add-LocalizationFailure 'Value allowlist sets must include a reason.'
            continue
        }
        foreach ($locale in @($set.locales)) {
            if ($locale -ne '*' -and $translatedLocales -notcontains $locale) {
                Add-LocalizationFailure "Value allowlist set has an unknown target locale '$locale'."
                continue
            }
            foreach ($value in @($set.values)) {
                $value = [string]$value
                if ([string]::IsNullOrWhiteSpace($value)) {
                    Add-LocalizationFailure "Value allowlist set for '$locale' contains an empty value."
                    continue
                }
                $encodedValue = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
                foreach ($check in @($set.checks)) {
                    if ($check -notin @('source-identical', 'english-language')) {
                        Add-LocalizationFailure "Value allowlist set for '$locale' contains unsupported check '$check'."
                        continue
                    }
                    $map["VALUE|$locale|$check|$encodedValue"] = $reason
                }
            }
        }
    }

    return $map
}

function Test-LocalizationException {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Allowlist,
        [Parameter(Mandatory = $true)][string]$Locale,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Check,
        [AllowEmptyString()][string]$Value = ''
    )

    if ($Allowlist.ContainsKey("$Locale|$Key|$Check") -or $Allowlist.ContainsKey("*|$Key|$Check")) {
        return $true
    }
    if (-not [string]::IsNullOrEmpty($Value)) {
        $encodedValue = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Value))
        return $Allowlist.ContainsKey("VALUE|$Locale|$Check|$encodedValue") -or
            $Allowlist.ContainsKey("VALUE|*|$Check|$encodedValue")
    }
    return $false
}

function Test-ContainsTranslatableText {
    param([Parameter(Mandatory = $true)][string]$Value)

    $scrubbed = $Value
    $scrubbed = [regex]::Replace($scrubbed, '\|[cC][0-9A-Fa-f]{8}|\|r|\|T[^|]*\|t|\|A[^|]*\|a|\|H[^|]*\|h|\|h', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouqsxX]', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '\\[nrt]', ' ')
    $protectedTerms = @(
        'Mists of Pandaria', 'The War Within', 'World of Warcraft', 'LibSettingsDesigner',
        'BetterFriendList', 'BetterFriendlist', 'Battle\.net', 'BattleTag', 'FriendGroups',
        'Data Broker', 'Diablo IV', 'Hearthstone', 'StarCraft', 'Midnight', 'Blizzard',
        'Discord', 'ElvUI', 'Ko-fi', 'AddOns?', 'Retail', 'Classic', 'Broker', 'WoW',
        'BNet', 'BFL', 'WIM', 'AFK', 'DND', 'DPS', 'PvP', 'AP', 'iLvl', 'FPS',
        'ASC', 'DESC', 'MOTD', 'Ctrl', 'Shift', 'Alt', 'ms', 'px', 'min'
    )
    foreach ($term in $protectedTerms) {
        $scrubbed = [regex]::Replace(
            $scrubbed,
            "(?<![\p{L}\p{N}])(?:$term)(?![\p{L}\p{N}])",
            ' ',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    return [regex]::IsMatch($scrubbed, '\p{L}')
}

function Get-PrintfTokens {
    param([Parameter(Mandatory = $true)][string]$Value)

    $withoutEscapedPercent = $Value -replace '%%', ''
    return @(
        [regex]::Matches($withoutEscapedPercent, '%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouqsxX]') |
            ForEach-Object { $_.Value }
    )
}

function Get-WowMarkupTokens {
    param([Parameter(Mandatory = $true)][string]$Value)

    $patterns = @(
        '\|c[0-9A-Fa-f]{8}',
        '\|r',
        '\|T[^|]*\|t',
        '\|A[^|]*\|a',
        '\|H[^|]*\|h',
        '\|h'
    )
    $tokens = @()
    foreach ($pattern in $patterns) {
        $tokens += @([regex]::Matches($Value, $pattern) | ForEach-Object { $_.Value })
    }
    return @($tokens | Sort-Object)
}

function Test-TokenParity {
    param(
        [Parameter(Mandatory = $true)][string]$Locale,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$EnglishValue,
        [Parameter(Mandatory = $true)][string]$TranslatedValue
    )

    $englishPrintf = @(Get-PrintfTokens $EnglishValue)
    $translatedPrintf = @(Get-PrintfTokens $TranslatedValue)
    if (($englishPrintf -join '|') -cne ($translatedPrintf -join '|')) {
        Add-LocalizationFailure "$Locale/$Key changes printf placeholders: enUS=[$($englishPrintf -join ', ')] target=[$($translatedPrintf -join ', ')]."
    }

    $englishMarkup = @(Get-WowMarkupTokens $EnglishValue)
    $translatedMarkup = @(Get-WowMarkupTokens $TranslatedValue)
    if (($englishMarkup -join '|') -cne ($translatedMarkup -join '|')) {
        Add-LocalizationFailure "$Locale/$Key changes WoW markup tokens: enUS=[$($englishMarkup -join ', ')] target=[$($translatedMarkup -join ', ')]."
    }

    $englishNewlines = [regex]::Matches($EnglishValue, '\\n').Count
    $translatedNewlines = [regex]::Matches($TranslatedValue, '\\n').Count
    if (($englishNewlines -ge 2 -and $translatedNewlines -eq 0) -or ($englishNewlines -eq 0 -and $translatedNewlines -ge 2)) {
        Add-LocalizationFailure "$Locale/$Key changes multiline structure: enUS newlines=$englishNewlines target newlines=$translatedNewlines."
    }
}

function Test-LooksEnglish {
    param([Parameter(Mandatory = $true)][string]$Value)

    $scrubbed = $Value
    $scrubbed = [regex]::Replace($scrubbed, '\|[cC][0-9A-Fa-f]{8}|\|r|\|T[^|]*\|t|\|A[^|]*\|a|\|H[^|]*\|h|\|h', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '%(?:\d+\$)?[-+ #0]*\d*(?:\.\d+)?[cdeEfgGiouqsxX]', ' ')
    $scrubbed = [regex]::Replace($scrubbed, '\b(?:BetterFriendlist|BetterFriendList|Battle\.net|FriendGroups|LibSettingsDesigner|Discord|ElvUI|WoW|BFL)\b', ' ', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $words = @([regex]::Matches($scrubbed.ToLowerInvariant(), "[a-z]+(?:'[a-z]+)?") | ForEach-Object { $_.Value })
    if ($words.Count -eq 0) {
        return $false
    }

    $strongEnglishWords = @(
        'and', 'are', 'available', 'cannot', 'click', 'created', 'currently', 'disable', 'enable',
        'failed', 'for', 'friend', 'friends', 'from', 'group', 'groups', 'guild', 'hide', 'into',
        'invite', 'is', 'left', 'message', 'migration', 'more', 'others', 'please', 'ready', 'right',
        'search', 'selected', 'settings', 'show', 'successfully', 'that', 'the', 'these', 'this', 'those',
        'to', 'use', 'using', 'verifying', 'when', 'while', 'will', 'with', 'without', 'you', 'your'
    )
    $strongCount = @($words | Where-Object { $strongEnglishWords -contains $_ }).Count
    return $strongCount -ge 2
}

$root = Resolve-BFLRepositoryRoot
Set-Location -LiteralPath $root

if ([string]::IsNullOrWhiteSpace($AllowlistPath)) {
    $AllowlistPath = Join-Path $root 'tools/BFL-LocalizationAllowlist.json'
} elseif (-not [System.IO.Path]::IsPathRooted($AllowlistPath)) {
    $AllowlistPath = Join-Path $root $AllowlistPath
}

if ($Mode -eq 'Changed' -and [string]::IsNullOrWhiteSpace($BaseRef)) {
    $BaseRef = 'HEAD'
}
if ($Mode -eq 'Changed') {
    & git -C $root rev-parse --verify "$BaseRef^{commit}" 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Localization base ref is not a commit: $BaseRef"
    }
}

Write-Host '# BetterFriendlist Localization Check'
Write-Host "Repository: $root"
Write-Host "Mode: $Mode"
if ($Mode -eq 'Changed') {
    Write-Host "Base ref: $BaseRef"
}

$currentCatalogs = @{}
foreach ($locale in $expectedLocales) {
    $currentCatalogs[$locale] = Get-CurrentLocaleCatalog -Root $root -Locale $locale
}

$englishCatalog = $currentCatalogs['enUS']
$allowlist = Get-LocalizationAllowlist -Path $AllowlistPath -EnglishCatalog $englishCatalog
$keysToCheckByLocale = @{}
$baseCatalogs = @{}

if ($Mode -eq 'Full') {
    $englishKeys = @($englishCatalog.Values.Keys | Sort-Object)
    foreach ($locale in $translatedLocales) {
        $targetKeys = @($currentCatalogs[$locale].Values.Keys | Sort-Object)
        foreach ($missingKey in @($englishKeys | Where-Object { $targetKeys -notcontains $_ })) {
            Add-LocalizationFailure "$locale is missing enUS key $missingKey."
        }
        foreach ($extraKey in @($targetKeys | Where-Object { $englishKeys -notcontains $_ })) {
            Add-LocalizationFailure "$locale contains key $extraKey that is not present in enUS."
        }
        $keysToCheckByLocale[$locale] = $englishKeys
    }
} else {
    foreach ($locale in $expectedLocales) {
        $baseCatalogs[$locale] = Get-RefLocaleCatalog -Root $root -Ref $BaseRef -Locale $locale
    }

    $changedEnglishKeys = @(Get-ChangedCatalogKeys -Before $baseCatalogs['enUS'] -After $englishCatalog)
    Write-Host "Changed enUS keys: $($changedEnglishKeys.Count)"

    foreach ($locale in $translatedLocales) {
        $targetCatalog = $currentCatalogs[$locale]
        $baseTargetCatalog = $baseCatalogs[$locale]
        $changedTargetKeys = @(Get-ChangedCatalogKeys -Before $baseTargetCatalog -After $targetCatalog)
        $keysToCheckByLocale[$locale] = @($changedEnglishKeys + $changedTargetKeys | Sort-Object -Unique)

        foreach ($key in $changedEnglishKeys) {
            $englishExists = $englishCatalog.Values.ContainsKey($key)
            $targetExists = $targetCatalog.Values.ContainsKey($key)
            if ($englishExists -and -not $targetExists) {
                Add-LocalizationFailure "$locale is missing changed enUS key $key."
                continue
            }
            if (-not $englishExists -and $targetExists) {
                Add-LocalizationFailure "$locale still contains deleted enUS key $key."
                continue
            }
            if (-not $englishExists) {
                continue
            }

            $targetChanged = $changedTargetKeys -contains $key
            if (-not $targetChanged -and -not (Test-LocalizationException -Allowlist $allowlist -Locale $locale -Key $key -Check 'source-change-no-target-change')) {
                Add-LocalizationFailure "$locale/$key was not reviewed after its enUS source changed. Translate it in the same change."
            }
        }

        foreach ($key in $keysToCheckByLocale[$locale]) {
            $currentCount = if ($targetCatalog.Counts.ContainsKey($key)) { [int]$targetCatalog.Counts[$key] } else { 0 }
            $baseCount = if ($baseTargetCatalog.Counts.ContainsKey($key)) { [int]$baseTargetCatalog.Counts[$key] } else { 0 }
            if ($currentCount -gt 1 -and $currentCount -gt $baseCount) {
                Add-LocalizationFailure "$locale/$key introduces or increases duplicate assignments ($baseCount -> $currentCount)."
            }
        }
    }
}

foreach ($locale in $translatedLocales) {
    $targetCatalog = $currentCatalogs[$locale]
    foreach ($key in @($keysToCheckByLocale[$locale])) {
        if (-not $englishCatalog.Values.ContainsKey($key) -or -not $targetCatalog.Values.ContainsKey($key)) {
            continue
        }

        $englishValue = [string]$englishCatalog.Values[$key]
        $translatedValue = [string]$targetCatalog.Values[$key]
        if ([string]::IsNullOrWhiteSpace($translatedValue)) {
            Add-LocalizationFailure "$locale/$key has an empty translation."
            continue
        }
        if ($translatedValue -ceq $key) {
            Add-LocalizationFailure "$locale/$key uses the key name as its translation."
        }
        if ($translatedValue -ceq $englishValue -and
            (Test-ContainsTranslatableText $translatedValue) -and
            -not (Test-LocalizationException -Allowlist $allowlist -Locale $locale -Key $key -Check 'source-identical' -Value $translatedValue)) {
            Add-LocalizationFailure "$locale/$key is identical to the enUS source: '$translatedValue'"
        }
        if ((Test-LooksEnglish $translatedValue) -and -not (Test-LocalizationException -Allowlist $allowlist -Locale $locale -Key $key -Check 'english-language' -Value $translatedValue)) {
            Add-LocalizationFailure "$locale/$key appears to contain an English fallback: '$translatedValue'"
        }

        Test-TokenParity -Locale $locale -Key $key -EnglishValue $englishValue -TranslatedValue $translatedValue
    }
}

Write-Host "Checked locales: $($expectedLocales.Count)"
Write-Host "Allowlist exceptions: $($allowlist.Count)"
Write-Host "Failures: $($failures.Count)"

if ($failures.Count -gt 0) {
    $failureCategories = [ordered]@{
        'Duplicate assignments' = @($failures | Where-Object { $_ -match ' is assigned \d+ times|duplicate assignments' }).Count
        'Missing or extra keys' = @($failures | Where-Object { $_ -match ' is missing enUS key | contains key .* not present|missing changed enUS key|still contains deleted enUS key' }).Count
        'Stale translations' = @($failures | Where-Object { $_ -match ' was not reviewed after its enUS source changed' }).Count
        'Source-identical values' = @($failures | Where-Object { $_ -match ' is identical to the enUS source' }).Count
        'English leakage' = @($failures | Where-Object { $_ -match ' appears to contain an English fallback' }).Count
        'Placeholder or markup errors' = @($failures | Where-Object { $_ -match ' changes printf placeholders| changes WoW markup| changes multiline structure' }).Count
        'Other contract errors' = 0
    }
    $categorizedCount = 0
    foreach ($category in @($failureCategories.Keys | Where-Object { $_ -ne 'Other contract errors' })) {
        $categorizedCount += [int]$failureCategories[$category]
    }
    $failureCategories['Other contract errors'] = [Math]::Max(0, $failures.Count - $categorizedCount)
    foreach ($category in $failureCategories.Keys) {
        if ($failureCategories[$category] -gt 0) {
            Write-Host ("- {0}: {1}" -f $category, $failureCategories[$category])
        }
    }

    $limit = $MaxReportedFailures
    foreach ($failure in @($failures | Select-Object -First $limit)) {
        Write-Host "[FAIL] $failure" -ForegroundColor Red
    }
    if ($failures.Count -gt $limit) {
        Write-Host "[FAIL] Output limited to $limit of $($failures.Count) failures." -ForegroundColor Red
    }
    exit 1
}

Write-Host '[OK] Localization contract passed.' -ForegroundColor Green
exit 0
