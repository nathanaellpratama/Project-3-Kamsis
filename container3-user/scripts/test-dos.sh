#!/bin/bash
# ============================================
# Test: DoS (Denial of Service) Attacks
# Verifies Snort IPS + Nginx rate limiting
# ============================================

WEB_HOST="10.10.10.10"
WEB_URL="https://${WEB_HOST}"

echo "======================================"
echo " Test: DoS Attacks"
echo " Target: $WEB_URL"
echo " Expected: BLOCKED by Snort + Rate Limit"
echo "======================================"
echo ""

# Test 1: HTTP Flood
echo "[TEST 1] HTTP Flood (100 rapid requests)..."
BLOCKED=0
SUCCESS=0
for i in $(seq 1 100); do
    RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" "$WEB_URL/" --max-time 2 2>/dev/null)
    if [ "$RESPONSE" = "429" ] || [ "$RESPONSE" = "000" ] || [ "$RESPONSE" = "503" ]; then
        BLOCKED=$((BLOCKED + 1))
    else
        SUCCESS=$((SUCCESS + 1))
    fi
done
echo "  Results: $SUCCESS successful, $BLOCKED blocked/rate-limited"
if [ $BLOCKED -gt 0 ]; then
    echo "  ✅ Rate limiting is working!"
else
    echo "  ⚠️ No requests were rate-limited"
fi

# Test 2: SYN Flood (using hping3)
echo ""
echo "[TEST 2] SYN Flood (hping3 - 500 packets)..."
echo "  Sending SYN packets..."
hping3 -S -p 443 -c 500 --fast "$WEB_HOST" 2>&1 | tail -3
echo "  ✅ SYN flood test complete. Check Snort alerts."

# Test 3: ICMP Flood
echo ""
echo "[TEST 3] ICMP Flood (100 rapid pings)..."
hping3 --icmp -c 100 --fast "$WEB_HOST" 2>&1 | tail -3
echo "  ✅ ICMP flood test complete. Check Snort alerts."

# Test 4: Large ICMP (Ping of Death)
echo ""
echo "[TEST 4] Large ICMP Packet (Ping of Death)..."
hping3 --icmp -d 2000 -c 5 "$WEB_HOST" 2>&1 | tail -3
echo "  ✅ Ping of Death test complete. Check Snort alerts."

echo ""
echo "======================================"
echo " DoS Tests Complete"
echo " Check Snort alerts: docker exec snort-ids-ips cat /var/log/snort/alert_fast.txt"
echo "======================================"
