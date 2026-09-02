# ============================================================
#  ConsisApp - BUILD ALL (Web + APK)  [PowerShell]
#  Run this in a NORMAL Powershell window (not VS Code terminal):
#    Right-click Start -> "Windows PowerShell" (or open Terminal)
#    cd C:\Users\Gaeldev\Desktop\ConsisApp
#    powershell -ExecutionPolicy Bypass -File .\build_all.ps1
# ============================================================
param([switch]$SkipApk)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ConsisApp - Build Web + APK" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- 0) Kill stray java (avoid corrupt daemon) -------
taskkill /F /IM java.exe 2>$null | Out-Null

# --- 1) Verify flutter on PATH -----------------------
Write-Host "[1/5] Checking flutter..."
where.exe flutter *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: 'flutter' not found in PATH." -ForegroundColor Red
    Write-Host "  Flutter must be in PATH. See note at bottom." -ForegroundColor Yellow
    exit 1
}

# --- 2) Get dependencies -----------------------------
Write-Host "[2/5] flutter pub get..."
flutter pub get

# --- 3) Build WEB (for Vercel) -----------------------
Write-Host "[3/5] Building web (flutter build web --release)..."
flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Host "  WEB build FAILED (see above)." -ForegroundColor Red }
else { Write-Host "  Web OK -> build\web\ " -ForegroundColor Green }

# --- 4) Build APK ------------------------------------
if ($SkipApk) {
    Write-Host "[4/5] Skipping APK (requested)."
} else {
    Write-Host "[4/5] Building APK (this takes minutes)..."
    # Lower Gradle JVM heap to reduce system RAM pressure during AOT.
    $env:GRADLE_OPTS = "-Xmx2g"
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  APK FAILED. If it says gradle-fileevents.dll," -ForegroundColor Red
        Write-Host "  do these TWO things then re-run:" -ForegroundColor Red
        Write-Host "    1) Install: https://aka.ms/vs/17/release/vc_redist.x64.exe  (+ RESTART)" -ForegroundColor Yellow
        Write-Host "    2) Remove cache:  Remove-Item \"$env:USERPROFILE\.gradle\native\" -Recurse -Force" -ForegroundColor Yellow
    } else {
        Write-Host "  APK OK! -> build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
}

# --- 5) Summary ----------------------------------------
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RESULTADO" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
if (Test-Path "$root\build\web") {
    Write-Host "  [OK] WEB  : $root\build\web\" -ForegroundColor Green
    Write-Host "         Deploy a Vercel desde esa carpeta (ver DEPLOY.md)" -ForegroundColor Green
} else {
    Write-Host "  [--] Web build no produjo build\web" -ForegroundColor Yellow
}
$apk = "$root\build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    $mb = [math]::Round((Get-Item $apk).Length/1MB, 1)
    Write-Host "  [OK] APK  : $apk  ($mb MB)" -ForegroundColor Green
    Write-Host "         Install: adb install -r `"$apk`"" -ForegroundColor Green
} else {
    Write-Host "  [--] APK aun no existe." -ForegroundColor Yellow
}
Write-Host ""