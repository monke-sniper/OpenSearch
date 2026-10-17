@echo off
REM Launch opensearch and keep window open
set PATH=%USERPROFILE%\.bun\bin;%PATH%
start "OpenSearch" bun.exe run C:\Users\idkch\opensearch\packages\opencode\src\index.ts