# ============================================================
#  ConsisApp - Gradle native DLL fix + APK build
#  Run: powershell -ExecutionPolicy Bypass -File .\fix_and_build.ps1
# ============================================================
param([switch]$Debug)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=== ConsisApp: Gradle fix + APK build ===" -ForegroundColor Cyan
Write-Host ""

# ---- 1) Kill any stray java/gradle daemon ---------------------
Write-Host "[1/5] Killing stray java processes..." -ForegroundColor Cyan
Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# ---- 2) Clean native + daemon caches (broken DLL location) ----
Write-Host "[2/5] Cleaning Gradle caches..." -ForegroundColor Cyan
$paths = @(
    "$env:USERPROFILE\.gradle\native",
    "$env:USERPROFILE\.gradle\daemon",
    "$env:USERPROFILE\.gradle\wrapper\dists\gradle-9.1.0-all"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   Deleted: $p"
    }
}
# Also purge old daemon registry so a stale daemon never respawns
$reg = "$env:USERPROFILE\.gradle\daemon"
if (Test-Path $reg) { Remove-Item $reg -Recurse -Force -ErrorAction SilentlyContinue }

# ---- 3) Check VC++ runtime (main cause of ERROR_PROC_NOT_FOUND)
Write-Host "[3/5] Checking VC++ runtime..." -ForegroundColor Cyan
$vc = "$env:WINDIR\System32\vcruntime140.dll"
if (Test-Path $vc) {
    Write-Host "   vcruntime140.dll present - OK"
} else {
    Write-Host "   WARNING: vcruntime140.dll NOT installed."
    Write-Host "   Install the VC++ redistributable (x64):"
    Write-Host "     https://aka.ms/vs/17/release/vc_redist.x64.exe"
    Write-Host "     then rerun this script."
}

# ---- 4) Force disable daemon + file watching in project -------
Write-Host "[4/5] Ensuring android/gradle.properties flags..." -ForegroundColor Cyan
$gp = Join-Path $PSScriptRoot "android\gradle.properties"
if (Test-Path $gp) {
    $txt = [System.IO.File]::ReadAllText($gp)
    if ($txt -notmatch "org\.gradle\.vfs\.watch\s*=\s*false") {
        [System.IO.File]::WriteAllText($gp, $txt + "`r`norg.gradle.vfs.watch=false`r`n")
        Write-Host "   Added org.gradle.vfs.watch=false"
    } else {
        Write-Host "   Flags already present"
    }
}

# ---- 5) Build --------------------------------------------------
Write-Host "[5/5] Building APK (no-daemon, vfs off)..." -ForegroundColor Cyan
Set-Location $PSScriptRoot
$env:GRADLE_OPTS = "-Dorg.gradle.vfs.watch=false -Dorg.gradle.daemon=false"
$env:JAVA_TOOL_OPTIONS = "-Dorg.gradle.vfs.watch=false"
$log = Join-Path $PSScriptRoot "build_log.txt"

# Force enable in project (idempotent)
$props = Join-Path $PSScriptRoot "android\gradle.properties"
$txt = [System.IO.File]::ReadAllText($props)
if ($txt -notmatch "org\.gradle\.daemon") { [System.IO.File]::WriteAllText($props, $txt + "`r`norg.gradle.daemon=false`r`n") }
if ($txt -notmatch "org\.gradle\.vfs\.watch") { [System.IO.File]::WriteAllText($props, $txt + "`r`norg.gradle.vfs.watch=false`r`n") }

Write-Host "   Full build log -> $log"
if ($Debug) { flutter build apk --debug 2>&1 | Tee-Object -FilePath $log }
else        { flutter build apk --release 2>&1 | Tee-Object -FilePath $log }

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "BUILD FAILED." -ForegroundColor Red
    Write-Host "--- LAST 40 LINES OF build_log.txt ---" -ForegroundColor Yellow
    Get-Content $log -Tail 40 | ForEach-Object { Write-Host $_ }
    Write-Host "---------------------------------------" -ForegroundColor Yellow
    Write-Host "Paste the tail above if you need help." -ForegroundColor Cyan
    exit 1
}

# ---- Result -----------------------------------------------------
$apk = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    $mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ""
    Write-Host "SUCCESS: $apk ($mb MB)" -ForegroundColor Green
    Write-Host "Install: adb install -r `"$apk`""
} else {
    Write-Host "Build ended but APK not found. Check build\app\outputs\flutter-apk\" -ForegroundColor Yellow
}