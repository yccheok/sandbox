import redis
import json
from celery import Celery

redis_worker = redis.Redis(host='redis', port=6379, decode_responses=True)

app = Celery('calorie')
app.config_from_object('celeryconfig')

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
    # Use Redis to atomically increment a counter
    # This guarantees an accurate count across all Celery workers
    count = redis_worker.incr("calorie_demo_count")

    message = f"Hello world : {count}"
    print(f"➡️ >>>> celery sending '{message}'")

    notify_client(client_id="client-123", message=message)