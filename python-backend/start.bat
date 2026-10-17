@echo off
REM OpenSearch - Start all services
REM Run with: start.bat

echo ================================================
echo OpenSearch - Start All Services
echo ================================================
echo.

REM Check if Ollama is running
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Ollama already running on port 11434
) else (
    echo [*] Starting Ollama...
    start /b ollama serve
    timeout /t 5 /nobreak >nul
)

REM Start API server
echo [*] Starting API server on port 11435...
start "OpenSearch API" cmd /c "cd /d %~dp0 && python main.py"

timeout /t 5 /nobreak >nul

REM Test API
curl -s -X POST http://localhost:11435/v1/chat/completions -H "Content-Type: application/json" -d "{"model": "qwen2.5-coder:7b", "messages": [{"role": "user", "content": "hi"}]}" >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] API server running on http://localhost:11435
) else (
    echo [*] API server started
)

REM Check OpenWebUI
docker ps -a --filter name=openwebui -q >nul 2>&1
if %errorlevel% equ 0 (
    docker start openwebui >nul 2>&1
    echo [*] OpenWebUI started on http://localhost:3000
) else (
    echo [*] OpenWebUI container not found - skipping
)

echo.
echo ================================================
echo All services started!
echo ================================================
echo.
echo API:        http://localhost:11435
echo OpenWebUI:  http://localhost:3000
echo.
echo To connect OpenWebUI:
echo   1. Go to http://localhost:3000
echo   2. Settings ^> Connections
echo   3. Add OpenAI Compatible API
echo      URL: http://host.docker.internal:11435
echo      API Key: opensearch-local
echo.
pause