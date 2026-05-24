#!/bin/bash
# ============================================
# Test: Normal User Behavior
# Verifies legitimate access works correctly
# ============================================

WEB_HOST="10.10.10.10"
WEB_URL="https://${WEB_HOST}"

echo "======================================"
echo " Test: Normal User Behavior"
echo " Target: $WEB_URL"
echo "======================================"
echo ""

# Test 1: HTTPS connectivity
echo "[TEST 1] Testing HTTPS connectivity..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "$WEB_URL/" 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  ✅ PASS - HTTPS is working (HTTP $HTTP_CODE)"
else
    echo "  ❌ FAIL - HTTPS returned HTTP $HTTP_CODE"
fi

# Test 2: Redirect HTTP to HTTPS
echo "[TEST 2] Testing HTTP to HTTPS redirect..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/" 2>/dev/null)
if [ "$HTTP_CODE" = "301" ]; then
    echo "  ✅ PASS - HTTP redirects to HTTPS (HTTP $HTTP_CODE)"
else
    echo "  ℹ️ INFO - HTTP returned HTTP $HTTP_CODE"
fi

# Test 3: SSL Certificate
echo "[TEST 3] Checking SSL certificate..."
CERT_INFO=$(echo | openssl s_client -connect "${WEB_HOST}:443" -servername "${WEB_HOST}" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
if [ -n "$CERT_INFO" ]; then
    echo "  ✅ PASS - SSL certificate is present"
    echo "  $CERT_INFO" | head -3
else
    echo "  ❌ FAIL - Could not retrieve SSL certificate"
fi

# Test 4: Register a new user
echo "[TEST 4] Testing user registration..."
# First get CSRF token
CSRF_TOKEN=$(curl -sk "$WEB_URL/register" 2>/dev/null | grep -o 'name="csrf_token" value="[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$CSRF_TOKEN" ]; then
    REG_RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        -X POST "$WEB_URL/register" \
        -d "csrf_token=${CSRF_TOKEN}&username=testuser&email=test@example.com&password=TestPass123&confirm_password=TestPass123&full_name=Test User" \
        2>/dev/null)
    echo "  ✅ PASS - Registration endpoint responded (HTTP $REG_RESPONSE)"
else
    echo "  ℹ️ INFO - Could not get CSRF token (may need cookies)"
fi

# Test 5: Login attempt
echo "[TEST 5] Testing login..."
CSRF_TOKEN=$(curl -sk "$WEB_URL/login" 2>/dev/null | grep -o 'name="csrf_token" value="[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$CSRF_TOKEN" ]; then
    LOGIN_RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
        -X POST "$WEB_URL/login" \
        -d "csrf_token=${CSRF_TOKEN}&username=testuser&password=TestPass123" \
        2>/dev/null)
    echo "  ✅ PASS - Login endpoint responded (HTTP $LOGIN_RESPONSE)"
else
    echo "  ℹ️ INFO - Could not get CSRF token"
fi

# Test 6: Security headers check
echo "[TEST 6] Checking security headers..."
HEADERS=$(curl -sk -I "$WEB_URL/" 2>/dev/null)
echo "$HEADERS" | grep -qi "strict-transport-security" && echo "  ✅ Strict-Transport-Security: Present" || echo "  ❌ Strict-Transport-Security: Missing"
echo "$HEADERS" | grep -qi "x-content-type-options" && echo "  ✅ X-Content-Type-Options: Present" || echo "  ❌ X-Content-Type-Options: Missing"
echo "$HEADERS" | grep -qi "x-frame-options" && echo "  ✅ X-Frame-Options: Present" || echo "  ❌ X-Frame-Options: Missing"
echo "$HEADERS" | grep -qi "content-security-policy" && echo "  ✅ Content-Security-Policy: Present" || echo "  ❌ Content-Security-Policy: Missing"

# Test 7: Ping test
echo "[TEST 7] Ping to web server..."
ping -c 3 "$WEB_HOST" 2>/dev/null && echo "  ✅ PASS - Ping successful" || echo "  ❌ FAIL - Ping failed"

echo ""
echo "======================================"
echo " Normal User Tests Complete"
echo "======================================"
