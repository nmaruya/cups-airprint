#!/bin/bash
set -e

# 1. Start the Avahi daemon for AirPrint discovery
service avahi-daemon start

# 2. Start the Canon CAPT daemon
# This is the translator that talks to the LBP3300
service ccpd start

# 3. Start CUPS in the foreground 
# (Keeping it in the foreground prevents the container from exiting)
exec /usr/sbin/cupsd -f
