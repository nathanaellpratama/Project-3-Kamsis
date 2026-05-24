#!/bin/bash
# ============================================
# Test: XSS (Cross-Site Scripting) Attacks
# Verifies Snort IPS + Flask XSS protection
# ============================================

WEB_HOST="10.10.10.10"
WEB_URL="https://${WEB_HOST}"

echo "======================================"
echo " Test: XSS Attacks"
echo " Target: $WEB_URL"
echo " Expected: BLOCKED by Snort IPS + Flask"
echo "======================================"
echo ""

declare -a XSS_PAYLOADS=(
    "<script>alert('XSS')</script>"
    "<img src=x onerror=alert('XSS')>"
    "<svg onload=alert('XSS')>"
    "javascript:alert('XSS')"
    "<body onload=alert('XSS')>"
    "<img src=x onerror=document.cookie>"
    "'\"><script>alert(String.fromCharCode(88,83,83))</script>"
    "<iframe src=javascript:alert('XSS')>"
    "<div onmouseover=alert('XSS')>hover me</div>"
    "eval('alert(1)')"
)

echo "--- Testing XSS via POST (Message Form) ---"
for i in "${!XSS_PAYLOADS[@]}"; do
    payload="${XSS_PAYLOADS[$i]}"
    echo ""
    echo "[XSS #$((i+1))] Payload: $payload"
    
    RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        -X POST "$WEB_URL/messages" \
        -d "title=XSS+Test&content=${payload}" \
        --max-time 5 2>/dev/null)
    
    if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "000" ]; then
        echo "  ✅ BLOCKED (HTTP $RESPONSE) - Snort IPS blocked"
    elif [ "$RESPONSE" = "400" ]; then
        echo "  ✅ BLOCKED (HTTP 400) - Flask rejected"
    else
        echo "  ⚠️ Response: HTTP $RESPONSE (content should be sanitized by bleach)"
    fi
done

echo ""
echo "--- Testing XSS via URL Parameter ---"
for i in "${!XSS_PAYLOADS[@]}"; do
    payload="${XSS_PAYLOADS[$i]}"
    ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$payload'))" 2>/dev/null || echo "$payload")
    
    RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        "${WEB_URL}/search?q=${ENCODED}" \
        --max-time 5 2>/dev/null)
    
    if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "000" ]; then
        echo "[XSS URL #$((i+1))] ✅ BLOCKED (HTTP $RESPONSE)"
    else
        echo "[XSS URL #$((i+1))] Response: HTTP $RESPONSE"
    fi
done

echo ""
echo "======================================"
echo " XSS Tests Complete"
echo " Check Snort alerts: docker exec snort-ids-ips cat /var/log/snort/alert_fast.txt"
echo "======================================"
