@echo off
setlocal
echo ======================================================
echo  Claude Code Starter Kit
echo ======================================================
echo.
echo Starting setup. This may take a few minutes.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-ClaudeCodeKit.ps1"
echo.
echo ======================================================
echo  The setup script has finished. You can close this window.
echo ======================================================
pause
endlocal
