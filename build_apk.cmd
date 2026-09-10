@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
REM ==== ConsisApp APK build (CMD) ==================================
echo ============================================
echo   ConsisApp - Android APK build
echo ============================================

REM ---- 0) Kill stray Java --------------------------------------------
echo [1/6] Killing stray java...
taskkill /F /IM java.exe 2>nul | findstr /V "" >nul

REM ---- 1) Purge broken caches -----------------------------------------
echo [2/6] Purging caches...
if exist "%USERPROFILE%\.gradle\native" rd /s /q "%USERPROFILE%\.gradle\native"
if exist "%USERPROFILE%\.gradle\daemon" rd /s /q "%USERPROFILE%\.gradle\daemon"
if exist "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.14-bin" rd /s /q "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.14-bin"
if exist "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.13-bin" rd /s /q "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.13-bin"
if exist "%USERPROFILE%\.gradle\wrapper\dists\gradle-9.1.0-all" rd /s /q "%USERPROFILE%\.gradle\wrapper\dists\gradle-9.1.0-all"

REM ---- 2) Copy UCRT DLLs to native dir ------------------------------
echo [3/6] Setting up native libraries...
set "NATIVEDIR=%USERPROFILE%\.gradle\native\0.2.7\x86_64-windows-gnu"
if exist "%NATIVEDIR%" (
    xcopy "C:\Users\Gaeldev\.vscode\extensions\ms-dotnettools.csharp-2.140.9-win32-x64\.debugger\x86_64\api-ms-win-crt-*.*" "%NATIVEDIR%\" /Y /Q /H 2>nul
    xcopy "C:\Windows\System32\vcruntime140.dll" "%NATIVEDIR%\" /Y /Q 2>nul
    xcopy "C:\Windows\System32\vcruntime140_1.dll" "%NATIVEDIR%\" /Y /Q 2>nul
    xcopy "C:\Windows\System32\msvcp140.dll" "%NATIVEDIR%\" /Y /Q 2>nul
)

REM ---- 3) Set JVM options ---------------------------------------------
echo [4/6] Setting JVM options...
set JAVA_TOOL_OPTIONS=-Dorg.gradle.vfs.watch=false
set GRADLE_OPTS=-Dorg.gradle.daemon=false

REM ---- 4) Build -------------------------------------------------------
echo [5/6] Building APK...
cd /d "C:\Users\Gaeldev\Desktop\ConsisApp"
call flutter build apk --release --no-tree-shake-icons --no-obfuscate --android-skip-build-dependency-validation
if errorlevel 1 (
    echo.
    echo BUILD FAILED.
    echo If the error mentions gradle-fileevents.dll, install the VC++ Redistributable:
    echo   https://aka.ms/vs/17/release/vc_redist.x64.exe  then RESTART your PC.
    exit /b 1
)

echo.
echo SUCCESS!
for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do echo   %%F
echo Install: adb install -r "build\app\outputs\flutter-apk\app-release.apk"
endlocal