$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$flutter = "C:\Users\HP\develop\flutter\bin\flutter.bat"

if (-not (Test-Path $flutter)) {
    throw "Flutter was not found at $flutter"
}

Write-Host "e-market FINAL LOCAL QA" -ForegroundColor Cyan
Write-Host "Project: $projectRoot"
Write-Host ""

Write-Host "[1/5] Resolving cached dependencies..." -ForegroundColor Cyan
& $flutter --no-version-check pub get --offline
if ($LASTEXITCODE -ne 0) {
    throw "flutter pub get --offline failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "[2/5] Static analysis..." -ForegroundColor Cyan
& $flutter --no-version-check analyze
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "[3/5] Full test suite..." -ForegroundColor Cyan
& $flutter --no-version-check test
if ($LASTEXITCODE -ne 0) {
    throw "flutter test failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "[4/5] Android debug APK build..." -ForegroundColor Cyan
& $flutter --no-version-check build apk --debug --no-pub
if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk --debug failed with exit code $LASTEXITCODE"
}

$apk = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apk)) {
    throw "Build reported success but app-debug.apk was not found."
}

Write-Host ""
Write-Host "[5/5] Git whitespace check..." -ForegroundColor Cyan
git diff --check
if ($LASTEXITCODE -ne 0) {
    throw "git diff --check failed"
}

Write-Host ""
Write-Host "FINAL LOCAL QA PASSED." -ForegroundColor Green
Write-Host "APK: $apk" -ForegroundColor Green
