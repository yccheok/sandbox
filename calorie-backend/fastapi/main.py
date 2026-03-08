import os
import shutil
from typing import Dict
from fastapi import FastAPI, File, UploadFile, WebSocket, WebSocketDisconnect
from pydantic import BaseModel

import asyncio
import json
from contextlib import asynccontextmanager
from fastapi.responses import JSONResponse
import redis.asyncio as redis
from celery import Celery
import constants


celery = Celery(
    'main', 
    broker=constants.CELERY_BROKER_URL, 
    backend=constants.CELERY_RESULT_BACKEND
)


# --- Redis Setup ---
# In production, replace 'localhost' with your Redis server URL
redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)
REDIS_CHANNEL = "ws_notifications"


# --- Redis Background Listener ---
async def redis_listener():
    """Listens for messages from Redis with automatic reconnection."""
    print(f"Starting background listener for channel: {REDIS_CHANNEL}")
    
    # The outer loop keeps the task alive indefinitely
    while True:
        try:
            # Create the pubsub object inside the loop so we get a fresh 
            # connection if we are recovering from a crash
            pubsub = redis_client.pubsub()
            await pubsub.subscribe(REDIS_CHANNEL)
            print(f"Successfully subscribed/reconnected to Redis! : {REDIS_CHANNEL}", flush=True)
            
            # The async generator (the "inner" infinite loop)
            async for message in pubsub.listen():
                type = message["type"]

                print(f"Received in Redis! : {REDIS_CHANNEL}", flush=True)
                print(f"The received type is : {type}", flush=True)

                if type == "message":
                    data = json.loads(message["data"])
                    client_id = data.get("client_id")
                    message = data.get("message")
                    
                    print(f"⬅️ >>>> fastapi receiving message '{message}' and client id '{client_id}'", flush=True)

                    await manager.send_personal_message(message, client_id)
                    
        except asyncio.CancelledError:
            # This is triggered by lifespan's listener_task.cancel()
            # We MUST break the while loop here, or the app will never shut down!
            print("Received shutdown signal. Unsubscribing from Redis...", flush=True)
            await pubsub.unsubscribe(REDIS_CHANNEL)
            break 
            
        except Exception as e:
            # Catch connection drops, Redis timeouts, or unexpected errors
            print(f"Redis connection error: {e}", flush=True)
            print("Attempting to reconnect in 5 seconds...", flush=True)
            
            # Prevent the while loop from spinning too fast and maxing out your CPU
            await asyncio.sleep(5)


# --- FastAPI Lifespan ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start the Redis listener in the background when app starts
    listener_task = asyncio.create_task(redis_listener())
    yield
    # Clean up when the app shuts down
    listener_task.cancel()
    await redis_client.close()

    
app = FastAPI(lifespan=lifespan)


# --- Upload Configuration ---
# Create upload directory if it doesn't exist
UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename: str):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# --- WebSocket Manager ---
class ConnectionManager:
    def __init__(self):
        # Map client_id -> WebSocket
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_personal_message(self, message: str, client_id: str):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_text(message)

manager = ConnectionManager()


# --- Pydantic Models ---
class Notification(BaseModel):
    client_id: str
    message: str


# --- Routes ---

@app.get("/info/")
async def info():
    request_data = {}

    celery.send_task('calorie.demo', queue='calorie', args=[request_data], kwargs={})

    return "development only"


@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    # 1. Check if filename is present
    if not file.filename:
         return JSONResponse(
            content={
                "status": "error",
                "message": "No selected file"
            },
            status_code=400
        )

    # 2. Check allowed extension
    if not allowed_file(file.filename):
        return JSONResponse(
            content={
                "status": "error",
                "message": "File type not allowed. Please upload JPG or PNG."
            },
            status_code=400
        )

    # 3. Save the file
    # We use os.path.basename to avoid directory traversal
    filename = os.path.basename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 4. Return success
    return JSONResponse(
        content={
            "status": "success",
            "message": "Image successfully received and processed",
            "data": {
                "filename": filename,
                "document_id": "doc_12345", 
                "confidence_score": 0.98
            }
        },
        status_code=200
    )

# --- WebSocket Endpoint ---
@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket, client_id)
    try:
        while True:
            # Keep connection alive
            # You can process client messages here if needed
            data = await websocket.receive_text()
            # For this requirement, we mainly push notifications to the client
            # But we must await receive_text to keep the loop running and detect disconnects
    except WebSocketDisconnect:
        manager.disconnect(client_id)