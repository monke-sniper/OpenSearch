@echo off
REM OpenSearch - Run with search agent by default
cd /d "%~dp0"
bun run packages/opencode/src/index.ts --agent search %*