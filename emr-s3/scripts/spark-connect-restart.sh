#!/bin/bash

echo "Wait for a brief moment to let it start"
# Wait for a brief moment to let it start
sleep 30  # Adjust time based on your environment and service startup time

# Kill the Spark Connect service
echo "Stopping Spark Connect service..."
sudo systemctl stop spark-connect-server

echo "Wait for a brief moment to let it stop cleanly"
# Wait for the service to stop cleanly
sleep 10  # Adjust as needed

# Restart the Spark Connect service
echo "Restarting Spark Connect service..."
sudo systemctl restart spark-connect-server

# Confirm that the service is running again
sleep 5  # Adjust time to ensure the service has enough time to restart
sudo systemctl status spark-connect-server.service
