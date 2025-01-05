from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
import json
import time

def get_cf_cache_status(driver):
    logs = driver.get_log('performance')
    for entry in logs:
        log = json.loads(entry['message'])['message']
        if log['method'] == 'Network.responseReceived':
            response = log['params']['response']
            headers = response.get('headers', {})
            cf_cache_status = headers.get('CF-Cache-Status')
            if cf_cache_status:
                url = response.get('url')
                print(f"URL: {url}\nCF-Cache-Status: {cf_cache_status}\n")

def launch_chrome_stream_with_logging(stream_url, duration, driver_path):
    # Configure Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--mute-audio")  # Mute audio to prevent overlapping sounds
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    # Uncomment the next line to run Chrome in headless mode
    chrome_options.add_argument("--headless")
    
    # Enable performance logging
    perf_log_prefs = {
        'enableNetwork': True,
    }
    chrome_options.set_capability('goog:loggingPrefs', {'performance': 'ALL'})
    
    # Initialize the WebDriver
    service = Service(executable_path=driver_path)
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    try:
        # Navigate to the stream URL
        driver.get(stream_url)
        print(f"Started streaming in Chrome instance PID: {driver.service.process.pid}")
        
        # Wait for a short period to allow network events to be captured
        time.sleep(5)  # Adjust based on your needs
        
        # Retrieve and parse CF-Cache-Status headers
        get_cf_cache_status(driver)
        
        # Continue streaming for the remaining duration
        remaining_time = duration - 5  # Adjust based on the initial sleep
        if remaining_time > 0:
            time.sleep(remaining_time)
        
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Close the browser
        driver.quit()
        print(f"Closed Chrome instance PID: {driver.service.process.pid}")

def main():
    stream_url = "https://stream.stretchie.delivery/"
    duration = 5  # Duration in seconds (1 minute)
    driver_path = "/opt/homebrew/bin/chromedriver"  # Update this path if different
    
    num_instances = 1  # Number of Chrome instances to launch
    for i in range(num_instances):
        print(f"Launching Chrome instance {i+1}/{num_instances}")
        launch_chrome_stream_with_logging(stream_url, duration, driver_path)
        time.sleep(1)  # Slight delay to prevent overwhelming the system

    print("All Chrome instances have completed streaming.")

if __name__ == "__main__":
    main()

