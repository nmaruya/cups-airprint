# Docker Canon LBP3300: CUPS + CAPT + AirPrint

This repository provides a Dockerized solution for the **Canon LBP3300** laser printer. This specific model requires the proprietary Canon CAPT (Canon Advanced Printing Technology) driver, which relies on a 32-bit background daemon (`ccpd`) to communicate with the hardware.

This image is optimized for **OpenMediaVault (OMV)** and other headless Linux servers.



## 🚀 Features
- **Canon CAPT v2.71 Drivers**: Pre-installed and configured for the LBP3300.
- **32-bit Compatibility**: Includes necessary `i386` libraries to run on 64-bit hosts.
- **AirPrint / Avahi**: Pre-configured for discovery on iOS and macOS.
- **Auto-Start**: Includes a custom entrypoint to ensure the `ccpd` daemon starts with the container.

## 🛠 Prerequisites

1. **Identify the USB Path**: 
   Plug in your printer and run `ls /dev/usb/`. Typically, it is `/dev/usb/lp0`.
2. **Set Host Permissions**:
   On your OMV/Host terminal, run:
   `sudo chmod 666 /dev/usb/lp0`
3. **Driver Files**:
   Place the official Canon `.deb` driver files (Common and CAPT) into a `./drivers` folder before building.

## 📦 Installation

### 1. Clone and Build
```bash
git clone https://github.com/YOUR_USERNAME/canon-lbp3300-docker.git
cd canon-lbp3300-docker
docker-compose up -d --build
```

### 2. Register the Hardware
Because the LBP3300 uses a specialized daemon, you must register the printer inside the container once:

```bash
# Enter the container
docker exec -it cups-canon bash

# Register with CUPS
lpadmin -p LBP3300 -m CNCUPSLBP3300CAPTK.ppd -v ccp://localhost:59687 -E

# Register with the CAPT Daemon
ccpdadmin -p LBP3300 -o /dev/usb/lp0

# Restart the daemon to apply
service ccpd restart
exit
```

## 📱 Enabling AirPrint
1. Navigate to the CUPS Web UI: `http://<your-server-ip>:631`
2. Go to **Printers** > **LBP3300**.
3. Select **Administration** > **Modify Printer**.
4. Follow the prompts and ensure **"Share This Printer"** is checked.
5. Under **Set Default Options**, ensure your Media Size (A4/Letter) is correct.



## 📝 Configuration (docker-compose.yml)
Critical notes for OMV users:
- **Network Mode**: Must be set to `host` for AirPrint discovery.
- **Devices**: You must map `/dev/usb/lp0` so the container can see the physical printer.
- **Volumes**: Mapping `/var/run/dbus` helps resolve color management errors.

## ⚠️ Troubleshooting

### Printer "Processing" but nothing happens
This usually means the `ccpd` daemon has lost its connection. 
- Run `docker exec cups-canon service ccpd status`.
- If it is not running, run `docker exec cups-canon service ccpd restart`.

***
