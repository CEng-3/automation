#!/bin/bash

# Define service file paths
SERVICE1="timelapse.service"
SERVICE2="stream.service"

# Define systemd directory
SYSTEMD_DIR="/etc/systemd/system"

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try: sudo ./setup.sh"
   exit 1
fi

echo "Stopping and disabling existing services (if they exist)..."
systemctl stop "$SERVICE1" 2>/dev/null || true
systemctl stop "$SERVICE2" 2>/dev/null || true
systemctl disable "$SERVICE1" 2>/dev/null || true
systemctl disable "$SERVICE2" 2>/dev/null || true

echo "Removing old service files..."
rm -f "$SYSTEMD_DIR/$SERVICE1"
rm -f "$SYSTEMD_DIR/$SERVICE2"

echo "Copying new service files..."
cp "$SERVICE1" "$SYSTEMD_DIR/"
cp "$SERVICE2" "$SYSTEMD_DIR/"
chmod 644 "$SYSTEMD_DIR/$SERVICE1"
chmod 644 "$SYSTEMD_DIR/$SERVICE2"

echo "Reloading systemd..."
systemctl daemon-reload

echo "Enabling and starting services..."
systemctl enable "$SERVICE1"
systemctl enable "$SERVICE2"
systemctl start "$SERVICE1"
systemctl start "$SERVICE2"

echo "Installing NetworkManager (if not installed)..."
apt update && apt install -y network-manager

echo "Enabling NetworkManager-wait-online service..."
systemctl enable NetworkManager-wait-online.service

# Function to check service status
check_service() {
    local service_name=$1
    systemctl is-active --quiet "$service_name"
    if [[ $? -eq 0 ]]; then
        echo "[✔] $service_name is running."
    else
        echo "[✘] $service_name failed to start! Check logs: sudo journalctl -u $service_name --no-pager"
    fi
}

echo "Checking service statuses..."
check_service "$SERVICE1"
check_service "$SERVICE2"

echo "Setup and update complete!"