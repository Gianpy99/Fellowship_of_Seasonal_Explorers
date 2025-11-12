# ========================================
# Create ICO Icon from PNG for Windows
# ========================================

Write-Host "Creating ICO icon for Seasonal Quest App..." -ForegroundColor Cyan

# Paths
$sourcePng = Join-Path $PSScriptRoot "web\icons\Icon-192.png"
$outputIco = Join-Path $PSScriptRoot "seasonal_quest_app.ico"

# Check if source PNG exists
if (-not (Test-Path $sourcePng)) {
    Write-Host "ERROR: Source PNG not found at: $sourcePng" -ForegroundColor Red
    exit 1
}

# Load required assemblies
Add-Type -AssemblyName System.Drawing

try {
    Write-Host "Loading PNG image..." -ForegroundColor Yellow
    
    # Load the PNG image
    $png = [System.Drawing.Image]::FromFile($sourcePng)
    
    # Create icon sizes (Windows standard sizes)
    $sizes = @(16, 32, 48, 64, 128, 256)
    
    Write-Host "Creating multi-resolution ICO file..." -ForegroundColor Yellow
    
    # Create a bitmap for the icon
    $icon = New-Object System.Drawing.Bitmap $png
    
    # Save as ICO (using the largest size)
    $iconBitmap = New-Object System.Drawing.Bitmap($icon, 256, 256)
    $iconHandle = $iconBitmap.GetHicon()
    $iconObject = [System.Drawing.Icon]::FromHandle($iconHandle)
    
    # Save the icon
    $fileStream = [System.IO.File]::Create($outputIco)
    $iconObject.Save($fileStream)
    $fileStream.Close()
    
    # Cleanup
    $iconObject.Dispose()
    $iconBitmap.Dispose()
    $icon.Dispose()
    $png.Dispose()
    
    Write-Host ""
    Write-Host "Icon created successfully!" -ForegroundColor Green
    Write-Host "Location: $outputIco" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Failed to create icon: $_" -ForegroundColor Red
    exit 1
}

# Now update the desktop shortcut to use the icon
Write-Host "Updating desktop shortcut with new icon..." -ForegroundColor Cyan

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Seasonal Quest App.lnk"

if (Test-Path $shortcutPath) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.IconLocation = $outputIco
    $Shortcut.Save()
    
    Write-Host "Desktop shortcut updated with new icon!" -ForegroundColor Green
    Write-Host ""
    
    # Release COM object
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
} else {
    Write-Host "WARNING: Desktop shortcut not found. Run CREATE_DESKTOP_SHORTCUT.ps1 first." -ForegroundColor Yellow
}

Write-Host "Done! Your Seasonal Quest App now has a custom icon." -ForegroundColor Green
Write-Host ""
