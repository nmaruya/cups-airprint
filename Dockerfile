# Use Ubuntu as the base for better driver compatibility
FROM ubuntu:22.04

# Prevent interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# 1. Add 32-bit architecture and install dependencies
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y \
    cups \
    cups-filters \
    libcups2:i386 \
    libstdc++6:i386 \
    libxml2:i386 \
    libc6:i386 \
    libpopt0:i386 \
    avahi-daemon \
    dbus \
    libatk1.0-0:i386 \
    libgtk2.0-0:i386 \
    libgdk-pixbuf2.0-0:i386 \
    && apt-get clean

# 2. Copy the Canon Driver .deb files from your local 'drivers' folder
# Make sure you have the 'common' and 'capt' deb files in your repo
COPY drivers/*.deb /tmp/

# 3. Install the drivers (Common first, then CAPT)
RUN dpkg -i /tmp/cndrvcups-common*.deb || apt-get install -f -y
RUN dpkg -i /tmp/cndrvcups-capt*.deb || apt-get install -f -y

# 4. Configure CUPS to allow remote access
RUN cupsd && \
    cupsctl --remote-admin --remote-any --share-printers && \
    killall cupsd

# 5. Copy and set permissions for the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Standard CUPS port
EXPOSE 631

ENTRYPOINT ["/entrypoint.sh"]
