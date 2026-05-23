$ErrorActionPreference = 'Stop'

Write-Host '[BFL] Git status'
& git status --short --branch

Write-Host ''
Write-Host '[BFL] Whitespace check'
& git diff --check

Write-Host ''
Write-Host '[BFL] Project pre-commit check'
python Utils/pre-commit-check.py 2>&1 |
    Select-String -Pattern '\[ERROR\]|\[OK\]|\[WARN\] WARN|All checks'
