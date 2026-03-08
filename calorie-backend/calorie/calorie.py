import redis
import json
from celery import Celery

redis_worker = redis.Redis(host='redis', port=6379, decode_responses=True)

def notify_client(client_id: str, message: str):
    """Publishes a notification to the Redis channel."""
    
    payload = {
        "client_id": client_id,
        "message": message
    }
    
    # Publish to the same channel the FastAPI instances are listening to
    redis_worker.publish("ws_notifications", json.dumps(payload))
    print(f"Notification sent to Redis for client: {client_id}")


@app.task(name='calorie.demo', bind=True, max_retries=0, ignore_result=True)
def demo(self, request_data):
    print(">>>> demo")

    notify_client(client_id="client-123", message="hello world")