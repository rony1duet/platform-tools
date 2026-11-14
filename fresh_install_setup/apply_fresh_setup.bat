@echo off
setlocal
cd /d "%~dp0"
echo ============================================================
echo   Redmi Note 12 Pro (sweet2) - Fresh Setup Provisioner
echo ============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply_fresh_setup.ps1"
pause
