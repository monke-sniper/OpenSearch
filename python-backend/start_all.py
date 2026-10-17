#!/usr/bin/env python3
"""
OpenSearch API Server - Start all services with one command
Run with: python start_all.py
"""

import subprocess
import sys
import os
import time
import socket
import requests

OLLAMA_PORT = 11434
API_PORT = 11435
WEBUI_PORT = 3000

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('localhost', port))
    sock.close()
    return result == 0

def start_ollama():
    if check_port(OLLAMA_PORT):
        print(f"[*] Ollama already running on port {OLLAMA_PORT}")
        return True
    
    print("Starting Ollama...")
    try:
        subprocess.Popen(['ollama', 'serve'], 
                        stdout=subprocess.DEVNULL, 
                        stderr=subprocess.DEVNULL,
                        creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0)
        for _ in range(20):
            time.sleep(1)
            if check_port(OLLAMA_PORT):
                print(f"[*] Ollama started on port {OLLAMA_PORT}")
                return True
        print("[X] Ollama failed to start")
        return False
    except Exception as e:
        print(f"[X] Error starting Ollama: {e}")
        return False

def start_api_server():
    if check_port(API_PORT):
        print(f"[*] API server already running on port {API_PORT}")
        return True
    
    print(f"Starting API server on port {API_PORT}...")
    try:
        from main import app
        import uvicorn
        import threading
        
        def run():
            uvicorn.run(app, host="0.0.0.0", port=API_PORT, log_level="error")
        
        thread = threading.Thread(target=run, daemon=True)
        thread.start()
        
        for _ in range(10):
            time.sleep(1)
            if check_port(API_PORT):
                print(f"[*] API server started on http://localhost:{API_PORT}")
                return True
        print("[X] API server failed to start")
        return False
    except Exception as e:
        print(f"[X] Error starting API server: {e}")
        return False

def start_openwebui():
    try:
        result = subprocess.run(['docker', 'ps', '-a', '--filter', 'name=openwebui', '--format', '{{.Names}}'],
                            capture_output=True, text=True, timeout=10)
        
        if 'openwebui' in result.stdout:
            subprocess.run(['docker', 'start', 'openwebui'], capture_output=True, timeout=30)
            print(f"[*] OpenWebUI started on http://localhost:{WEBUI_PORT}")
            return True
        
        print("Starting OpenWebUI container (first time may take a few minutes)...")
        proc = subprocess.Popen(['docker', 'run', '-d', '--name', 'openwebui', '-p', f'{WEBUI_PORT}:8080',
                              '-e', f'OLLAMA_BASE_URL=http://host.docker.internal:{OLLAMA_PORT}',
                              '-e', 'API_KEY=opensearch-local',
                              'openwebui/open-webui:latest'],
                             capture_output=True, timeout=300)
        proc.wait()
        
        for _ in range(30):
            time.sleep(2)
            if check_port(WEBUI_PORT):
                print(f"[*] OpenWebUI started on http://localhost:{WEBUI_PORT}")
                return True
        
        print("[X] OpenWebUI failed to start")
        return False
    except FileNotFoundError:
        print("[X] Docker not found - skipping OpenWebUI")
        return False
    except Exception as e:
        print(f"[X] Error with OpenWebUI: {e}")
        return False

def test_api():
    try:
        url = f"http://localhost:{API_PORT}/v1/chat/completions"
        data = {
            "model": "qwen2.5-coder:7b",
            "messages": [{"role": "user", "content": "Hi"}],
            "stream": False
        }
        
        print("\nTesting API...")
        resp = requests.post(url, json=data, timeout=60)
        
        if resp.status_code == 200:
            result = resp.json()
            content = result.get("choices", [{}])[0].get("message", {}).get("content", "")
            if content:
                print(f"[*] API test passed!")
                print(f"  Response: {content[:80]}...")
                return True
            else:
                print("[X] API returned empty content")
                return False
        else:
            print(f"[X] API test failed: {resp.status_code}")
            return False
    except Exception as e:
        print(f"[X] API test error: {e}")
        return False

def main():
    print("=" * 50)
    print("OpenSearch - Start All Services")
    print("=" * 50)
    print()
    
    # Start Ollama
    if not start_ollama():
        print("Warning: Ollama not available")
    
    # Start API server
    if not start_api_server():
        print("Error: API server failed to start")
        return
    
    # Test API
    test_api()
    
    # Start OpenWebUI
    start_openwebui()
    
    print()
    print("=" * 50)
    print("All services started!")
    print("=" * 50)
    print()
    print(f"API URL:        http://localhost:{API_PORT}/v1/chat/completions")
    print(f"Models:         http://localhost:{API_PORT}/v1/models")
    print(f"Ollama:         http://localhost:{OLLAMA_PORT}")
    print(f"OpenWebUI:     http://localhost:{WEBUI_PORT}")
    print()
    print("To connect OpenWebUI:")
    print(f"  1. Go to http://localhost:{WEBUI_PORT}")
    print("  2. Settings > Connections")
    print(f"  3. Add OpenAI Compatible API")
    print(f"     URL: http://host.docker.internal:{API_PORT}")
    print("     API Key: opensearch-local")
    print()
    print("Press Ctrl+C to stop all services")
    print("=" * 50)
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping services...")
        try:
            subprocess.run(['docker', 'stop', 'openwebui'], capture_output=True, timeout=30)
        except:
            pass
        print("Done!")

if __name__ == "__main__":
    main()