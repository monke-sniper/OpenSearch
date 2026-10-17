@echo off
REM Simple launcher - make sure bun is found
set PATH=%USERPROFILE%\.bun\bin;%PATH%

REM Run direct
bun.exe run C:\Users\idkch\opensearch\packages\opencode\src\index.ts