@echo off
rmdir /S "C:\Users\Bryan\AppData\LocalLow\IronGate\Valheim"
mklink /J "C:\Users\Bryan\AppData\LocalLow\IronGate\Valheim" "F:\Programs\Steam\steamapps\common\Valheim-Bjornworld\Valheim - Bjornworld"
start "" "F:\Programs\Steam\steamapps\common\Valheim-Bjornworld\valheim.exe"