#!/bin/bash
# ============================================
# Entrypoint for Container 1: Web + DB
# Initializes PostgreSQL, then starts supervisord
# ============================================

set -e

echo "======================================"
echo " Container 1: Web + DB Starting..."
echo "======================================"

# ---- PostgreSQL Initialization ----
echo "[DB] Initializing PostgreSQL..."

# Start PostgreSQL
su - postgres -c "pg_ctlcluster 15 main start" 2>/dev/null || \
su - postgres -c "pg_ctlcluster 14 main start" 2>/dev/null || {
    # Fallback: initialize and start manually
    PG_VERSION=$(ls /usr/lib/postgresql/ | head -1)
    PG_DATA="/var/lib/postgresql/${PG_VERSION}/main"
    
    if [ ! -f "$PG_DATA/PG_VERSION" ]; then
        echo "[DB] Initializing database cluster..."
        su - postgres -c "/usr/lib/postgresql/${PG_VERSION}/bin/initdb -D $PG_DATA"
    fi
    
    # Configure PostgreSQL to accept local connections
    echo "local all all trust" > "$PG_DATA/pg_hba.conf"
    echo "host all all 127.0.0.1/32 md5" >> "$PG_DATA/pg_hba.conf"
    echo "host all all ::1/128 md5" >> "$PG_DATA/pg_hba.conf"
    
    # Set listen address
    echo "listen_addresses = '127.0.0.1'" >> "$PG_DATA/postgresql.conf"
    
    su - postgres -c "/usr/lib/postgresql/${PG_VERSION}/bin/pg_ctl -D $PG_DATA -l /var/log/postgresql/postgresql.log start"
}

# Wait for PostgreSQL to be ready
echo "[DB] Waiting for PostgreSQL to be ready..."
for i in $(seq 1 30); do
    if su - postgres -c "psql -c 'SELECT 1'" > /dev/null 2>&1; then
        echo "[DB] PostgreSQL is ready!"
        break
    fi
    echo "[DB] Waiting... ($i/30)"
    sleep 1
done

# Run initialization SQL
echo "[DB] Running initialization scripts..."
su - postgres -c "psql -f /docker-entrypoint-initdb.d/init.sql" 2>/dev/null || true

echo "[DB] Database initialization complete."

# ---- Start Supervisord (Nginx + Gunicorn) ----
echo "[APP] Starting application services..."
exec "$@"
