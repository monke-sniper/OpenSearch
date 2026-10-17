@echo off
REM OpenSearch Launcher - Run from anywhere
REM Find and run opencode with search agent enabled

setlocal enabledelayedexpansion

REM Find opencode binary
set "OPENCODE_DIR=%~dp0"
for %%A in ("!OPENCODE_DIR!") do set "OPENCODE_DIR=%%~dpA"
for /f "delims=" %%B in ('dir /s /b "!OPENCODE_DIR!node_modules\.bin\opencode.exe" 2^>nul') do set "OPENCODE=%%B"

if not defined OPENCODE (
    for /f "delims=" %%B in ('dir /s /b "!OPENCODE_DIR!..\node_modules\.bin\opencode.exe" 2^>nul') do set "OPENCODE=%%B"
)

if not defined OPENCODE (
    echo ERROR: Could not find opencode binary
    exit /b 1
)

REM Check if --agent is already passed
set "HAS_AGENT=0"
echo %* | findstr /C:"--agent" >nul
if !errorlevel! equ 0 set "HAS_AGENT=1"
echo %* | findstr /C:"-a" >nul
if !errorlevel! equ 0 set "HAS_AGENT=1"

set "ARGS="
if !HAS_AGENT! equ 0 set "ARGS=--agent search"

REM Enable thinking display by default (verbose reasoning)
set "ARGS=!ARGS! --thinking"

REM Run opencode
endlocal
"%OPENCODE%" %ARGS% %*