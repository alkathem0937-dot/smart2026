import requests
import time
import subprocess
import os

RAG_URL = "http://localhost:8080"

def wait_for_rag():
    print(f"Waiting for RAG engine at {RAG_URL}...")
    start_time = time.time()
    while time.time() - start_time < 600: # Wait up to 10 mins
        try:
            response = requests.get(f"{RAG_URL}/health")
            if response.status_code == 200:
                status = response.json()
                if status.get("ready"):
                    print("RAG engine is ready!")
                    return True
                else:
                    print(f"RAG engine status: {status.get('message', 'Loading...')}")
        except Exception:
            pass
        time.sleep(10)
    return False

if __name__ == "__main__":
    if wait_for_rag():
        print("Starting indexing...")
        # Change directory to smartju and run management command
        os.chdir("smartju")
        subprocess.run(["python", "manage.py", "index_legal_db"], check=True)
    else:
        print("RAG engine timed out or failed to start.")
