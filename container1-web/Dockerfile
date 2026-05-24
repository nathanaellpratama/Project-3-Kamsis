# ============================================
# Container 1: Flask Web App + PostgreSQL + Nginx
# Multi-service container using supervisord
# ============================================
FROM python:3.11-slim AS base

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql \
    postgresql-client \
    nginx \
    supervisor \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user (non-root)
RUN useradd -m -s /bin/bash appuser

# Setup Python dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ /app/app/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY init-db/init.sql /docker-entrypoint-initdb.d/init.sql
COPY certs/generate-certs.sh /app/generate-certs.sh

# Generate self-signed SSL certificates
RUN chmod +x /app/generate-certs.sh && /app/generate-certs.sh

# Create necessary directories
RUN mkdir -p /var/log/supervisor /var/run/postgresql /var/log/nginx \
    && chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql \
    && chown -R appuser:appuser /app

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
