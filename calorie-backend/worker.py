import requests
import sys
import time

# usage: python worker.py [base_url]
# example: python worker.py http://localhost

BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost"

def trigger_notification():
    endpoint = f"{BASE_URL}/notify"
    print(f"Attempting to trigger notification at {endpoint}...")
    
    payload = {
        "message": "Data availability notification: New analysis ready!"
    }
    
    try:
        response = requests.post(endpoint, json=payload)
        if response.status_code == 200:
            print("✅ Notification triggered successfully.")
            print("Response:", response.json())
        else:
            print(f"❌ Failed to trigger. Status: {response.status_code}")
            print("Response:", response.text)
    except requests.exceptions.ConnectionError:
        print(f"❌ Could not connect to {BASE_URL}. Is the server running?")
    except Exception as e:
        print(f"❌ An error occurred: {e}")

if __name__ == "__main__":
    trigger_notification()
