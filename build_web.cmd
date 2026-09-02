@echo off
setlocal
chcp 65001 >nul
echo ============================================
echo   ConsisApp - Verifica APK + construye Web
echo ============================================

echo.
echo [1/2] APK status:
set "APK=build\app\outputs\flutter-apk\app-release.apk"
if exist "%APK%" (
    for %%F in ("%APK%") do echo     [OK] app-release.apk  (%%~zF bytes)
) else (
    echo     [MISSING] app-release.apk - build it once:
    echo       flutter build apk --release
)

echo.
echo [2/2] Building Web (for Vercel)...
call flutter build web --release
if errorlevel 1 (
    echo [FAIL] web build failed.
    pause
    exit /b 1
)

echo.
echo [OK] Web build ready at:
echo     build\web\
echo.
echo Deploy with Vercel (from this folder):
echo     vercel --prod
echo   (or import repo at vercel.com, Root Directory: build/web)
echo.
pause