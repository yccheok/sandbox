import asyncio
import websockets
import sys

# usage: python ios_client_simulator.py [client_id] [base_ws_url]
# example: python ios_client_simulator.py ios_device_1 ws://localhost/ws

CLIENT_ID = sys.argv[1] if len(sys.argv) > 1 else "ios_device_1"
BASE_WS_URL = sys.argv[2] if len(sys.argv) > 2 else "ws://localhost/ws"

async def listen_for_notifications():
    # Append client_id to the WebSocket URL
    # Ensure BASE_WS_URL doesn't end with / to avoid double slashes, though usually fine
    ws_url = f"{BASE_WS_URL.rstrip('/')}/{CLIENT_ID}"
    
    print(f"📱 iOS App Simulator ({CLIENT_ID}) connecting to {ws_url}...")
    try:
        async with websockets.connect(ws_url) as websocket:
            print(f"✅ Connected as '{CLIENT_ID}'! Listening for notifications...")
            print("(Press Ctrl+C to quit)")
            
            while True:
                message = await websocket.recv()
                print(f"\n🔔 Notification Received: {message}")
                
    except ConnectionRefusedError:
        print(f"❌ Connection refused to {ws_url}. Is the server running?")
    except websockets.exceptions.ConnectionClosed:
        print("❌ Connection closed by server.")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    try:
        asyncio.run(listen_for_notifications())
    except KeyboardInterrupt:
        print("\nStopped.")
