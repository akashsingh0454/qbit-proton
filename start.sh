#!/bin/bash

# Default qBittorrent Web UI port
QBITTORRENT_WEBUI_PORT=${QBITTORRENT_WEBUI_PORT:-9090}

# Check for necessary environment variables
if [ -z "$PROTONVPN_SERVER" ] || [ -z "$PROTONVPN_USER" ] || [ -z "$PROTONVPN_PASS" ]; then
  echo "Error: PROTONVPN_SERVER, PROTONVPN_USER, and PROTONVPN_PASS environment variables must be set."
  exit 1
fi

# Find the OpenVPN configuration file
# Assumes only one .ovpn file will be in /etc/openvpn/protonvpn
OVPN_FILE=$(find /etc/openvpn/protonvpn -name "*.ovpn" -print -quit)

if [ -z "$OVPN_FILE" ]; then
  echo "Error: No .ovpn file found in /etc/openvpn/protonvpn. Please mount your ProtonVPN configuration file."
  exit 1
fi

echo "Using OpenVPN configuration: $OVPN_FILE"

# Create auth.txt for OpenVPN credentials
echo "$PROTONVPN_USER" > /etc/openvpn/protonvpn/auth.txt
echo "$PROTONVPN_PASS" >> /etc/openvpn/protonvpn/auth.txt
chmod 600 /etc/openvpn/protonvpn/auth.txt

# Modify the .ovpn file to use the auth.txt file and run as daemon
# Also, ensure that DNS is handled correctly by OpenVPN
# and prevent OpenVPN from changing the default route for the host.
# We only want the container's traffic to go through the VPN.

# Create a modified config file
MODIFIED_OVPN_FILE="/etc/openvpn/protonvpn/config.ovpn"
cp "$OVPN_FILE" "$MODIFIED_OVPN_FILE"

# Check if auth-user-pass is already in the config
if ! grep -q "^auth-user-pass" "$MODIFIED_OVPN_FILE"; then
  echo "auth-user-pass /etc/openvpn/protonvpn/auth.txt" >> "$MODIFIED_OVPN_FILE"
fi
# Ensure script security is high enough if not present
if ! grep -q "^script-security" "$MODIFIED_OVPN_FILE"; then
  echo "script-security 2" >> "$MODIFIED_OVPN_FILE"
fi
# Add up and down scripts to handle DNS and routing if not present
if ! grep -q "^up /etc/openvpn/update-resolv-conf" "$MODIFIED_OVPN_FILE"; then
  echo "up /etc/openvpn/update-resolv-conf" >> "$MODIFIED_OVPN_FILE"
fi
if ! grep -q "^down /etc/openvpn/update-resolv-conf" "$MODIFIED_OVPN_FILE"; then
  echo "down /etc/openvpn/update-resolv-conf" >> "$MODIFIED_OVPN_FILE"
fi

echo "Starting OpenVPN..."
# Start OpenVPN in the background
# The specific server from PROTONVPN_SERVER is expected to be part of the .ovpn filename
# or the user should use a generic .ovpn file that connects to a specified server.
# For simplicity, we'll assume the .ovpn file itself dictates the server, or PROTONVPN_SERVER is used by an entry script.
# The current Dockerfile doesn't use PROTONVPN_SERVER directly in openvpn command yet.
# This script assumes the OVPN_FILE is pre-configured for the desired server, or the user provides a server-specific .ovpn file.
openvpn --config "$MODIFIED_OVPN_FILE" --daemon --log /var/log/openvpn.log

# Wait for the VPN to connect - simple check, might need improvement
echo "Waiting for VPN connection..."
TIMEOUT=60
CONNECTED=false
for i in $(seq 1 $TIMEOUT); do
  if grep -q "Initialization Sequence Completed" /var/log/openvpn.log; then
    echo "VPN connected."
    CONNECTED=true
    break
  fi
  if grep -q "AUTH_FAILED" /var/log/openvpn.log; then
    echo "VPN authentication failed. Please check your credentials."
    exit 1
  fi
  sleep 1
done

if [ "$CONNECTED" = false ]; then
  echo "VPN connection timeout. Please check your OpenVPN configuration and logs."
  cat /var/log/openvpn.log
  exit 1
fi

# Get the VPN IP address
VPN_IP=$(ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
if [ -z "$VPN_IP" ]; then
    echo "Could not determine VPN IP address from tun0."
    # Fallback or error
else
    echo "VPN Interface IP: $VPN_IP"
fi


echo "Starting qBittorrent..."
# Start qBittorrent with the specified Web UI port and without daemonizing (it's managed by Docker)
# Also disabling authentication for local access within the container/VPN for simplicity.
# User can configure this via WebUI later.
exec qbittorrent-nox --webui-port="$QBITTORRENT_WEBUI_PORT" --profile=/config --add-trackers=false --no-splash --no-daemon
# The --profile=/config ensures that qBittorrent saves its configuration in the /config volume.
# --add-trackers=false is a privacy measure.
# Removed --bypass-local-auth because it might not be available or desired.
# Users should set a password via the WebUI. The default is admin/adminadmin.
# The WebUI will be accessible on http://<docker_host_ip>:9090

# Note: For qBittorrent to bind to the VPN interface, you might need to set
# 'Connection > Advanced > Network Interface' in qBittorrent's Web UI settings
# to 'tun0' and 'Optional IP address to bind to' to the VPN_IP.
# This script doesn't automate that qBittorrent internal setting.
# However, with proper firewall rules (not implemented here) or by default,
# qBittorrent should use the default route, which will be via tun0.

# Keep container running if qbittorrent exits (for debugging)
# while true; do sleep 1; done
