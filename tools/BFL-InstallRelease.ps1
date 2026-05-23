param(
    [Parameter(Mandatory = $true)][string]$Zip,

    [ValidateSet('retail', 'ptr', 'xptr', 'beta', 'classic', 'classic_ptr', 'classic_era', 'anniversary', 'all')]
    [string[]]$Client = @('retail'),

    [string]$Root,
    [string]$WowRoot,
    [switch]$Force
)

& "$PSScriptRoot\BFL-Deploy.ps1" -Mode Zip -Zip $Zip -Client $Client -Root $Root -WowRoot $WowRoot -Force:$Force
