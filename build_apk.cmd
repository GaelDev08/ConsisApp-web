@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
REM ==== ConsisApp APK build (CMD) ==================================
echo ============================================
echo   ConsisApp - Android APK build (Gradle8.13)
echo ============================================

REM ---- 0) Kill stray Java --------------------------------------------
echo [1/4] Killing stray java...
taskkill /F /IM java.exe 2>nul | findstr /V "" >nul

REM ---- 1) Choose a good JDK (JBR from Android Studio = MSVC) ----------
echo [2/4] Choosing JDK...
set "JDKBEST="
if exist "%PROGRAMFILES%\Android\Android Studio\jbr\bin\java.exe" set "JDKBEST=%PROGRAMFILES%\Android\Android Studio\jbr"
if not defined JDKBEST if exist "%LOCALAPPDATA%\Programs\Android Studio\jbr\bin\java.exe" set "JDKBEST=%LOCALAPPDATA%\Programs\Android Studio\jbr"
if defined JDKBEST (
    set "JAVA_HOME=%JDKBEST%"
    echo     Using JDK: !JAVA_HOME!
) else (
    echo     Using current JAVA_HOME: %JAVA_HOME%
)

REM ---- 2) Purge broken gnu native variant -----------------------------
echo [3/4] Purging broken Gradle native cache...
if exist "%USERPROFILE%\.gradle\native" rd /s /q "%USERPROFILE%\.gradle\native"
if exist "%USERPROFILE%\.gradle\daemon" rd /s /q "%USERPROFILE%\.gradle\daemon"
REM remove only the gradle-8.13 dist to force clean redownload
if exist "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.13-bin" rd /s /q "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.13-bin"

set JAVA_TOOL_OPTIONS=-Dorg.gradle.vfs.watch=false -Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=-Xmx4g
set GRADLE_OPTS=-Dorg.gradle.vfs.watch=false -Dorg.gradle.daemon=false

REM ---- 3) Build -------------------------------------------------------
echo [4/4] flutter build apk --release
cd /d "C:\Users\Gaeldev\Desktop\ConsisApp"
call flutter build apk --release
if errorlevel 1 (
    echo.
    echo BUILD FAILED. Last log:
    if exist build\app\outputs\flutter-apk\build_error.log type build\app\outputs\flutter-apk\build_error.log
    echo.
    echo If still mentions gradle-fileevents.dll, install:
    echo   https://aka.ms/vs/17/release/vc_redist.x64.exe  then RESTART
    echo and re-run this script.
    exit /b 1
)

echo.
echo SUCCESS!
for %%F in ("build\app\outputs\flutter-apk\app-release.apk") do echo   %%F
echo Install: adb install -r "build\app\outputs\flutter-apk\app-release.apk"
endlocal