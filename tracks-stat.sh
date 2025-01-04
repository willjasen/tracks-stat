#!/bin/sh

# Install dependencies
apt-get update;
apt install git -y;

# Install darkice and icecast2
apt-get install darkice icecast2 -y;
