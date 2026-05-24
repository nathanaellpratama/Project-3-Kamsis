#!/bin/bash
# ============================================
# ACL (Access Control List) Rules
# Network-level access control using iptables
# ============================================

echo "[ACL] Configuring Access Control Lists..."

# ---- ACL Rule 1: Allow only HTTPS (port 443) from User to Web ----
# Only allow HTTPS traffic to reach the web server
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p tcp --dport 80 -j ACCEPT
echo "[ACL] Rule 1: Allow HTTP/HTTPS from User to Web"

# ---- ACL Rule 2: Block direct database access ----
# Prevent User from accessing PostgreSQL directly
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p tcp --dport 5432 -j DROP
echo "[ACL] Rule 2: Block direct PostgreSQL access (port 5432)"

# ---- ACL Rule 3: Block SSH access to web server ----
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p tcp --dport 22 -j DROP
echo "[ACL] Rule 3: Block SSH access to web server"

# ---- ACL Rule 4: Allow ICMP (ping) for testing ----
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p icmp -j ACCEPT
echo "[ACL] Rule 4: Allow ICMP between containers"

# ---- ACL Rule 5: Rate limit new connections ----
# Limit new TCP connections to 25 per second per source IP
iptables -A FORWARD -s 10.10.10.30 -d 10.10.10.10 -p tcp --syn \
    -m limit --limit 25/second --limit-burst 50 -j ACCEPT
echo "[ACL] Rule 5: Rate limit new TCP connections (25/sec)"

# ---- ACL Rule 6: Drop invalid packets ----
iptables -A FORWARD -m state --state INVALID -j DROP
echo "[ACL] Rule 6: Drop invalid packets"

# ---- ACL Rule 7: Log dropped packets ----
iptables -A FORWARD -j LOG --log-prefix "[ACL-DROP] " --log-level 4
echo "[ACL] Rule 7: Log dropped packets"

echo "[ACL] Access Control Lists configured."
echo "[ACL] Summary:"
echo "  - HTTPS/HTTP: ALLOWED"
echo "  - PostgreSQL: BLOCKED"
echo "  - SSH:        BLOCKED"
echo "  - ICMP:       ALLOWED"
echo "  - Rate Limit: 25 conn/sec"
echo "  - Invalid:    DROPPED"
