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
    echo "cloudflared is already installed";
fi

# Create a configuration directory for cloudflared
mkdir -p /etc/cloudflared || error_exit "Failed to create cloudflared configuration directory"

# Verify VAR1 is set
if [ -z "${VAR1}" ]; then
    error_exit "VAR1 is not set. Please set the tunnel ID variable.";
else
    # Debug tunnel ID configuration
    echo "Current tunnel ID: ${VAR1}"
fi

# Clear out the service and redo it
rm /etc/systemd/system/cloudflared.service;
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
systemctl daemon-reload;
cloudflared service uninstall;
cloudflared service install $VAR1;

echo "Cloudflare Tunnel installation completed successfully"
