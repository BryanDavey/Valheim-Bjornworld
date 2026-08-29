# --- Copy Game files to this modded valheim installation ---

# Path where this script is located (Valheim-Modded folder)
$ModdedValheimDir = (Get-Item .).FullName

# Get Steam install path from registry
$SteamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam").SteamPath

if (-not $SteamPath) {
    Write-Error "Could not find Steam installation path."
    exit 1
}

$ValheimDir = (Get-Content "$SteamPath\steamapps\libraryfolders.vdf" |
    Where-Object { $_ -match '"path"' } | ForEach-Object { ($_ -replace '.*"path"\s*"\s*(.+?)\s*".*','$1') }) |
    ForEach-Object { 
        $manifest = Join-Path $_ "steamapps\appmanifest_892970.acf"
        if (Test-Path $manifest) {
            $installdir = (Get-Content $manifest | Where-Object { $_ -match '"installdir"' }) -replace '.*"installdir"\s*"\s*(.+?)\s*".*','$1'
            Join-Path (Join-Path $_ "steamapps\common") $installdir
        }
    } | Where-Object { $_ -ne $null } | Select-Object -First 1

Write-Host "Valheim game files will be copied from:`n    $ValheimDir`nto`n    $ModdedValheimDir"

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

Write-Host "Copy completed from $ValheimDir to $ModdedValheimDir"