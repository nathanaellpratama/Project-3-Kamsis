#!/bin/bash
# ============================================
# Test: Buffer Overflow Attempts
# Verifies Nginx + Flask input limits
# ============================================

WEB_HOST="10.10.10.10"
WEB_URL="https://${WEB_HOST}"

echo "======================================"
echo " Test: Buffer Overflow Attempts"
echo " Target: $WEB_URL"
echo " Expected: REJECTED by Nginx/Flask"
echo "======================================"
echo ""

# Test 1: Oversized URL (>2048 chars)
echo "[TEST 1] Oversized URL (3000 chars)..."
LONG_PARAM=$(python3 -c "print('A' * 3000)")
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    "${WEB_URL}/search?q=${LONG_PARAM}" \
    --max-time 5 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
if [ "$RESPONSE" = "414" ] || [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "413" ]; then
    echo "  ✅ BLOCKED - Oversized URL rejected"
else
    echo "  ⚠️ Check if input was truncated"
fi

# Test 2: Oversized POST body (>1MB)
echo ""
echo "[TEST 2] Oversized POST body (2MB)..."
LARGE_DATA=$(python3 -c "print('B' * 2097152)")
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -X POST "$WEB_URL/login" \
    -d "username=${LARGE_DATA}" \
    --max-time 10 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
if [ "$RESPONSE" = "413" ] || [ "$RESPONSE" = "000" ]; then
    echo "  ✅ BLOCKED - Oversized body rejected (413 Request Entity Too Large)"
else
    echo "  ⚠️ Response: HTTP $RESPONSE"
fi

# Test 3: Long username (>50 chars)
echo ""
echo "[TEST 3] Long username (500 chars)..."
LONG_USER=$(python3 -c "print('C' * 500)")
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -X POST "$WEB_URL/login" \
    -d "username=${LONG_USER}&password=test" \
    --max-time 5 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
if [ "$RESPONSE" = "403" ] || [ "$RESPONSE" = "400" ]; then
    echo "  ✅ BLOCKED - Long username rejected"
else
    echo "  ℹ️ Flask should validate and reject on server side"
fi

# Test 4: Oversized HTTP headers
echo ""
echo "[TEST 4] Oversized HTTP headers (10KB header)..."
LONG_HEADER=$(python3 -c "print('D' * 10240)")
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "X-Custom-Header: ${LONG_HEADER}" \
    "$WEB_URL/" \
    --max-time 5 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
if [ "$RESPONSE" = "431" ] || [ "$RESPONSE" = "400" ] || [ "$RESPONSE" = "494" ]; then
    echo "  ✅ BLOCKED - Oversized header rejected"
else
    echo "  ⚠️ Response: HTTP $RESPONSE"
fi

# Test 5: Long password (>128 chars)
echo ""
echo "[TEST 5] Long password (1000 chars)..."
LONG_PASS=$(python3 -c "print('E' * 1000)")
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -X POST "$WEB_URL/register" \
    -d "username=buftest&email=buf@test.com&password=${LONG_PASS}&confirm_password=${LONG_PASS}" \
    --max-time 5 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
echo "  ℹ️ Flask validates max 128 chars for password"

# Test 6: Null byte injection
echo ""
echo "[TEST 6] Null byte injection..."
RESPONSE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -X POST "$WEB_URL/login" \
    -d "username=admin%00&password=test" \
    --max-time 5 2>/dev/null)
echo "  Response: HTTP $RESPONSE"
echo "  ℹ️ Null bytes are stripped by security middleware"

echo ""
echo "======================================"
echo " Buffer Overflow Tests Complete"
echo "======================================"
