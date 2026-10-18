param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repositoryRoot
try {
    foreach ($edition in @('Public', 'Unstable')) {
        & $Python 'rites-preview/test_tribal_ceremony.py' --edition $edition
        if ($LASTEXITCODE -ne 0) { throw "Runtime tests failed: $edition" }
    }
    & $Python 'tools/package.py'
    if ($LASTEXITCODE -ne 0) { throw 'Package validation failed.' }
} finally {
    Pop-Location
}
