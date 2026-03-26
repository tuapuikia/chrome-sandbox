#!/bin/bash

# Get current Xhost permissions
XHOST_STATUS=$(xhost | grep "LOCAL:")

# Check if local access is allowed
if [[ "$XHOST_STATUS" != *"LOCAL:"* ]]; then
  echo "Allowing local connections via xhost..."
  xhost +local:docker
else
  echo "xhost already configured for local access."
fi

# Ensure X11 socket path exists
if [ ! -d "/tmp/.X11-unix" ]; then
  echo "/tmp/.X11-unix not found. X11 might not be running correctly."
fi

# Set Display if not set
if [ -z "$DISPLAY" ]; then
  export DISPLAY=:0
  echo "Setting DISPLAY to :0"
fi

# Ensure containers are running in the background
echo "Starting containers in the background..."
docker compose up -d wireguard chromium-sandbox

# Function to handle Ctrl+C (it will just terminate the exec process)
trap 'echo "Terminating chromium session..."; exit 0' SIGINT SIGTERM

echo "Launching Chromium in the sandbox container..."
echo "Press Ctrl+C to close Chromium (the container will remain running)."

# Run Chromium via docker compose exec
# We use the start.sh script already in the container but we call it explicitly
docker compose exec -it -u chromium chromium-sandbox /usr/local/bin/start.sh
