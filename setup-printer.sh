
#!/bin/bash
sleep 10
# 1. Register the printer in CUPS
lpadmin -p LBP3300 -m CNCUPSLBP3300CAPTK.ppd -v ccp://localhost:59687 -E
# 2. Map the CAPT driver to your Network IP
ccpdadmin -p LBP3300 -o net:192.168.1.252
# 3. Start the Canon background service
service ccpd restart
echo "Canon LBP3300 setup script finished."
EOF