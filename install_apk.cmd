@echo off
setlocal
chcp 65001 >nul
echo ============================================
echo   ConsisApp - APK check and install
echo ============================================

set "APK=build\app\outputs\flutter-apk\app-release.apk"

if exist "%APK%" (
    echo [OK] APK found:
    for %%F in ("%APK%") do echo      %%~fF  (%%~zF bytes)
    echo.
    adb version >nul 2>&1
    if errorlevel 1 (
        echo [WARN] adb not found in PATH.
        echo    - Connect phone with USB debugging, or
        echo    - Copy the APK to the device, or
        echo    - Run from Android Studio terminal.
    ) else (
        echo Installing...
        adb install -r "%APK%"
        if errorlevel 1 (
            echo [FAIL] install error. Is a device connected? Enable USB debugging.
        ) else (
            echo [OK] Installed successfully.
        )
    )
) else (
    echo [MISSING] APK not found. Build it first:
    echo   flutter build apk --release
)
pause