# ========================================
# Create Desktop Shortcut for Seasonal Quest App
# ========================================

Write-Host "Creating Desktop Shortcut for Seasonal Quest App..." -ForegroundColor Cyan

# Get paths
$desktopPath = [Environment]::GetFolderPath("Desktop")
$scriptPath = Join-Path $PSScriptRoot "START_APP.bat"
$shortcutPath = Join-Path $desktopPath "Seasonal Quest App.lnk"
$iconPath = Join-Path $PSScriptRoot "seasonal_quest_app.ico"

# Create shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $scriptPath
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Seasonal Quest Explorer - Avvia server e app Flutter Web"
$Shortcut.WindowStyle = 1

# Set custom icon if available
if (Test-Path $iconPath) {
    $Shortcut.IconLocation = $iconPath
    Write-Host "Using custom icon: seasonal_quest_app.ico" -ForegroundColor Green
} else {
    Write-Host "Custom icon not found. Run CREATE_ICON.ps1 to create one." -ForegroundColor Yellow
}

$Shortcut.Save()

Write-Host ""
Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
Write-Host "Location: $shortcutPath" -ForegroundColor White
Write-Host ""
Write-Host "Double-click the shortcut on your desktop to:" -ForegroundColor Cyan
Write-Host "  1. Start the Image Server (Node.js)" -ForegroundColor White
Write-Host "  2. Launch Flutter Web App" -ForegroundColor White
Write-Host "  3. Open in Chrome browser" -ForegroundColor White
Write-Host ""

# Release COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
