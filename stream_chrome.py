from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
import json
import time
import threading

def monitor_network_traffic(driver):
    total_bytes = 0
    received_responses = []
    
    def response_received(message):
        nonlocal total_bytes
        try:
            message_dict = json.loads(message)
            if message_dict['method'] == 'Network.responseReceived':
                received_responses.append(message_dict['params']['requestId'])
            elif message_dict['method'] == 'Network.loadingFinished':
                request_id = message_dict['params']['requestId']
                if request_id in received_responses:
                    encoded_length = message_dict['params'].get('encodedDataLength', 0)
                    total_bytes += encoded_length
                    print(f"Received {encoded_length} bytes for request {request_id}")
        except Exception as e:
            print(f"Error processing network event: {e}")
        return total_bytes

    # Enable network tracking
    driver.execute_cdp_cmd('Network.enable', {})
    
    # Add event listener
    driver.add_cdp_listener('Network.responseReceived', response_received)
    driver.add_cdp_listener('Network.loadingFinished', response_received)
    
    return total_bytes

def launch_chrome_stream_with_logging(stream_url, duration, instance_num, driver_path):
    # Configure Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--mute-audio")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--headless")
    chrome_options.set_capability('goog:loggingPrefs', {'performance': 'ALL'})
    
    # Initialize the WebDriver
    service = Service(executable_path=driver_path)
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    try:
        # Enable CDP Network domain
        driver.execute_cdp_cmd('Network.enable', {})
        
        # Start monitoring before navigating
        total_bandwidth = monitor_network_traffic(driver)
        
        print(f"Starting stream in Chrome instance: {instance_num}")
        driver.get(stream_url)
        
        # Stream for the specified duration
        time.sleep(duration)
        
    except Exception as e:
        print(f"An error occurred in instance {instance_num}: {e}")
    finally:
        driver.execute_cdp_cmd('Network.disable', {})
        driver.quit()
        print(f"Closed Chrome instance: {instance_num}, Total Bandwidth Used: {total_bandwidth} bytes")

def main():
    stream_url = "http://rp.risk-mermaid.ts.net:8000/"
    driver_path = "/opt/homebrew/bin/chromedriver"  # Update this path if different
    num_instances = 5  # Number of Chrome instances to launch
    duration = 3  # Duration in seconds
    threads = []

    print(f"Preparing to launch Chrome: {num_instances} instances")
    for i in range(num_instances):
        thread = threading.Thread(target=launch_chrome_stream_with_logging, args=(stream_url, duration, i, driver_path))
        threads.append(thread)
    
    # Start all threads
    for thread in threads:
        thread.start()
    
    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    print("All Chrome instances have completed streaming.")

if __name__ == "__main__":
    main()