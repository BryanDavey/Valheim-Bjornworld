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