#!/bin/bash

# Default to Intel
GPU_TYPE="intel"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --nvidia) GPU_TYPE="nvidia"; shift ;;
        --intel) GPU_TYPE="intel"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

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

echo "Launching Chromium in the sandbox container ($GPU_TYPE)..."

if [ "$GPU_TYPE" == "nvidia" ]; then
    # Force NVIDIA via Prime offload and Vulkan flags
    docker compose exec -it \
        -e __NV_PRIME_RENDER_OFFLOAD=1 \
        -e __GLX_VENDOR_LIBRARY_NAME=nvidia \
        -e __VK_LAYER_NV_optimus=NVIDIA_only \
        -u chromium chromium-sandbox \
        /usr/local/bin/start.sh \
        --use-angle=vulkan \
        --gpu-preference=high-performance \
        --ignore-gpu-blocklist
else
    # Default Intel/Mesa (Integrated)
    # Use standard GL/EGL for Intel, ensuring NVIDIA is fully off
    # We add more flags to force-enable hardware features
    docker compose exec -it \
        -e __NV_PRIME_RENDER_OFFLOAD=0 \
        -e __GL_VENDOR_LIBRARY_NAME=mesa \
        -u chromium chromium-sandbox \
        /usr/local/bin/start.sh \
        --use-gl=desktop \
        --enable-zero-copy \
        --enable-gpu-memory-buffer-video-frames \
        --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization \
        --ignore-gpu-blocklist
fi
