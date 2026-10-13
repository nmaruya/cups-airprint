FROM debian:buster-slim

# 1. Archive & 32-bit Setup
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    echo 'APT::Get::AllowUnauthenticated "true";' >> /etc/apt/apt.conf.d/99no-check-valid-until && \
    sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

# 2. Comprehensive 32-bit Library Install
RUN dpkg --add-architecture i386 && \
    apt-get update -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true && \
    apt-get install -y --allow-unauthenticated \
    cups cups-filters libcups2-dev \
    libxml2:i386 libstdc++6:i386 libgcc1:i386 libc6:i386 \
    wget psmisc iputils-ping \
    libatk1.0-0:i386 libglade2-0:i386 libgtk2.0-0:i386 \
    libpopt0:i386 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# 3. Manual Extraction & Backend Setup
COPY linux-capt-drv-v271-uken.tar.gz /tmp/
RUN tar -xf /tmp/linux-capt-drv-v271-uken.tar.gz -C /tmp/ && \
    cd /tmp/linux-capt-drv-v271-uken/64-bit_Driver/Debian/ && \
    dpkg-deb -x cndrvcups-common_3.21-1_amd64.deb / && \
    dpkg-deb -x cndrvcups-capt_2.71-1_amd64.deb / && \
    chmod 755 /usr/lib/cups/backend/ccp && \
    rm -rf /tmp/linux-capt-drv-v271-uken*

# 4. Pre-configure CUPS for Network/AirPrint
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All/' /etc/cups/cupsd.conf

# 5. Startup Script
RUN echo '#!/bin/bash\n\
mkdir -p /var/log/cups && touch /var/log/cups/error_log\n\
\n\
# Fix CUPS daemon and library permissions\n\
chmod -R 755 /usr/lib/cups\n\
chown -R root:root /usr/lib/cups\n\
\n\
# Initialize spooler and temporary directory permissions for user lp\n\
mkdir -p /var/spool/cups/tmp /tmp\n\
chown -R lp:lp /var/spool/cups /tmp\n\
chmod 777 /var/spool/cups /var/spool/cups/tmp /tmp\n\
chmod -s /var/spool/cups/tmp 2>/dev/null || true\n\
\n\
/usr/sbin/cupsd\n\
sleep 5\n\
\n\
# Clean up old printer registration to avoid conflicts\n\
lpadmin -x Canon_LBP3300 >/dev/null 2>&1\n\
\n\
# Setup Canon communication pipes\n\
mkdir -p /var/ccpd /var/captmon\n\
rm -f /var/ccpd/fifo0 && mkfifo /var/ccpd/fifo0\n\
chown -R root:lp /var/ccpd\n\
\n\
# REGISTER: 1. Tell CUPS about the printer\n\
lpadmin -p Canon_LBP3300 -m CNCUPSLBP3300CAPTK.ppd -v ccp://localhost:59687 -E\n\
\n\
# REGISTER: 2. Tell the Canon Daemon where the printer is on the network\n\
ccpdadmin -p Canon_LBP3300 -o net:192.168.1.252\n\
\n\
# START: The translation daemon\n\
/etc/init.d/ccpd restart\n\
echo "Setup finished. Printing status..."\n\
ccpdadmin\n\
tail -f /var/log/cups/error_log' > /start-everything.sh

RUN chmod +x /start-everything.sh
ENTRYPOINT ["/start-everything.sh"]
