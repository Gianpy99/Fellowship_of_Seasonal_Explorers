@echo off
setlocal enabledelayedexpansion

REM ========================================
REM SEASONAL QUEST APP - ULTRA FAST
REM ========================================

cd /d "%~dp0"

echo.
echo ========================================
echo SEASONAL QUEST APP - ULTRA FAST v2
echo ========================================
echo.

REM Check if server is already running
netstat -ano | findstr ":3000" >nul 2>nul
if %ERRORLEVEL% == 0 (
    echo [*] Image Server already running - REUSING (port 3000)
    echo [*] Server state persisted on disk
) else (
    echo [+] Starting Image Server (port 3000)...
    start "Seasonal Quest - Image Server" cmd /k "node image_server.js"
    timeout /t 2 /nobreak >nul
)

echo.
echo [+] Starting Flutter App (Release Mode - OPTIMIZED)...
echo [*] Compilation time: ~25s (normal for Flutter Web)
echo [*] Use 'r' for hot reload, 'd' to detach
echo.

REM Use release mode for faster subsequent builds + smaller app
"C:\Users\gianp\OneDrive\Documents\flutter\bin\flutter.bat" run -d chrome --release

echo.
echo ========================================
echo [✓] App closed
echo [*] Server still running at http://localhost:3000
echo [*] To restart app: press UP arrow + ENTER
echo ========================================

pause
