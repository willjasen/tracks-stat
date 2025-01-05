import subprocess
import threading
import re
import random
import time
import requests
from bs4 import BeautifulSoup

LISTEN_HOST = "http://rp.risk-mermaid.ts.net:8000/status.xsl"
STREAM_HOSTS = [
    "http://rp.risk-mermaid.ts.net:8000/"#,
    #"https://stream.stretchie.delivery/"
]
CLIENT_INSTANCES = 100
DURATION_MIN = 10
DURATION_MAX = 10

total_bytes_read = 0
total_duration = 0
total_bytes_lock = threading.Lock()
total_duration_lock = threading.Lock()

def get_current_listeners():
    url = LISTEN_HOST
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'html.parser')
    listeners_element = soup.find('td', string='Listeners (current):')
    if listeners_element:
        listeners = listeners_element.find_next_sibling('td').text
        return int(listeners)
    else:
        print("DEBUG: Listeners element not found")
        return 0

def run_ffmpeg(instance_id):
    global total_bytes_read, total_duration
    duration = random.randint(DURATION_MIN, DURATION_MAX)
    stream_host = random.choice(STREAM_HOSTS)
    cmd = [
        "ffmpeg", "-i", stream_host, "-t", str(duration),
        "-progress", "pipe:1", "-loglevel", "debug", "-f", "null", "-"
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    for line in process.stderr:
        match = re.search(r"Statistics: (\d+) bytes read", line)
        if match:
            bytes_read = int(match.group(1))
            with total_bytes_lock:
                total_bytes_read += bytes_read
            print(f"\033[0;33mHost: {stream_host}, Duration: {duration} seconds, {line.strip()}\033[0m")

    with total_duration_lock:
        total_duration += duration

    process.wait()

def print_listeners_periodically():
    while True:
        current_listeners = get_current_listeners()
        print(f"\033[0;34mCurrent listeners: {current_listeners}\033[0m")
        time.sleep(0.5)

def main():
    print("\033[0;32mStarting {} streaming instances...\033[0m".format(CLIENT_INSTANCES))
    
    # Start the thread to print listeners periodically
    listener_thread = threading.Thread(target=print_listeners_periodically)
    listener_thread.daemon = True
    listener_thread.start()
    
    threads = []
    for i in range(CLIENT_INSTANCES):
        thread = threading.Thread(target=run_ffmpeg, args=(i,))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

    total_kilobytes_read = total_bytes_read / 1024
    total_megabytes_read = total_kilobytes_read / 1024

    current_listeners = get_current_listeners()

    if total_duration > 0:
        kilobytes_per_second = total_kilobytes_read / total_duration
    else:
        kilobytes_per_second = 0

    print("\033[0;34mTotal bytes read from the {} streams:\033[0m".format(CLIENT_INSTANCES))
    print("\033[0;34mKilobytes read: {:.2f} kilobytes\033[0m".format(total_kilobytes_read))
    print("\033[0;34mMegabytes read: {:.2f} megabytes\033[0m".format(total_megabytes_read))
    print("\033[0;34mTotal streaming duration: {} seconds\033[0m".format(total_duration))
    print("\033[0;34mKilobytes per second - per client: {:.2f} kB/s\033[0m".format(kilobytes_per_second))
    print("\033[0;34mKilobytes per second - all clients: {:.2f} kB/s\033[0m".format(kilobytes_per_second * CLIENT_INSTANCES))
    print("\033[0;32mThe streaming test is done.\033[0m")

if __name__ == "__main__":
    main()
