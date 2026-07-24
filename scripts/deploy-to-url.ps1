# Build dist/deploy.zip and open Netlify Drop
$ErrorActionPreference = "Stop"
$root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
& (Join-Path $root "scripts\make-share-pack.ps1") | Out-Null

$dist = Join-Path $root "dist"
$zip = Join-Path $dist "Fridge-Fit-Chef-share.zip"
$deployZip = Join-Path $dist "deploy.zip"
if (Test-Path $deployZip) { Remove-Item $deployZip -Force }
Copy-Item $zip $deployZip -Force

Write-Host ""
Write-Host "=== Fridge Fit Chef deploy ===" -ForegroundColor Green
Write-Host "1. Netlify Drop opens in browser"
Write-Host "2. Drag dist\deploy.zip into the page"
Write-Host ""
Write-Host "Zip: $deployZip"
Write-Host ""

Start-Process "https://app.netlify.com/drop"
Start-Process explorer.exe "/select,`"$deployZip`""
