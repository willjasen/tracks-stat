#!/bin/sh

# Check if darkice is installed
if ! which darkice > /dev/null 2>&1; then
    apt-get update;
    apt-get install darkice -y;
else
    echo "darkice is already installed";
fi

# Check if icecast2 is installed
if ! which icecast2 > /dev/null 2>&1; then
    apt-get update;
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
    # USB_AUDIO=$(arecord -l | grep 'device [0-9]\+: USB Audio \[USB Audio\]' | awk '{print $2}' | tr -d ':');
    USB_AUDIO=$(arecord -l | grep 'card [0-9]\+: CODEC \[USB Audio CODEC\]' | awk '{print $2}' | tr -d ':');

    # Validate that USB_AUDIO is not empty
    if [ -z "$USB_AUDIO" ]; then
        error_exit "USB_AUDIO variable is empty. Ensure that the USB Audio CODEC is connected and recognized.";
    fi

    # Validate that USB_AUDIO contains only digits
    if ! echo "$USB_AUDIO" | grep -qE '^[0-9]+$'; then
        error_exit "USB_AUDIO variable ('$USB_AUDIO') is not a valid number.";
    fi

    sed -i.bak "s/\(plughw:CODEC,\)[0-9]\+/\1$USB_AUDIO/" /home/wiljasen/darkice.cfg;

};

configure_usb_audio_device;

# Make darkice a service
cp darkice.service /etc/systemd/system/darkice.service;
systemctl daemon-reload;
systemctl enable darkice.service;

# Start darkice and icecast2
systemctl restart darkice.service;
systemctl restart icecast2.service;
