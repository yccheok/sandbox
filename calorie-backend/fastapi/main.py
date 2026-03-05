import os
import shutil
from typing import Dict
from fastapi import FastAPI, File, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from pydantic import BaseModel

app = FastAPI()

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


# --- Trigger Notification Endpoint (for Worker) ---
@app.post("/notify")
async def notify(notification: Notification):
    """
    Endpoint for the worker to trigger a notification to a specific client.
    """
    await manager.send_personal_message(notification.message, notification.client_id)
    return {"status": "notification sent", "client_id": notification.client_id}
