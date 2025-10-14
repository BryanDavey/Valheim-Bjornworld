# --- Ensure Steam is running ---
# Ensure Steam is running
$steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue

if (-not $steamProcess) {
    Write-Host "Steam is not running. Starting Steam..."
    $steamPath = "${env:appdata}\Microsoft\Windows\Start Menu\Programs\Steam.lnk"

    if (-not (Test-Path $steamPath)) {
        Write-Host "Steam not found at default path. Please specify your Steam path manually."
        exit 1
    }

    Start-Process $steamPath
    # Optional: wait for it to start before continuing
    Start-Sleep -Seconds 10
} else {
    Write-Host "Steam is already running."
}

# --- Add git template remote and pull latest changes ---
Write-Host "Checking for any changes on remote Git repository..."
# Fetch latest from all remotes
git fetch | Out-Null

# Perform merge and capture output
$pullOutput = git pull 2>&1

Write-Host $pullOutput
Write-Host "Git update done."

# Check if merge actually changed anything
if ($pullOutput -notmatch "Already up to date.") {
    Write-Host "Changes were merged. Re-running this script..."
    # Restart this script
    & $PSCommandPath
    exit
} else {
    Write-Host "No new Git changes found. Continuing...`n`n"
}
# Reset the terminal output so only relevant info is shown when prompting the user for Yes/No
Clear-Host

# --- Check Nextcloud for updates to the plugins ---
# URL of the shared file
$NextCloudURLFilePath = Join-Path $PSScriptRoot "NextCloudURLs.ps1"
if (Test-Path $NextCloudURLFilePath) {
    . $NextCloudURLFilePath
    Write-Host "✅ Loaded variables from $NextCloudURLFilePath"
    try {
        $remoteVersion = Invoke-WebRequest -Uri $remoteVersionUrl -UseBasicParsing
    } catch {
        Write-Host "⚠️ Could not check version. Downloading anyway."
        $remoteVersion.content = "-1"
    }

    # Read and parse versions
    $localVersionUrl = Join-Path $PSScriptRoot "BepInEx\plugins\version.md"
    if (Test-Path $localVersionUrl) {
        $localVersion = [int](Get-Content $localVersionUrl | Select-Object -First 1)
    } else {
        $localVersion = "-1"
    }

    $remoteVersion = $remoteVersion.content
    # Compare
    if ([int]$remoteVersion -gt [int]$localVersion) {
        Write-Host "Some mods have been updated in the Nextcloud folder."
        . ".\Read_YesNoChoice.ps1" # Load external script with Read-YesNoChoice function
        $choice = Read-YesNoChoice -Title "Would you like to download them?" -Message "Yes or No?" -DefaultOption 1

        # Act based on the choice
        switch ($choice) {
            0 { 
                Write-Host "You answered No. Continuing..."
            }
            1 {
                Write-Host "You answered Yes. Downloading mods from Nextcloud..."
                Write-Host "🆕 New mod version detected ($remoteVersion). Downloading..."
                $pluginsDir = Join-Path $PSScriptRoot "BepInEx\plugins"
                $tempZip = Join-Path $PSScriptRoot "mods.zip"

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

                Write-Host "✅ Mods updated successfully!"
            }
        }
    } else {
        Write-Host "Mods do not need to be updated. Continuing..."
    }
    # Reset the terminal output so only relevant info is shown when prompting the user for Yes/No
    Clear-Host
} else {
    Write-Warning "⚠️ Variables file not found at: $NextCloudURLFilePath"
}

# --- Create link (junction) between default save location (C:\Users\Bryan\AppData\LocalLow\IronGate) and the Save folder in this directory ---

$SaveFolder = Join-Path (Get-Item .).FullName 'Saves'
$ValheimSave = Join-Path $env:userprofile 'appdata\locallow\IronGate\Valheim'

Write-Host "Valheim default save location: $ValheimSave"
Write-Host "SaveFolder:                    $SaveFolder"

Write-Host "`nThis script will create a junction (shortcut) between where Valheim is looking for save data and where the save data is in this custom Valheim installation.`n"
Write-Host "This operation will not copy any data, just create a shortcut such that:`n    $ValheimSave`nwill redirect to:`n    $SaveFolder"

# --- Remove existing save link or folder ---
if (Test-Path $ValheimSave) {
    Write-Host "Removing existing Valheim save folder/link..."
    Remove-Item $ValheimSave -Recurse -Force
}

# --- Create new junction ---
Write-Host "Creating junction..."
cmd /c mklink /J "`"$ValheimSave`"" "`"$SaveFolder`""

if (-not (Test-Path $ValheimSave)) {
    Write-Host "[ERROR] Failed to create junction."
    exit 1
}

# --- Launch Valheim ---
$ExePath = Join-Path (Get-Item .).FullName 'valheim.exe'
if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] valheim.exe not found at $ExePath"
    exit 1
}

Write-Host "`nLaunching Valheim..."
Start-Process -FilePath $ExePath

Write-Host "Done! You can close this window."