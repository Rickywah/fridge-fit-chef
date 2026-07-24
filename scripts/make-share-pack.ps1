# Build dist/Fridge-Fit-Chef-share.zip (flat layout for WeChat sharing)
$ErrorActionPreference = "Stop"
$root = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent
$web = Join-Path $root "web"
$config = Join-Path $root "config"
$dist = Join-Path $root "dist"
$pack = Join-Path $dist "share-pack"
$zip = Join-Path $dist "Fridge-Fit-Chef-share.zip"

New-Item -ItemType Directory -Force -Path $pack | Out-Null
$html = Get-Content (Join-Path $web "fridge-fit-chef.html") -Raw -Encoding UTF8
$html = $html -replace '\.\./config/config\.js', 'config.js'
Set-Content -Path (Join-Path $pack "fridge-fit-chef.html") -Value $html -Encoding UTF8
Copy-Item (Join-Path $web "index.html") $pack -Force
Copy-Item (Join-Path $config "config.example.js") $pack -Force
if (Test-Path (Join-Path $config "config.js")) {
  Copy-Item (Join-Path $config "config.js") $pack -Force
} else {
  Copy-Item (Join-Path $config "config.example.js") (Join-Path $pack "config.js") -Force
}
Copy-Item (Join-Path $root "docs\SHARE-README.txt") $pack -Force -ErrorAction SilentlyContinue

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$pack\*" -DestinationPath $zip -Force

Write-Host "Created: $zip"
Write-Host "WeChat this zip to family."
