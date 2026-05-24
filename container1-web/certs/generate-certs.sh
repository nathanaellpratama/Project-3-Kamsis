#!/bin/bash
# ============================================
# Generate Self-Signed RSA SSL Certificate
# For HTTPS on the web server
# ============================================

CERT_DIR="/etc/nginx/certs"
mkdir -p "$CERT_DIR"

# Check if certificates already exist
if [ -f "$CERT_DIR/server.crt" ] && [ -f "$CERT_DIR/server.key" ]; then
    echo "[SSL] Certificates already exist, skipping generation."
    exit 0
fi

echo "[SSL] Generating self-signed RSA SSL certificate..."

# Generate RSA private key (2048-bit)
openssl genrsa -out "$CERT_DIR/server.key" 2048

# Generate self-signed certificate (valid for 365 days)
openssl req -new -x509 \
    -key "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt" \
    -days 365 \
    -subj "/C=ID/ST=West Java/L=Bandung/O=Telkom University/OU=Security Lab/CN=secure-web.local"

# Set proper permissions
chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo "[SSL] Certificate generated successfully."
echo "[SSL] Certificate: $CERT_DIR/server.crt"
echo "[SSL] Key: $CERT_DIR/server.key"
