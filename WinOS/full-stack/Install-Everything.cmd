@echo off
setlocal
echo ======================================================
echo  Claude Code Full Stack Installer
echo ======================================================
echo.
echo This installs Claude Code, skills, caveman, and MCP servers.
echo It runs unattended. A UAC prompt may appear for winget.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Everything.ps1"
echo.
echo ======================================================
echo  Finished. Review the messages above, then close this window.
echo ======================================================
pause
endlocal
