FROM debian:trixie-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Chromium, X11, and pulse audio
# Using Debian 13 (Trixie) and installing chromium-sandbox
RUN apt-get update && apt-get install -y \
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
    pulseaudio \
    libpulse0 \
    alsa-utils \
    fonts-liberation \
    libasound2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Create a non-privileged user
RUN useradd -m -s /bin/bash chromium

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
