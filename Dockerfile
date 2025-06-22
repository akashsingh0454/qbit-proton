# Use an arm64 Ubuntu base image
FROM arm64v8/ubuntu:latest

# Set environment variables to non-interactive to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install qBittorrent, OpenVPN, and other dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qbittorrent-nox \
    openvpn \
    unzip \
    ca-certificates \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for qbittorrent
RUN useradd -r -m -s /bin/bash qbittorrent

# Create directories for OpenVPN configuration and qBittorrent data
RUN mkdir -p /etc/openvpn/protonvpn /config /downloads
RUN chown -R qbittorrent:qbittorrent /config /downloads /etc/openvpn/protonvpn

# Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose qBittorrent Web UI port
EXPOSE 9090

# Expose ports for qBittorrent P2P traffic (TCP and UDP)
# These will need to be the ports forwarded by ProtonVPN
# For now, we'll just expose a common range. The user will need to
# configure qBittorrent and their ProtonVPN connection to use these.
EXPOSE 6881/tcp
EXPOSE 6881/udp

USER qbittorrent
WORKDIR /home/qbittorrent

# Default command to run when the container starts
CMD ["/start.sh"]
