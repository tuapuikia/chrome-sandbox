FROM debian:trixie-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Add this line to bust the cache whenever you want a fresh update
ARG CACHEBUST=1

# Install dependencies for Chromium, X11, and pulse audio
# Using Debian 13 (Trixie) and installing chromium-sandbox
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    chromium \
    chromium-sandbox \
    chromium-l10n \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-nanum \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libgbm1 \
    libgles2 \
    libegl1 \
    libvulkan1 \
    mesa-va-drivers \
    intel-media-va-driver \
    mesa-vulkan-drivers \
    mesa-utils \
    libva-glx2 \
    libva-drm2 \
    libva-x11-2 \
    pulseaudio \
    libpulse0 \
    alsa-utils \
    fonts-liberation \
    libasound2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Environment variables for NVIDIA GPU support
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute

# Create a non-privileged user and ensure it has access to GPU devices
RUN groupadd -g 109 render || true && \
    useradd -m -s /bin/bash -G video,render chromium || \
    usermod -aG video,render chromium

# Set up work directory
WORKDIR /home/chromium

# Copy start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Persistent directory for Chromium profile
RUN mkdir -p /home/chromium/.config/chromium && \
    chown -R chromium:chromium /home/chromium

USER chromium

ENTRYPOINT ["/usr/local/bin/start.sh"]
