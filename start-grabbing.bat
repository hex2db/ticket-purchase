@echo off
REM Windows launcher for the Damai ticket grabbing script.
REM Double-click this file, or run: start-grabbing.bat -y
REM It calls start-grabbing.ps1 (PowerShell) with UTF-8 console.

chcp 65001 >nul
setlocal

set "PS1=%~dp0start-grabbing.ps1"
if not exist "%PS1%" (
    echo [ERROR] start-grabbing.ps1 not found next to this bat file.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"

echo.
REM Only pause when launched by double-click (no -y and interactive)
if /i not "%1"=="-y" pause
exit /b %RC%
