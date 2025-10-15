# URL of the shared file
$NextCloudURLFilePath = Join-Path $PSScriptRoot "NextCloudURLs.ps1"
if (Test-Path $NextCloudURLFilePath) {
    . $NextCloudURLFilePath
    Write-Host "Loaded variables from $NextCloudURLFilePath"
} else {
    Write-Warning "Variables file not found at: $NextCloudURLFilePath"
    exit 1
}

$pluginsDir = Join-Path $PSScriptRoot "BepInEx\plugins"
$tempZip = Join-Path $PSScriptRoot "mods.zip"
$localVersionUrl = Join-Path $PSScriptRoot "BepInEx\plugins\version.md"

try {
    $remoteVersion = Invoke-WebRequest -Uri $remoteVersionUrl -UseBasicParsing
} catch {
    Write-Host "Could not check version. Downloading anyway."
    $remoteVersion.content = "-1"
}
Write-Host "localversionurl: $localVersionUrl"
# Read and parse versions
if (Test-Path $localVersionUrl) {
    $localVersion = [int](Get-Content $localVersionUrl | Select-Object -First 1)
} else {
    $localVersion = "-1"
}

$remoteVersion = $remoteVersion.content

Write-Host "Local version:  $localVersion"
Write-Host "Remote version: $remoteVersion"

# Compare
if ([int]$remoteVersion -gt [int]$localVersion) {
    Write-Host "New mod version detected ($remoteVersion). Downloading..."

    # Download ZIP
    # Invoke-WebRequest -Uri $modsUrl -OutFile $tempZip # Slow
    curl.exe -L "$modsUrl" -o "$tempZip" # Much faster

    # Create temporary extraction folder
    $tempExtract = Join-Path ([System.IO.Path]::GetTempPath()) "mods_extract"
    if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
    New-Item -ItemType Directory -Path $tempExtract | Out-Null

    # Extract to temp folder
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    # Detect if a single top-level folder exists
    $entries = Get-ChildItem -Path $tempExtract -Force
    if ($entries.Count -eq 1 -and $entries[0].PSIsContainer) {
        # Use that subfolder as the real root
        $realExtractPath = $entries[0].FullName
    } else {
        # Otherwise use the temp folder directly
        $realExtractPath = $tempExtract
    }

    # Move the actual contents into the plugins directory
    Get-ChildItem -Path $realExtractPath -Force | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $pluginsDir -Force
    }

    # Clean up temp files
    Remove-Item $tempExtract -Recurse -Force
    Remove-Item $tempZip -Force

    Write-Host "Mods updated successfully!"
} elseif ([int]$remoteVersion -lt [int]$localVersion) {
    Write-Host "⬇Local version is newer? ($localVersion > $remoteVersion)"
} else {
    Write-Host "Versions match ($localVersion). No Update required."
}