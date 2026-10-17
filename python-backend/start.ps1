# OpenSearch - Start all services
# Run with: .\start.ps1

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "OpenSearch - Start All Services" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

function Test-Port {
    param($Port)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect("localhost", $Port)
        $tcp.Close()
        return $true
    } catch {
        return $false
    }
}

# Check/Start Ollama
Write-Host "[*] Checking Ollama..." -ForegroundColor Yellow
if (Test-Port -Port 11434) {
    Write-Host "    [*] Ollama running on port 11434" -ForegroundColor Green
} else {
    Write-Host "    [*] Starting Ollama..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    if (Test-Port -Port 11434) {
        Write-Host "    [*] Ollama started on port 11434" -ForegroundColor Green
    } else {
        Write-Host "    [X] Ollama failed to start" -ForegroundColor Red
    }
}

# Start API server
Write-Host "[*] Starting API server..." -ForegroundColor Yellow
$apiProc = Start-Process python -ArgumentList "main.py" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru

Start-Sleep -Seconds 5

if (Test-Port -Port 11435) {
    Write-Host "    [*] API server running on http://localhost:11435" -ForegroundColor Green
} else {
    Write-Host "    [X] API server failed to start" -ForegroundColor Red
}

# Test API
Write-Host "[*] Testing API..." -ForegroundColor Yellow
try {
    $body = @{
        model = "qwen2.5-coder:7b"
        messages = @(@{role = "user"; content = "hi"})
        stream = $false
    } | ConvertTo-Json
    
    $resp = Invoke-RestMethod -Uri "http://localhost:11435/v1/chat/completions" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 60
    $content = $resp.choices[0].message.content
    
    if ($content) {
        Write-Host "    [*] API test passed!" -ForegroundColor Green
        Write-Host "    Response: $($content.Substring(0, [Math]::Min(50, $content.Length)))..." -ForegroundColor Green
    } else {
        Write-Host "    [X] API returned empty response" -ForegroundColor Red
    }
} catch {
    Write-Host "    [X] API test error: $_" -ForegroundColor Red
}

# Check/Start OpenWebUI
Write-Host "[*] Checking OpenWebUI..." -ForegroundColor Yellow
$webuiRunning = docker ps --filter "name=openwebui" --format "{{.Names}}" 2>$null

if ($webuiRunning -eq "openwebui") {
    docker start openwebui 2>$null
    Write-Host "    [*] OpenWebUI running on http://localhost:3000" -ForegroundColor Green
} elseif ($webuiRunning -eq "") {
    Write-Host "    [*] Starting OpenWebUI (may take a few minutes)..." -ForegroundColor Yellow
    docker run -d --name openwebui -p 3000:8080 -e "OLLAMA_BASE_URL=http://host.docker.internal:11434" -e "API_KEY=opensearch-local" openwebui/open-webui:latest 2>$null
    Start-Sleep -Seconds 10
    if (Test-Port -Port 3000) {
        Write-Host "    [*] OpenWebUI started on http://localhost:3000" -ForegroundColor Green
    }
} else {
    Write-Host "    [X] OpenWebUI Docker error" -ForegroundColor Red
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "All services started!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API URL:      http://localhost:11435/v1/chat/completions" -ForegroundColor White
Write-Host "API Models:   http://localhost:11435/v1/models" -ForegroundColor White
Write-Host "OpenWebUI:    http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "To connect OpenWebUI:'n" -ForegroundColor Yellow
Write-Host "  1. Go to http://localhost:3000" -ForegroundColor White
Write-Host "  2. Settings > Connections" -ForegroundColor White
Write-Host "  3. Add OpenAI Compatible API" -ForegroundColor White
Write-Host "     URL: http://host.docker.internal:11435" -ForegroundColor White
Write-Host "     API Key: opensearch-local" -ForegroundColor White
Write-Host ""

# Keep process running
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Yellow
while ($true) {
    Start-Sleep -Seconds 10
}