# --- Configuration & Setup ---
$ErrorActionPreference = 'Stop'
Write-Host "=== ModdedValheim Launcher ===`n"

# Path where this script is located (Valheim-Modded folder)
# $ModdedValheimDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ModdedValheimDir = (Get-Item .).FullName

# Paths
# $ValheimSave = Join-Path $env:LOCALAPPDATA 'Low\IronGate\Valheim'
$ValheimSave = Join-Path $env:userprofile 'appdata\locallow\IronGate\Valheim'

Write-Host "ModdedValheim folder:   $ModdedValheimDir"
Write-Host "Valheim saves folder: $ValheimSave"

. ".\Read_YesNoChoice.ps1" # Load external script with Read-YesNoChoice function
$choice = Read-YesNoChoice -Title "Is this information correct?" -Message "Yes or No?" -DefaultOption 1

# Act based on the choice
switch ($choice) {
    0 { 
        Write-Host "You answered No. Exiting..."
        exit 1
    }
    1 { 
        Write-Host "You answered Yes. Continuing..."
        # Continue script...
    }
}

# --- Copy world and character saves to this modded valheim installation ---

$SaveFolder = Join-Path $ModdedValheimDir 'Saves'
Write-Host "The contents of:`n  $ValheimSave `nwill now be copied to:`n  $SaveFolder"

# Ensure the source and destination exist
if (-Not (Test-Path $ValheimSave)) {
    Write-Error "Source folder $ValheimSave does not exist."
    Write-Output "Please run Valheim from steam first (then exit) to generate the saves folder."
    return
}
if (-Not (Test-Path $SaveFolder)) {
    Write-Output "Destination folder $SaveFolder does not exist. Creating it..."
    New-Item -ItemType Directory -Path $SaveFolder | Out-Null
}

# Move all saves into the modded valheim folder
Get-ChildItem -Path $ValheimSave -Force | ForEach-Object {
    $destination = Join-Path -Path $SaveFolder -ChildPath $_.Name
    
    # Move item if it doesn't already exist
    if (-Not (Test-Path $destination)) {
        Move-Item -Path $_.FullName -Destination $SaveFolder
    } else {
        Write-Output "Skipping existing item: $($_.Name)"
    }
}

# Move everything recursively, preserving existing items
Get-ChildItem -Path $ValheimSave -Recurse -Force | ForEach-Object {
    # Compute relative path to preserve folder structure
    $relativePath = $_.FullName.Substring($ValheimSave.Length).TrimStart('\')
    $destination = Join-Path -Path $SaveFolder -ChildPath $relativePath

    # Move file or folder if it doesn't exist
    if (-Not (Test-Path $destination)) {
        Move-Item -Path $_.FullName -Destination $destination
    } else {
        Write-Output "Skipping existing item: $relativePath"
    }
}

# --- Copy Game files to this modded valheim installation ---

# Get Steam install path from registry
$SteamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam").SteamPath

if (-not $SteamPath) {
    Write-Error "Could not find Steam installation path."
    exit 1
}
Write-Host "Found Steam path: $steamPath"

$ValheimDir = (Get-Content "$SteamPath\steamapps\libraryfolders.vdf" |
    Where-Object { $_ -match '"path"' } | ForEach-Object { ($_ -replace '.*"path"\s*"\s*(.+?)\s*".*','$1') }) |
    ForEach-Object { 
        $manifest = Join-Path $_ "steamapps\appmanifest_892970.acf"
        if (Test-Path $manifest) {
            $installdir = (Get-Content $manifest | Where-Object { $_ -match '"installdir"' }) -replace '.*"installdir"\s*"\s*(.+?)\s*".*','$1'
            Join-Path (Join-Path $_ "steamapps\common") $installdir
        }
    } | Where-Object { $_ -ne $null } | Select-Object -First 1

Write-Host "`nValheim found at: $ValheimDir"
Write-Host "Valheim game files will be copied from $ValheimDir to $ModdedValheimDir"
$choice = Read-YesNoChoice -Title "Is this information correct?" -Message "Yes or No?" -DefaultOption 1

# Act based on the choice
switch ($choice) {
    0 { 
        Write-Host "You answered No. Exiting..."
        exit 1
    }
    1 { 
        Write-Host "You answered Yes. Continuing..."
        # Continue script...
    }
}

$ValheimDir = $ValheimDir.TrimEnd('\')

# Move everything recursively, preserving existing items
Get-ChildItem -Path $ValheimDir -Recurse -Force | ForEach-Object {
    # Compute relative path to preserve folder structure
    $relativePath = $_.FullName.Substring($ValheimDir.Length - 1).TrimStart('\')
    $destination = Join-Path -Path $ModdedValheimDir -ChildPath $relativePath

    # Move file or folder if it doesn't exist
    if (-Not (Test-Path $destination)) {
        Write-Output "Copying $($_.FullName) into $destination"
        Copy-Item -Path $_.FullName -Destination $destination
    } else {
        Write-Output "Skipping existing item: $relativePath"
    }
}

Write-Host "Copy completed from $ValheimDir to $ModdedValheimDir"

# $WorldSave   = Join-Path $ModdedValheimDir 'Valheim - Modded'

# # --- Remove existing save link or folder ---
# if (Test-Path $ValheimSave) {
#     Write-Host "Removing existing Valheim save folder/link..."
#     Remove-Item $ValheimSave -Recurse -Force
# }

# # --- Create new junction ---
# Write-Host "Creating junction..."
# cmd /c mklink /J "`"$ValheimSave`"" "`"$WorldSave`""

# if (-not (Test-Path $ValheimSave)) {
#     Write-Host "[ERROR] Failed to create junction."
#     exit 1
# }

# # --- Launch Valheim ---
# $ExePath = Join-Path $ValheimDir 'valheim.exe'
# if (-not (Test-Path $ExePath)) {
#     Write-Host "[ERROR] valheim.exe not found at $ExePath"
#     exit 1
# }

# Write-Host "`nLaunching Valheim..."
# Start-Process -FilePath $ExePath

# Write-Host "Done! You can close this window."