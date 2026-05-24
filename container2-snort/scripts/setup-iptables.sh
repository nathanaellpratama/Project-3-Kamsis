#!/bin/bash
# ============================================
# IPTables + NFQUEUE Setup
# Routes traffic through Snort IPS
# ============================================

echo "[FW] Configuring iptables for Snort IPS..."

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# ---- NFQUEUE Rules (Send traffic to Snort for inspection) ----

# Forward all traffic between User (10.10.10.30) and Web (10.10.10.10) through NFQUEUE
# This allows Snort to inspect and potentially block malicious traffic

# User -> Web (inbound to web server)
iptables -I FORWARD -s 10.10.10.30 -d 10.10.10.10 -j NFQUEUE --queue-num 1 --queue-bypass
echo "[FW] Rule: User -> Web traffic -> NFQUEUE 1"

# Web -> User (response traffic)
iptables -I FORWARD -s 10.10.10.10 -d 10.10.10.30 -j NFQUEUE --queue-num 1 --queue-bypass
echo "[FW] Rule: Web -> User traffic -> NFQUEUE 1"

# ---- Allow essential traffic ----

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow ICMP (for ping testing)
iptables -A INPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT

# ---- Connection tracking ----
# Enable connection tracking for better performance
modprobe nf_conntrack 2>/dev/null || true
modprobe nfnetlink_queue 2>/dev/null || true

echo "[FW] IPTables configuration complete."
echo "[FW] Current rules:"
iptables -L -n -v --line-numbers 2>/dev/null | head -30
