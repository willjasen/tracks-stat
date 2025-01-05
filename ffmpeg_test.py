import subprocess
import threading
import re
import random
import time

STREAM_HOST = "http://rp.risk-mermaid.ts.net:8000/"
CLIENT_INSTANCES = 25
DURATION_MIN = 3
DURATION_MAX = 5

total_bytes_read = 0
total_bytes_lock = threading.Lock()

def run_ffmpeg(instance_id):
    global total_bytes_read
    duration = random.randint(DURATION_MIN, DURATION_MAX)
    cmd = [
        "ffmpeg", "-i", STREAM_HOST, "-t", str(duration),
        "-progress", "pipe:1", "-loglevel", "debug", "-f", "null", "-"
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    for line in process.stderr:
        match = re.search(r"Statistics: (\d+) bytes read", line)
        if match:
            bytes_read = int(match.group(1))
            with total_bytes_lock:
                total_bytes_read += bytes_read
            print(f"\033[0;33mDuration: {duration} seconds, {line.strip()}\033[0m")

    process.wait()

def main():
    print("\033[0;32mStarting {} streaming instances...\033[0m".format(CLIENT_INSTANCES))
    threads = []
    for i in range(CLIENT_INSTANCES):
        thread = threading.Thread(target=run_ffmpeg, args=(i,))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

    print("\033[0;32mThe streaming test is done.\033[0m")
    print("\033[0;32mTotal bytes read: {}\033[0m".format(total_bytes_read))

if __name__ == "__main__":
    main()
