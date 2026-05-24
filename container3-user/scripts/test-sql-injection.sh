#!/bin/bash
# ============================================
# Test: SQL Injection Attacks
# Verifies Snort IPS + Flask protection
# ============================================

WEB_HOST="10.10.10.10"
WEB_URL="https://${WEB_HOST}"

echo "======================================"
echo " Test: SQL Injection Attacks"
echo " Target: $WEB_URL"
echo " Expected: BLOCKED by Snort IPS + Flask"
echo "======================================"
echo ""

# SQL Injection payloads
declare -a PAYLOADS=(
    "' OR '1'='1"
    "' OR 1=1--"
    "admin'--"
    "' UNION SELECT 1,2,3,4,5--"
    "'; DROP TABLE users;--"
    "' OR '1'='1' /*"
    "1; DELETE FROM users"
    "' UNION SELECT username,password FROM users--"
    "admin' AND 1=1--"
    "' INSERT INTO users VALUES('hacker','hack@evil.com','password')--"
)

echo "--- Testing via Login Form ---"
for i in "${!PAYLOADS[@]}"; do
    payload="${PAYLOADS[$i]}"
    echo ""
    echo "[SQLi #$((i+1))] Payload: $payload"
    
    RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        -X POST "$WEB_URL/login" \
        -d "username=${payload}&password=test" \
        --max-time 5 2>/dev/null)
    
    if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "000" ]; then
        echo "  ✅ BLOCKED (HTTP $RESPONSE) - Snort IPS or Flask rejected"
    elif [ "$RESPONSE" = "400" ]; then
        echo "  ✅ BLOCKED (HTTP 400) - Bad request rejected"
    else
        echo "  ⚠️ Response: HTTP $RESPONSE (check if input was sanitized)"
    fi
done

echo ""
echo "--- Testing via URL Query Parameter ---"
URL_PAYLOADS=(
    "/search?q=' OR 1=1--"
    "/search?q=' UNION SELECT 1--"
    "/search?q='; DROP TABLE users--"
)

for payload in "${URL_PAYLOADS[@]}"; do
    echo "[SQLi URL] Payload: $payload"
    RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        "${WEB_URL}${payload}" \
        --max-time 5 2>/dev/null)
    
    if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "000" ]; then
        echo "  ✅ BLOCKED (HTTP $RESPONSE)"
    else
        echo "  ⚠️ Response: HTTP $RESPONSE"
    fi
done

echo ""
echo "--- Testing with sqlmap User-Agent ---"
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "User-Agent: sqlmap/1.7" \
    "$WEB_URL/" \
    --max-time 5 2>/dev/null)
echo "[SQLi Tool] sqlmap User-Agent: HTTP $RESPONSE"
if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "000" ]; then
    echo "  ✅ BLOCKED - sqlmap detected by Snort"
else
    echo "  ⚠️ Not blocked at network level"
fi

echo ""
echo "======================================"
echo " SQL Injection Tests Complete"
echo " Check Snort alerts: docker exec snort-ids-ips cat /var/log/snort/alert_fast.txt"
echo "======================================"
