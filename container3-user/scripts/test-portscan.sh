#!/bin/bash
# ============================================
# Test: Port Scanning
# Verifies Snort IDS detection
# ============================================

WEB_HOST="10.10.10.10"

echo "======================================"
echo " Test: Port Scanning"
echo " Target: $WEB_HOST"
echo " Expected: DETECTED by Snort IDS"
echo "======================================"
echo ""

# Test 1: SYN Scan
echo "[TEST 1] Nmap SYN Scan (top 100 ports)..."
nmap -sS -T4 --top-ports 100 "$WEB_HOST" 2>/dev/null
echo "  ✅ SYN scan complete."

# Test 2: FIN Scan
echo ""
echo "[TEST 2] Nmap FIN Scan..."
nmap -sF -T4 --top-ports 20 "$WEB_HOST" 2>/dev/null
echo "  ✅ FIN scan complete."

# Test 3: XMAS Scan
echo ""
echo "[TEST 3] Nmap XMAS Scan..."
nmap -sX -T4 --top-ports 20 "$WEB_HOST" 2>/dev/null
echo "  ✅ XMAS scan complete."

# Test 4: NULL Scan
echo ""
echo "[TEST 4] Nmap NULL Scan..."
nmap -sN -T4 --top-ports 20 "$WEB_HOST" 2>/dev/null
echo "  ✅ NULL scan complete."

# Test 5: Version Detection
echo ""
echo "[TEST 5] Nmap Version Detection..."
nmap -sV -T4 -p 80,443 "$WEB_HOST" 2>/dev/null
echo "  ✅ Version detection complete."

# Test 6: Aggressive scan
echo ""
echo "[TEST 6] Nmap Aggressive Scan..."
nmap -A -T4 -p 80,443 "$WEB_HOST" 2>/dev/null
echo "  ✅ Aggressive scan complete."

echo ""
echo "======================================"
echo " Port Scan Tests Complete"
echo " Check Snort alerts: docker exec snort-ids-ips cat /var/log/snort/alert_fast.txt"
echo "======================================"
