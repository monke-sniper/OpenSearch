"""
OpenSearch API Server - OpenAI-compatible API for OpenWebUI
Run with: python main.py
"""

import os
import json
import requests
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
import uvicorn

app = FastAPI(title="OpenSearch API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen2.5-coder:7b")


def call_ollama(messages, model, stream=False):
    """Call Ollama API"""
    ollama_model = model.split(":")[1] if ":" in model else model
    url = f"{OLLAMA_BASE_URL}/v1/chat/completions"
    payload = {"model": ollama_model, "messages": messages, "stream": stream}
    
    if stream:
        resp = requests.post(url, json=payload, stream=True, timeout=120)
        for line in resp.iter_lines():
            line = line.decode().strip()
            if line.startswith("data: "):
                data = line[6:]
                if data == "[DONE]":
                    yield "data: [DONE]\n\n"
                    break
                try:
                    chunk = json.loads(data)
                    content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
                    if content:
                        yield f"data: {json.dumps({'choices': [{'delta': {'content': content}}]})}\n\n"
                except:
                    pass
    else:
        resp = requests.post(url, json=payload, timeout=120)
        data = resp.json()
        content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        yield content


@app.get("/v1/models")
async def list_models():
    return JSONResponse({"data": [{"id": DEFAULT_MODEL, "object": "model", "owned_by": "ollama"}]})


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body = await request.json()
    model = body.get("model", DEFAULT_MODEL)
    messages = body.get("messages", [])
    stream = body.get("stream", False)
    
    if not messages:
        return JSONResponse({"error": {"message": "messages required"}}, status_code=400)
    
    system_msg = {"role": "system", "content": "You are a helpful assistant."}
    all_messages = [system_msg] + messages
    
    if stream:
        def generate():
            chat_id = f"chat-{os.urandom(12).hex()}"
            yield f"data: {json.dumps({'id': chat_id, 'choices': [{'delta': {'role': 'assistant'}}]})}\n\n"
            for chunk in call_ollama(all_messages, model, stream=True):
                yield chunk
        return StreamingResponse(generate(), media_type="text/event-stream")
    else:
        response = ""
        for chunk in call_ollama(all_messages, model, stream=False):
            response += chunk
        
        return JSONResponse({
            "id": f"chat-{os.urandom(12).hex()}",
            "object": "chat.completion",
            "created": 0,
            "model": model,
            "choices": [{"index": 0, "message": {"role": "assistant", "content": response}, "finish_reason": "stop"}],
        })


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":
    print(f"OpenSearch API - http://localhost:11435")
    print(f"Model: {DEFAULT_MODEL}")
    uvicorn.run(app, host="0.0.0.0", port=11435)