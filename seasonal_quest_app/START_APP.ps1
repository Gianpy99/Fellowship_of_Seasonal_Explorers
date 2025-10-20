# Seasonal Quest App - Auto Launcher
# Doppio-click non funziona con .ps1, ma puoi usare: powershell -ExecutionPolicy Bypass -File START_APP.ps1

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $AppDir

Write-Host ""
Write-Host "========================================"
Write-Host "SEASONAL QUEST APP - Auto Launcher"
Write-Host "========================================"
Write-Host ""

# Avvia il server Node.js in un nuovo processo
Write-Host "Starting Image Server (port 3000)..."
Start-Process -FilePath "node" -ArgumentList "image_server.js" -WindowStyle Normal -PassThru | Out-Null

# Aspetta che il server si avvii
Start-Sleep -Seconds 3

# Avvia Flutter
Write-Host ""
Write-Host "Starting Flutter App (port 5000)..."
Write-Host ""

& flutter run -d chrome
