import requests
import json

url = "http://localhost:11434/v1/chat/completions"
payload = {
    "model": "qwen2.5-coder:7b",
    "messages": [
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "hi"}
    ],
    "stream": False
}

print("Calling Ollama directly...")
resp = requests.post(url, json=payload, timeout=120)
print(f"Status: {resp.status_code}")
print(f"Response: {resp.text}")
print()

data = resp.json()
print(f"Parsed: {json.dumps(data, indent=2)}")
print()

content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
print(f"Content: {repr(content)}")