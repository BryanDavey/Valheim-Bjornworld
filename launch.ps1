# --- Create link (junction) between default save location (C:\Users\Bryan\AppData\LocalLow\IronGate) and the Save folder in this directory ---

$SaveFolder = Join-Path (Get-Item .).FullName 'Saves'
$ValheimSave = Join-Path $env:userprofile 'appdata\locallow\IronGate\Valheim'

Write-Host "Valheim default save location: $ValheimSave"
Write-Host "SaveFolder: $SaveFolder"

Write-Host "This script will create a junction (shortcut) between where Valheim is looking for save data and where the save data is in this custom Valheim installation."
Write-Host "This operation will not copy any data, just create a shortcut such that:`n  $ValheimSave`nwill redirect to:`n   $SaveFolder"
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

# --- Add git template remote and pull latest changes ---
git remote add template git@github.com:BryanDavey/Valheim-Modded.git
git fetch --all
git merge template/main --allow-unrelated-histories -m "Merge updates from template repo"

# --- Launch Valheim ---
$ExePath = Join-Path (Get-Item .).FullName 'valheim.exe'
if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] valheim.exe not found at $ExePath"
    exit 1
}

Write-Host "`nLaunching Valheim..."
Start-Process -FilePath $ExePath

Write-Host "Done! You can close this window."