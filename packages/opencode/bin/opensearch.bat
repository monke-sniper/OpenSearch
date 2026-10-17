@echo off
REM OpenSearch Launcher - Interactive CLI with thinking and search agent
setlocal

REM Find bun
set "BUN_PATH=%USERPROFILE%\.bun\bin\bun.exe"
if not exist "%BUN_PATH%" (
    echo ERROR: Bun not found at %BUN_PATH%
    exit /b 1
)

REM Run opencode with search agent and thinking enabled
"%BUN_PATH%" run C:\Users\idkch\opensearch\packages\opencode\src\index.ts run --agent search --thinking %*
endlocal