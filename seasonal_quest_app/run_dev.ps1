#!/usr/bin/env pwsh

Write-Host "🚀 Starting Image Server and Flutter App..." -ForegroundColor Green

# Start Node server in background
Write-Host "📦 Starting image server on port 3000..." -ForegroundColor Cyan
$serverProcess = Start-Process -FilePath "node" -ArgumentList "image_server.js" -PassThru -NoNewWindow

# Wait for server to start
Start-Sleep -Seconds 2

# Start Flutter
Write-Host "🎯 Starting Flutter web app..." -ForegroundColor Cyan
flutter run -d chrome

# Cleanup: Kill server on exit
Write-Host "⏹️ Stopping image server..." -ForegroundColor Yellow
Stop-Process -Id $serverProcess.Id -Force
