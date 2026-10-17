import asyncio
import aiohttp

async def test():
    url = "http://localhost:11434/v1/chat/completions"
    payload = {
        "model": "qwen2.5-coder:7b",
        "messages": [{"role": "user", "content": "hi"}],
        "stream": False
    }
    
    print(f"Testing {url}...")
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                print(f"Status: {resp.status}")
                data = await resp.json()
                print(f"Response: {data}")
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(test())