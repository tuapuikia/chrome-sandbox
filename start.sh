#!/bin/bash

# Default arguments for Thorium / Chrome / Chromium
# Specific GPU and feature flags are passed from setup script at runtime
CHROME_FLAGS=(
  "--enable-gpu-rasterization"
  "--ignore-gpu-blocklist"
  "--disable-dev-shm-usage"
  "--user-data-dir=/home/chromium/.config/thorium"
)

# Launch Thorium Browser if available, otherwise fallback to Google Chrome or Chromium
if command -v thorium-browser >/dev/null 2>&1; then
    exec thorium-browser "${CHROME_FLAGS[@]}" "$@"
elif command -v google-chrome-stable >/dev/null 2>&1; then
    CHROME_FLAGS[3]="--user-data-dir=/home/chromium/.config/google-chrome"
    exec google-chrome-stable "${CHROME_FLAGS[@]}" "$@"
elif command -v google-chrome >/dev/null 2>&1; then
    CHROME_FLAGS[3]="--user-data-dir=/home/chromium/.config/google-chrome"
    exec google-chrome "${CHROME_FLAGS[@]}" "$@"
else
    # Fallback to chromium if running in legacy container
    CHROME_FLAGS[3]="--user-data-dir=/home/chromium/.config/chromium"
    exec chromium "${CHROME_FLAGS[@]}" "$@"
fi
