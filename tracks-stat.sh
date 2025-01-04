#!/bin/sh

# Install dependencies
apt-get update;

# Install darkice and icecast2
apt-get install darkice -y;
apt-get install icecast2 -y;

# Make darkice a service
chmod +x chmod /home/willjasen/darkice.sh
cp darkice.service /etc/systemd/system/darkice.service;
systemctl daemon-reload;
systemctl enable darkice.service;
