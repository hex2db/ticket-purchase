@echo off
REM Local Appium launcher (no global install).
REM Runs Appium from .\node_modules and keeps drivers in .\.appium
REM Usage: start-appium.bat [extra args]
REM
REM NOTE: we call node on appium's entry script directly instead of
REM node_modules\.bin\appium.cmd -- the npm shim does SETLOCAL/ENDLOCAL
REM and in that chain APPIUM_HOME gets lost, so Appium falls back to
REM C:\Users\<you>\.appium and reports "No drivers have been installed".

setlocal

set "APPIUM_HOME=%~dp0.appium"
if not exist "%~dp0node_modules\appium\index.js" (
    echo [ERROR] Appium not found in %~dp0node_modules
    echo Run: npm install   inside appium-env
    pause
    exit /b 1
)

REM adb on this machine: D:\Program Files\adb\platform-tools\adb.exe
if not defined ANDROID_HOME set "ANDROID_HOME=D:\Program Files\adb"
if not defined ANDROID_SDK_ROOT set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "PATH=%ANDROID_HOME%\platform-tools;%PATH%"

echo APPIUM_HOME  = %APPIUM_HOME%
echo ANDROID_HOME = %ANDROID_HOME%
echo Listening    = http://127.0.0.1:4723  (Ctrl+C to stop)
echo.

node "%~dp0node_modules\appium\index.js" --port 4723 --relaxed-security --log-level info %*

endlocal
