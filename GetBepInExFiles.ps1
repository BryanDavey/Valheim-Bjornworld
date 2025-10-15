$BepInExSubfolder = "BepInEx_files\BepInExPack_Valheim"
# URL of the shared file
$NextCloudURLFilePath = Join-Path $PSScriptRoot "NextCloudURLs.ps1"
if (Test-Path $NextCloudURLFilePath) {
    . $NextCloudURLFilePath
    Write-Host "Loaded variables from $NextCloudURLFilePath"
} else {
    Write-Warning "Variables file not found at: $NextCloudURLFilePath"
    exit 1
}

# --- $BepInExUrl ----

$BepInExDir = $PSScriptRoot
$tempZip = Join-Path $PSScriptRoot "BepInExFiles.zip"

# Download ZIP
# Invoke-WebRequest -Uri $BepInExUrl -OutFile $tempZip # Slow
curl.exe -L "$BepInExUrl" -o "$tempZip" # Much faster

# Create temporary extraction folder
$tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "bepinex_extract"
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
New-Item -ItemType Directory -Path $tempExtract | Out-Null

# Extract to temp folder
Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

# Full path to the subfolder
$BepInExFilesPath = Join-Path $tempExtract $BepInExSubfolder



# Ensure destination exists
if (-not (Test-Path $BepInExFilesPath)) {
    Write-Error "Could not find $BepInExSubfolder"
    exit 1
}

# Move the actual contents into the plugins directory
Get-ChildItem -Path $BepInExFilesPath -Force | ForEach-Object {
    Move-Item -Path $_.FullName -Destination $BepInExDir -Force
}

# Clean up temp files
Remove-Item $tempExtract -Recurse -Force
Remove-Item $tempZip -Force

Write-Host "BepInEx updated successfully!"
