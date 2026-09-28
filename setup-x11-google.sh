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

# Set Display if not set: detect active X11 socket or fallback to :0
if [ -z "$DISPLAY" ]; then
  DETECTED_SOCK=$(ls -1 /tmp/.X11-unix/X* 2>/dev/null | head -n 1)
  if [ -n "$DETECTED_SOCK" ]; then
    DISPLAY_NUM=$(basename "$DETECTED_SOCK" | sed 's/^X//')
    export DISPLAY=":${DISPLAY_NUM}"
  else
    export DISPLAY=:0
  fi
  echo "Setting DISPLAY to $DISPLAY"
fi

# Ensure containers are running in the background
echo "Starting containers in the background..."
docker compose up -d wireguard-chromium thorium-sandbox

# Function to handle Ctrl+C (it will just terminate the exec process)
trap 'echo "Terminating Thorium session..."; exit 0' SIGINT SIGTERM

echo "Launching Thorium Browser in the sandbox container ($GPU_TYPE)..."

if [ "$GPU_TYPE" == "nvidia" ]; then
    # NVIDIA GPU with Vulkan/ANGLE and Platform HEVC support
    docker compose exec -it \
        -e DISPLAY="$DISPLAY" \
        -e __NV_PRIME_RENDER_OFFLOAD=1 \
        -e __GLX_VENDOR_LIBRARY_NAME=nvidia \
        -e __VK_LAYER_NV_optimus=NVIDIA_only \
        -u chromium thorium-sandbox \
        /usr/local/bin/start.sh \
        --use-angle=vulkan \
        --gpu-preference=high-performance \
        --ignore-gpu-blocklist \
        --enable-features=VaapiVideoDecoder,PlatformHEVCDecoderSupport \
        "$@"

else
    # Default Intel/Mesa (Integrated)
    docker compose exec -it \
        -e DISPLAY="$DISPLAY" \
        -e __NV_PRIME_RENDER_OFFLOAD=0 \
        -e __GL_VENDOR_LIBRARY_NAME=mesa \
        -u chromium thorium-sandbox \
        /usr/local/bin/start.sh \
        --use-gl=angle \
        --use-angle=gl \
        --enable-zero-copy \
        --enable-gpu-memory-buffer-video-frames \
        --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization,PlatformHEVCDecoderSupport \
        --ignore-gpu-blocklist \
        --enable-gpu-rasterization \
        --ozone-platform=x11 \
        --enable-gpu \
        "$@"
fi



