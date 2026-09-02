# ============================================================
#  ConsisApp - Android APK build helper (Windows PowerShell)
#  Usage:
#    powershell -ExecutionPolicy Bypass -File .\build_apk.ps1
#  Optional switches: -SplitAbi   -Debug
# ============================================================
param(
    [switch]$SplitAbi,
    [switch]$Debug
)

$ErrorActionPreference = "Stop"

function Step($n, $msg) { Write-Host "[$n/5] $msg" -ForegroundColor Cyan }

# ---- 0) Verificar toolchain -----------------------------------------------
Step 0 "Checking Flutter SDK..."
where.exe flutter *> $null
if ($LASTEXITCODE -ne 0) { throw "Flutter SDK not found in PATH." }

Set-Location -Path $PSScriptRoot

# ---- 1) Generate android platform if missing (idempotent) -------------------
if (-not (Test-Path "android")) {
    Step 1 "Generating android/ folder (flutter create)..."
    flutter create --platforms=android --org com.consisapp .
    if ($LASTEXITCODE -ne 0) { throw "flutter create failed." }
} else {
    Step 1 "android/ already exists - skipped."
}

# ---- 2) minSdk = 24 (requisito de local_auth) -----------------------------
Step 2 "Aplicando minSdk 24..."
Get-ChildItem "android\app" -Filter "build.gradle*" | ForEach-Object {
    $path = $_.FullName
    $content = [System.IO.File]::ReadAllText($path)
    $updated = $false

    # Kotlin DSL:  minSdk = flutter.minSdkVersion
    if ($content -match "minSdk\s*=\s*flutter\.minSdkVersion") {
        $content = $content -replace "minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24"
        $updated = $true
    }
    # Groovy:      minSdkVersion flutter.minSdkVersion
    if ($content -match "minSdkVersion\s+flutter\.minSdkVersion") {
        $content = $content -replace "minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24"
        $updated = $true
    }
    # Groovy legacy numeric below 24 (21/22/23)
    if ($content -match "minSdkVersion\s+(1\d|2[0-3])\b") {
        $content = $content -replace "minSdkVersion\s+\d+", "minSdkVersion 24"
        $updated = $true
    }

    if ($updated) {
        [System.IO.File]::WriteAllText($path, $content)   # UTF-8 no BOM
        Write-Host "     minSdk=24 aplicado en $($_.Name)"
    }
}

# ---- 3) Biometric permission -------------------------------------------------
Step 3 "Ensuring USE_BIOMETRIC permission..."
$manifest = "android\app\src\main\AndroidManifest.xml"
$content = [System.IO.File]::ReadAllText((Join-Path $PWD $manifest))
if ($content -notmatch "USE_BIOMETRIC") {
    $permission = '    <uses-permission android:name="android.permission.USE_BIOMETRIC" />'
    $newline = "`r`n"
    $content = $content -replace '(<manifest[^>]*>)', ('$1' + $newline + $permission)
    [System.IO.File]::WriteAllText((Join-Path $PWD $manifest), $content)
    Write-Host "     USE_BIOMETRIC permission added."
} else {
    Write-Host "     Permission already present."
}

# ---- 4) Dependencias --------------------------------------------------------
Step 4 "flutter pub get..."
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "pub get failed." }

# ---- 5) Build ---------------------------------------------------------------
$mode = if ($Debug) { "debug" } else { "release" }
$extra = @()
if ($SplitAbi) { $extra += "--split-per-abi" }

Step 5 "Compilando APK ($mode)$(
    if ($SplitAbi) { ' [split-per-abi]' } else { '' }
)..."
if ($SplitAbi) {
    flutter build apk $mode --split-per-abi
} else {
    flutter build apk --$mode
}
if ($LASTEXITCODE -ne 0) { throw "Build failed. Check errors above." }

# ---- Resultado --------------------------------------------------------------
$outDir = "build\app\outputs\flutter-apk"
Write-Host ""
Write-Host "APK READY:" -ForegroundColor Green
Get-ChildItem $outDir -Filter "*.apk" | ForEach-Object {
    $mb = [math]::Round($_.Length / 1MB, 1)
    Write-Host ("  - {0}  ({1} MB)" -f $_.FullName, $mb) -ForegroundColor Green
}
Write-Host ""
Write-Host "Instalar en dispositivo conectado:"
Write-Host "   adb install -r `"$outDir\app-release.apk`""
