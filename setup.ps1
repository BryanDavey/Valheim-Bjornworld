# --- Configuration & Setup ---
$ErrorActionPreference = 'Stop'
Write-Host "=== ModdedValheim Launcher ===`n"

# Path where this script is located (Valheim-Modded folder)
$ModdedValheimDir = (Get-Item .).FullName

# Paths
# Path to where Valheim.exe will look for world and character save data
$ValheimSave = Join-Path $env:userprofile 'appdata\locallow\IronGate\Valheim'

Write-Host "ModdedValheim folder:   $ModdedValheimDir"
Write-Host "Valheim saves folder: $ValheimSave"

$SaveFolder = Join-Path $ModdedValheimDir 'Saves'
Write-Host "This operation will copy any existing world and character saves into this Valhiem installation."
Write-Host "Please navigate to $ValheimSave in your file explorer and ensure you want to copy those saves into this Valheim installation."
Write-Host "After this operation, the contents of:`n  $ValheimSave `nwill be copied to:`n  $SaveFolder"


. ".\Read_YesNoChoice.ps1" # Load external script with Read-YesNoChoice function
$choice = Read-YesNoChoice -Title "Would you like to continue?" -Message "Yes or No?" -DefaultOption 1

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

Write-Host "Valheim game files will be copied from:`n   $ValheimDir to`n    $ModdedValheimDir"

$choice = Read-YesNoChoice -Title "Would you like to continue?" -Message "Yes or No?" -DefaultOption 1

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

# Define allowed folders and files
$WhitelistedFolders = @('D3D12', 'MonoBleedingEdge', 'Valheim_Data')
$WhitelistedFiles = @('Valheim.exe', 'steam_appid.txt', 'UnityCrashHandler64.exe', 'UnityPlayer.dll')

# Move everything recursively, preserving existing items
Get-ChildItem -Path $ValheimDir -Recurse -Force |
    Where-Object {
        $include = $false

        # --- Folder whitelist check ---
        foreach ($folder in $WhitelistedFolders) {
            if ($_.FullName -like "*\$folder\*") {
                $include = $true
                break
            }
        }

        # --- File whitelist check ---
        if (-not $include -and -not $_.PSIsContainer) {
            $filename = Split-Path -Path $_.FullName -Leaf
            if ($WhitelistedFiles -contains $filename) {
                $include = $true
            }
        }

        # Output true or false to Where-Object
        $include
    } |
    ForEach-Object {
        # Compute relative path to preserve folder structure
        $relativePath = $_.FullName.Substring($ValheimDir.Length - 1).TrimStart('\')
        $destination = Join-Path -Path $ModdedValheimDir -ChildPath $relativePath

        # Copy if not already existing
        if (-Not (Test-Path $destination)) {
            $parentDir = Split-Path -Path $destination -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }

            Write-Output "Copying $($_.FullName) into $destination"
            Copy-Item -Path "$($_.FullName)" -Destination "$destination"
        } else {
            Write-Output "Skipping existing item: $relativePath"
        }
    }

# # Move everything recursively, preserving existing items
# Get-ChildItem -Path $ValheimDir -Recurse -Force | ForEach-Object {
#     # Compute relative path to preserve folder structure
#     $relativePath = $_.FullName.Substring($ValheimDir.Length - 1).TrimStart('\')
#     $destination = Join-Path -Path $ModdedValheimDir -ChildPath $relativePath

#     # Move file or folder if it doesn't exist
#     if (-Not (Test-Path $destination)) {
#         Write-Output "Copying $($_.FullName) into $destination"
#         Copy-Item -Path $_.FullName -Destination $destination
#     } else {
#         Write-Output "Skipping existing item: $relativePath"
#     }
# }

Write-Host "Copy completed from $ValheimDir to $ModdedValheimDir"


# --- Copy existing mod cfg files (if they exist) ---
$ExistingConfigPath = Join-Path $ValheimDir 'BepInEx\config'
$NewConfigPath = Join-Path $ModdedValheimDir 'BepInEx\config'

Write-Host "In the next operation, the script will find and copy any existing BepInEx config files from your Valheim installation."
Write-Host "BepInEx config files will be copied from:`n   $ExistingConfigPath to`n    $NewConfigPath"
$choice = Read-YesNoChoice -Title "Would you like to continue?" -Message "Yes or No?" -DefaultOption 1

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

if ((Test-Path $ExistingConfigPath)) {
    Write-Output "Existing mod settings found. Copying to new modded Valheim installation."
    # Move everything recursively, preserving existing items
    Get-ChildItem -Path $ExistingConfigPath -Recurse -Force | ForEach-Object {
        # Compute relative path to preserve folder structure
        $relativePath = $_.FullName.Substring($ExistingConfigPath.Length - 1).TrimStart('\')
        $destination = Join-Path -Path $NewConfigPath -ChildPath $relativePath

        # Move file or folder if it doesn't exist
        if (-Not (Test-Path $destination)) {
            Write-Output "Copying $($_.FullName) into $destination"
            Copy-Item -Path $_.FullName -Destination $destination
        } else {
            Write-Output "Skipping existing item: $relativePath"
        }
    }
} else {
    Write-Output "Could not find existing BepInEx\config folder."
}