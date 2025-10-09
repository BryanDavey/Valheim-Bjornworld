# CreateShortcut.ps1
# Creates a desktop shortcut for the isolated Valheim launcher

# === CONFIGURATION ===

# Get the folder this script is in
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FolderName = Split-Path $ScriptDir -Leaf
$LaunchBat = Join-Path $PSScriptRoot "launch_bypassExecutionPolicy.bat"  # assumes launch.bat is in the same folder as this script
# Path for the shortcut (on Desktop)
$ShortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "$FolderName.lnk"
$IconPath = Join-Path $PSScriptRoot "valheim.exe"  # can also point to a .ico file

# === VALIDATION ===
if (-not (Test-Path $LaunchBat)) {
    Write-Error "Could not find launch.bat at $LaunchBat"
    exit 1
}

if (-not (Test-Path $IconPath)) {
    Write-Host "⚠️ Icon file not found at $IconPath. The shortcut will use the default PowerShell icon."
    $IconPath = $null
}

# === SHORTCUT CREATION ===
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $LaunchBat
$Shortcut.WorkingDirectory = Split-Path $LaunchBat
if ($IconPath) { $Shortcut.IconLocation = $IconPath }
$Shortcut.Save()

Write-Host "✅ Shortcut created at: $ShortcutPath"