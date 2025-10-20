# PowerShell watcher: watches Downloads and copies matching pngs to assets/images/generated
# Usage: Open PowerShell and run: .\save_images_watcher.ps1

$downloadFolder = [Environment]::GetFolderPath('UserProfile') + '\Downloads'
$destFolder = Join-Path -Path (Resolve-Path "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\..\assets\images\generated") -ChildPath ''
if (-not (Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder -Force | Out-Null }
Write-Host "Watching Downloads: $downloadFolder"
Write-Host "Destination: $destFolder"

$filter = '*.png'
$fsw = New-Object System.IO.FileSystemWatcher $downloadFolder, $filter -Property @{IncludeSubdirectories=$false; EnableRaisingEvents=$true}

Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    Start-Sleep -Milliseconds 500
    try {
        # Simple heuristic: if filename contains '_icon' or '_story' copy as-is
        if ($name -match '_icon' -or $name -match '_story') {
            $dest = Join-Path $destFolder $name
            Copy-Item -Path $path -Destination $dest -Force
            Write-Host "Copied $name -> $dest"
        } else {
            # Otherwise copy but prefix with 'imported_'
            $dest = Join-Path $destFolder ("imported_$name")
            Copy-Item -Path $path -Destination $dest -Force
            Write-Host "Copied $name -> $dest"
        }
    } catch {
        Write-Host ("Error copying {0}: {1}" -f $name, $_)
    }
}

Write-Host "Press Enter to stop watcher..."
[Console]::ReadLine() | Out-Null
Unregister-Event -SourceIdentifier FileCreated -Force
$fsw.EnableRaisingEvents = $false
$fsw.Dispose()
Write-Host "Watcher stopped."