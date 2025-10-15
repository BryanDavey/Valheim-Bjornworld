@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0GetBepInExFiles.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0launch.ps1"