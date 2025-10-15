@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0GetBepInExFiles.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0checkForModUpdates.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0CreateShortcut.ps1"