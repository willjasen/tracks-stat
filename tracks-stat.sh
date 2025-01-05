#!/bin/sh

# Install dependencies
apt-get update;

# Check if darkice is installed
if ! which darkice > /dev/null 2>&1; then
    apt-get install darkice -y;
else
    echo "darkice is already installed";
fi

# Check if icecast2 is installed
if ! which icecast2 > /dev/null 2>&1; then
    apt-get install icecast2 -y;
else
    echo "icecast2 is already installed";
fi

# Define error_exit function
error_exit() {
    echo "$1" 1>&2
    exit 1
};

# configure the USB audio device
configure_usb_audio_device () {

    # Get the card number of the USB audio device, needed for darkice
    USB_AUDIO=$(arecord -l | grep 'device [0-9]\+: USB Audio \[USB Audio\]' | awk '{print $2}' | tr -d ':');

    # Validate that USB_AUDIO is not empty
    if [ -z "$USB_AUDIO" ]; then
        error_exit "USB_AUDIO variable is empty. Ensure that the USB Audio CODEC is connected and recognized.";
    fi

    # Validate that USB_AUDIO contains only digits
    if ! echo "$USB_AUDIO" | grep -qE '^[0-9]+$'; then
        error_exit "USB_AUDIO variable ('$USB_AUDIO') is not a valid number.";
    fi

    sed -i.bak "s/\(plughw:CODEC,\)[0-9]\+/\1$USB_AUDIO/" darkice.cfg;

};

configure_usb_audio_device;

# Make darkice a service
chmod +x /home/willjasen/darkice.sh;
cp darkice.service /etc/systemd/system/darkice.service;
systemctl daemon-reload;
systemctl enable darkice.service;

# Start icecast and darkice
systemctl start icecast2.service;
systemctl start darkice.service;