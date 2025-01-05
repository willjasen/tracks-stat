#!/bin/sh

# Install dependencies
apt-get update;

# Install darkice and icecast2
apt-get install darkice -y;
apt-get install icecast2 -y;

# configure the USB audio device
configure_usb_audio_device () {

    # Get the card number of the USB audio device, needed for darkice
    USB_AUDIO=$(arecord -l | grep 'card [0-9]\+: CODEC \[USB Audio CODEC\]' | awk '{print $2}' | tr -d ':');

    # Validate that USB_AUDIO is not empty
    if [[ -z "$USB_AUDIO" ]]; then
        error_exit "USB_AUDIO variable is empty. Ensure that the USB Audio CODEC is connected and recognized.";
    fi

    # Validate that USB_AUDIO contains only digits
    if ! [[ "$USB_AUDIO" =~ ^[0-9]+$ ]]; then
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

