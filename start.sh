#!/bin/bash

# Default arguments for Chromium
CHROME_FLAGS=(
  "--enable-gpu-rasterization"
  "--ignore-gpu-blocklist"
  "--disable-dev-shm-usage"
  "--user-data-dir=/home/chromium/.config/chromium"
)

# Run Chromium with the SUID sandbox (provided by chromium-sandbox package)
# Note: We do NOT use --no-sandbox because we want the sandbox security.
# This requires SYS_ADMIN capability in docker-compose.yml
exec chromium "${CHROME_FLAGS[@]}" "$@"
