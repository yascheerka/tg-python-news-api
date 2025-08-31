#!/usr/bin/env python3
import asyncio
import websockets
import json
import sys

async def test_websocket():
    # WebSocket URL with authentication and parameters
    uri = "ws://localhost/ws?key=228&channels=@sukatest228"
    
    print(f"🔌 Connecting to WebSocket: {uri}")
    print("📡 Waiting for live messages...")
    print("-" * 50)
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Connected successfully!")
            print("🎯 Listening for messages...")
            print("-" * 50)
            
            # Listen for messages
            async for message in websocket:
                try:
                    data = json.loads(message)
                    print(f"📨 Received: {json.dumps(data, indent=2)}")
                except json.JSONDecodeError:
                    print(f"📨 Raw message: {message}")
                    
    except websockets.exceptions.ConnectionClosed as e:
        print(f"❌ Connection closed: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_websocket())
