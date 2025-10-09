@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0CreateShortcut.ps1"