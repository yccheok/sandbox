import os
import shutil
from typing import List
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
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()


# --- Pydantic Models ---
class Notification(BaseModel):
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
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep connection alive
            # You can process client messages here if needed
            data = await websocket.receive_text()
            # For this requirement, we mainly push notifications to the client
            # But we must await receive_text to keep the loop running and detect disconnects
    except WebSocketDisconnect:
        manager.disconnect(websocket)


# --- Trigger Notification Endpoint (for Worker) ---
@app.post("/notify")
async def notify(notification: Notification):
    """
    Endpoint for the worker to trigger a notification to all connected clients.
    """
    await manager.broadcast(notification.message)
    return {"status": "notification sent", "message": notification.message}
