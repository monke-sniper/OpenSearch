@echo off
REM Fix UTF-8 encoding for Windows
chcp 65001 >nul 2>&1
set NODE_ENV=production

REM Add bun to PATH  
set PATH=%USERPROFILE%\.bun\bin;%PATH%

REM Run with proper encoding
cmd /c "bun run C:\Users\idkch\opensearch\packages\opencode\src\index.ts %*"