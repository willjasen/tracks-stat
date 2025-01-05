# tracks-stat
make an internet record player

this project can be used on a raspberry pi along with a usb audio adapter in order to setup a record player (or any other audio source that the adapter supports really) to stream to the internet

the underpinning uses:

- darkice
- icecast2 to setup the stream
- cloudflared to provide a tunnel from the internet to the raspberry pi

initial instructional help from https://www.instructables.com/Stream-Turntable-Vinyl-to-Chromecast/