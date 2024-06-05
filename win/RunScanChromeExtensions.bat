@echo off
setlocal
set "scriptPath=%~dp0ScanChromeExtensions.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptPath%"
endlocal
pause
