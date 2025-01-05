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
    #echo "Uninstalling existing Cloudflare Tunnel service"
    #if systemctl list-units --full -all | grep -Fq 'cloudflared-update.timer'; then
    #    systemctl stop cloudflared-update.timer || echo "Failed to stop cloudflared-update.timer, but continuing"
    #fi
    #cloudflared service uninstall || error_exit "Failed to uninstall existing Cloudflare Tunnel service"
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


# Check if config.yml symlink already points to our config
#if [ "$(readlink /etc/cloudflared/config.yml)" != "/opt/tracks-stat/cloudflare-config.yml" ]; then
    # Remove existing config if present
#    if [ -f /etc/cloudflared/config.yml ]; then
#        rm /etc/cloudflared/config.yml || error_exit "Failed to remove existing config";
#    fi
    # Create symlink
#    ln -s /opt/tracks-stat/cloudflare-config.yml /etc/cloudflared/config.yml || error_exit "Failed to create config symlink";
#fi


# Change the config file
# Verify VAR1 is set
if [ -z "${VAR1}" ]; then
    error_exit "VAR1 is not set. Please set the tunnel ID variable.";
else
    # Debug tunnel ID configuration
    echo "Current tunnel ID: ${VAR1}"
fi
# Update config file with tunnel ID
#sed -i "s/^tunnel: .*$/tunnel: ${VAR1}/" /opt/tracks-stat/cloudflare-config.yml || error_exit "Failed to update tunnel ID";
#sed -i "s/^credentials-file: \/etc\/cloudflared\/.*\.json$/credentials-file: \/etc\/cloudflared\/${VAR1}.json/" /opt/tracks-stat/cloudflare-config.yml || error_exit "Failed to update credentials file path";

# Reload systemd, enable and start the cloudflared service
#systemctl daemon-reload || error_exit "Failed to reload systemd daemon"
#systemctl enable cloudflared || error_exit "Failed to enable cloudflared service"
#systemctl start cloudflared || error_exit "Failed to start cloudflared service"

#systemctl stop cloudflared;
rm /etc/systemd/system/cloudflared.service;
systemctl daemon-reload;
cloudflared service uninstall;
cloudflared service install $VAR1;

echo "Cloudflare Tunnel installation completed successfully"

# Clear the cloudflard service
    #systemctl stop cloudflared;
    #rm /etc/systemd/system/cloudflared.service;
    #systemctl daemon-reload;
    #cloudflared service uninstall;