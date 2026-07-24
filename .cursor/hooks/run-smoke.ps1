$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$smoke = Join-Path $root "tests\smoke.ps1"
if (Test-Path $smoke) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $smoke
} else {
  Write-Host "smoke.ps1 not found — skip"
}
