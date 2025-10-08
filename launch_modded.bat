@echo off
setlocal

:: --- Find Steam install path for Valheim via registry ---
for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 892970" /v InstallLocation 2^>nul') do set VALHEIM_DIR=%%B

:: Fallback in case registry lookup fails
if "%VALHEIM_DIR%"=="" (
    echo Could not find Valheim install in registry. Please set VALHEIM_DIR manually.
    pause
    exit /b 1
)

:: --- Derive Bjornworld path (one directory up) ---
for %%A in ("%VALHEIM_DIR%") do set STEAM_COMMON_DIR=%%~dpA
set BJORNWORLD_DIR=%STEAM_COMMON_DIR%Valheim-Bjornworld

:: --- Paths for Valheim saves ---
set VALHEIM_SAVE="%LOCALAPPDATA%\Low\IronGate\Valheim"

echo.
echo ==========================================
echo  Valheim detected at: %VALHEIM_DIR%
echo  Bjornworld folder:   %BJORNWORLD_DIR%
echo ==========================================
echo.

@REM :: --- Replace and recreate junction ---
@REM echo Removing existing save link...
@REM rmdir /S /Q %VALHEIM_SAVE% 2>nul

@REM echo Creating new junction...
@REM mklink /J %VALHEIM_SAVE% "%BJORNWORLD_DIR%\Valheim - Bjornworld"
@REM if errorlevel 1 (
@REM     echo Failed to create junction. Check folder paths.
@REM     pause
@REM     exit /b 1
@REM )

@REM :: --- Launch Valheim ---
@REM echo Starting Valheim...
@REM start "" "%VALHEIM_DIR%\valheim.exe"

endlocal