#!/bin/sh

# Define error_exit function
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Check if cloudflared is installed
if ! which cloudflared > /dev/null 2>&1; then
    # Update package list and install dependencies
    apt-get update || error_exit "Failed to update package list"
    apt-get install -y curl || error_exit "Failed to install curl"

    # Download and install the Cloudflare Tunnel package
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o /usr/local/bin/cloudflared || error_exit "Failed to download cloudflared"
    chmod +x /usr/local/bin/cloudflared || error_exit "Failed to make cloudflared executable"

    # Verify the installation
    cloudflared --version || error_exit "Failed to verify cloudflared installation"
else
    echo "cloudflared is already installed"
    echo "Uninstalling existing Cloudflare Tunnel service"
    if systemctl list-units --full -all | grep -Fq 'cloudflared-update.timer'; then
        systemctl stop cloudflared-update.timer || error_exit "Failed to stop cloudflared-update.timer"
    fi
    sudo cloudflared service uninstall || error_exit "Failed to uninstall existing Cloudflare Tunnel service"
fi

# Create a configuration directory for cloudflared
mkdir -p /etc/cloudflared || error_exit "Failed to create cloudflared configuration directory"

# Create a systemd service file for cloudflared
cat <<EOF > /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/cloudflared tunnel run
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the cloudflared service
systemctl daemon-reload || error_exit "Failed to reload systemd daemon"
systemctl enable cloudflared || error_exit "Failed to enable cloudflared service"
systemctl start cloudflared || error_exit "Failed to start cloudflared service"

echo "Cloudflare Tunnel installation completed successfully"
