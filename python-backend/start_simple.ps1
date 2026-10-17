# OpenSearch - Quick start
# Run: powershell -File start.ps1

$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "OpenSearch - Start Services" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

function Test-Port {
    param($Port)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try { $tcp.Connect("localhost", $Port); $tcp.Close(); return $true } catch { return $false }
}

# 1. Start Ollama
if (-not (Test-Port -Port 11434)) {
    Write-Host "[*] Starting Ollama..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}
Write-Host "[*] Ollama: http://localhost:11434" -ForegroundColor Green

# 2. Start API server
$apiProc = Start-Process python -ArgumentList "main.py" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 5
Write-Host "[*] API: http://localhost:11435" -ForegroundColor Green

# 3. Start OpenWebUI
docker start openwebui 2>$null
if (-not (Test-Port -Port 3000)) {
    docker run -d --name openwebui -p 3000:8080 -e "OLLAMA_BASE_URL=http://host.docker.internal:11434" -e "API_KEY=opensearch-local" openwebui/open-webui:latest 2>$null
    Start-Sleep -Seconds 10
}
Write-Host "[*] OpenWebUI: http://localhost:3000" -ForegroundColor Green

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Ready!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connect OpenWebUI:" -ForegroundColor Yellow
Write-Host "  URL: http://host.docker.internal:11435" -ForegroundColor White
Write-Host "  Key: opensearch-local" -ForegroundColor White
Write-Host ""

# Keep running
try { while($true) { Start-Sleep -Seconds 5 } } catch { }