#!/usr/bin/env python3
import time

# Simulate some work
time.sleep(10)  # Simulating 10 seconds of work

# Update nginx page to show completion
with open('/var/www/html/index.html', 'w') as f:
    f.write('complete')
#delete later
#time.sleep(100)