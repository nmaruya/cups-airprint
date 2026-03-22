#!/bin/bash
# Usage: ./setup.sh LBP3300 /dev/usb/lp0

PRINTER_NAME=${1:-LBP3300}
DEVICE_PATH=${2:-/dev/usb/lp0}

echo "Registering $PRINTER_NAME on $DEVICE_PATH..."

# 1. Register with CUPS using the Canon PPD
docker exec -it cups-canon lpadmin -p "$PRINTER_NAME" -m CNCUPSLBP3300CAPTK.ppd -v ccp://localhost:59687 -E

# 2. Register with the CAPT Daemon
docker exec -it cups-canon ccpdadmin -p "$PRINTER_NAME" -o "$DEVICE_PATH"

# 3. Restart the daemon inside the container
docker exec -it cups-canon service ccpd restart

echo "Setup complete. Visit http://localhost:631 to enable sharing."
