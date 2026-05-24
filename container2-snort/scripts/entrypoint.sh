#!/bin/bash
# ============================================
# Entrypoint - Container 2: Snort IDS/IPS
# Sets up iptables, ACL, and starts Snort
# ============================================

set -e

echo "======================================"
echo " Container 2: Snort IDS/IPS Starting"
echo "======================================"

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "[NET] IP forwarding enabled"

# Setup iptables and ACL rules
echo "[FW] Setting up iptables and ACL rules..."
/opt/scripts/setup-iptables.sh

# Setup ACL rules
echo "[ACL] Setting up Access Control Lists..."
/opt/acl/acl-rules.sh

# Ensure log directory exists
mkdir -p /var/log/snort
touch /var/log/snort/alert_fast.txt
chmod 666 /var/log/snort/alert_fast.txt

# Validate Snort configuration
echo "[SNORT] Validating configuration..."
snort -c /etc/snort/config/snort.lua \
    --plugin-path /usr/local/lib/snort/plugins \
    -T 2>&1 | tail -5 || {
    echo "[SNORT] WARNING: Config validation had issues, attempting to start anyway..."
}

echo "======================================"
echo " Starting Snort 3 in IDS/IPS Mode"
echo " Mode: Inline (NFQUEUE)"
echo " Rules: Local + Community + Custom"
echo "======================================"

# Start Snort in inline IPS mode with NFQUEUE
exec snort \
    -c /etc/snort/config/snort.lua \
    --plugin-path /usr/local/lib/snort/plugins \
    --daq nfq \
    --daq-var queue=1 \
    -Q \
    -A alert_fast \
    -l /var/log/snort \
    -k none \
    --lua "include '/etc/snort/config/snort_defaults.lua'" \
    2>&1
