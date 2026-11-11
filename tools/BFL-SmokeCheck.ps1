[CmdletBinding()]
param(
    [ValidateSet('Portable', 'Full')]
    [string]$Mode = 'Portable',
    [string]$ReferenceRoot = $env:BFL_REFERENCES_ROOT,
    [string]$Lua = $(if ($env:BFL_LUA) { $env:BFL_LUA } else { 'lua' }),
    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 60,
    [string]$ReportPath = $env:BFL_SMOKE_REPORT,
    [string[]]$Test,
    [switch]$List
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runnerArgs = @(
    (Join-Path $PSScriptRoot 'bfl_smoke.py'), 'run',
    '--repo', (Split-Path -Parent $PSScriptRoot),
    '--mode', $Mode, '--lua', $Lua, '--timeout', $TimeoutSeconds
)
if ($ReferenceRoot) { $runnerArgs += @('--reference-root', $ReferenceRoot) }
if ($ReportPath) { $runnerArgs += @('--report', $ReportPath) }
foreach ($name in $Test) { $runnerArgs += @('--test', $name) }
if ($List) { $runnerArgs += '--list' }

& python @runnerArgs
exit $LASTEXITCODE
