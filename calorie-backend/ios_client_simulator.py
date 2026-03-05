import asyncio
import websockets
import sys

# usage: python ios_client_simulator.py [ws_url]
# example: python ios_client_simulator.py ws://localhost/ws

WS_URL = sys.argv[1] if len(sys.argv) > 1 else "ws://localhost/ws"

async def listen_for_notifications():
    print(f"📱 iOS App Simulator connecting to {WS_URL}...")
    try:
        async with websockets.connect(WS_URL) as websocket:
            print("✅ Connected! Listening for data availability notifications...")
            print("(Press Ctrl+C to quit)")
            
            while True:
                message = await websocket.recv()
                print(f"\n🔔 Notification Received: {message}")
                
    except ConnectionRefusedError:
        print(f"❌ Connection refused to {WS_URL}. Is the server running?")
    except websockets.exceptions.ConnectionClosed:
        print("❌ Connection closed by server.")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    try:
        asyncio.run(listen_for_notifications())
    except KeyboardInterrupt:
        print("\nStopped.")
