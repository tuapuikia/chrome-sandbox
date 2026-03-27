#!/bin/bash

# Default arguments for Chromium
# Note: Specific GPU flags are now passed from setup-x11.sh at runtime
CHROME_FLAGS=(
  "--enable-gpu-rasterization"
  "--ignore-gpu-blocklist"
  "--disable-dev-shm-usage"
  "--user-data-dir=/home/chromium/.config/chromium"
)

# Run Chromium with the SUID sandbox (provided by chromium-sandbox package)
# Any extra arguments passed to this script will be appended to the flags
exec chromium "${CHROME_FLAGS[@]}" "$@"
