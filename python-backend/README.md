# OpenSearch - Python Backend for OpenWebUI

## Quick Start

**Run all services with one command:**

```powershell
powershell -File start.ps1
```

Or the simplified version:

```powershell
powershell -File start_simple.ps1
```

## Services Started

| Service | URL | Port |
|---------|-----|------|
| **Ollama** (LLM) | http://localhost:11434 | 11434 |
| **OpenSearch API** | http://localhost:11435 | 11435 |
| **OpenWebUI** | http://localhost:3000 | 3000 |

## Connect OpenWebUI

1. Go to **http://localhost:3000**
2. Click **Settings** (bottom left)
3. Go to **Connections**
4. Under **OpenAI Compatible API**, add:
   - **URL**: `http://host.docker.internal:11435`
   - **API Key**: `opensearch-local`
5. Click **Connect**

## Test API

```bash
curl -X POST http://localhost:11435/v1/chat/completions ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"qwen2.5-coder:7b\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}"
```

## Model

Default model: `qwen2.5-coder:7b`

To use a different model, specify it in the request:

```json
{"model": "deepseek-r1:1.5b", "messages": [...]}
```

## Environment Variables

Set these before running:

```powershell
$env:OLLAMA_BASE_URL = "http://localhost:11434"  # Ollama URL
$env:DEFAULT_MODEL = "qwen2.5-coder:7b"       # Default model
```

## Files

- `main.py` - FastAPI server
- `start.ps1` - Full startup script
- `start_simple.ps1` - Simplified startup
- `start.bat` - Windows batch file