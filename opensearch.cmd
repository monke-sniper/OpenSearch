@echo off
REM OpenSearch Launcher - Run from anywhere
REM Add paths temporarily for this session
set PATH=%USERPROFILE%\.bun\bin;%PATH%
set PATH=C:\Users\idkch\opensearch;%PATH%

REM Check if --agent is already passed
set "HAS_AGENT=0"
echo %* | findstr /C:"--agent" >nul 2>&1
if !errorlevel! equ 0 set "HAS_AGENT=1"
echo %* | findstr /C:"-a " >nul 2>&1
if !errorlevel! equ 0 set "HAS_AGENT=1"

set "ARGS="
if !HAS_AGENT! equ 0 set "ARGS=--agent search"

REM Enable thinking display by default (verbose reasoning)
set "ARGS=!ARGS! --thinking"

REM Run opensearch with search agent and thinking
bun run C:\Users\idkch\opensearch\packages\opencode\src\index.ts !ARGS! %*