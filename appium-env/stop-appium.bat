@echo off
REM Stop the local Appium server listening on port 4723.

chcp 65001 >nul
setlocal enabledelayedexpansion

set "FOUND="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":4723" ^| findstr "LISTENING"') do (
    set "FOUND=1"
    taskkill /F /PID %%p >nul 2>&1
    if errorlevel 1 (
        echo [WARN] failed to kill PID %%p ^(maybe already gone^)
    ) else (
        echo [OK] killed PID %%p
    )
)

if not defined FOUND echo [INFO] nothing listening on port 4723
exit /b 0
