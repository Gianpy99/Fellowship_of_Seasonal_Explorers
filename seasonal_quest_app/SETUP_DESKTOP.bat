@echo off
echo ========================================
echo SETUP SEASONAL QUEST APP
echo ========================================
echo.

echo [1/2] Creating custom icon...
powershell -ExecutionPolicy Bypass -File "%~dp0CREATE_ICON.ps1"

echo.
echo [2/2] Creating desktop shortcut...
powershell -ExecutionPolicy Bypass -File "%~dp0CREATE_DESKTOP_SHORTCUT.ps1"

echo.
echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo You can now find "Seasonal Quest App" on your desktop
echo with a custom icon.
echo.

pause
