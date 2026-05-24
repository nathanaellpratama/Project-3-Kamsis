-- ============================================
-- Database Initialization Script
-- Container 1: PostgreSQL Setup
-- ============================================

-- Create application user with limited privileges
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN PASSWORD 'SecureP@ssw0rd2024';
    END IF;
END
$$;

-- Create database
SELECT 'CREATE DATABASE secure_app OWNER app_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'secure_app')\gexec

-- Connect to the database
\c secure_app

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(256) NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    login_attempts INTEGER DEFAULT 0,
    last_login TIMESTAMP
);

-- Create login_logs table for security auditing
CREATE TABLE IF NOT EXISTS login_logs (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    ip_address VARCHAR(45),
    user_agent VARCHAR(512),
    success BOOLEAN,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create messages table (for testing XSS protection)
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grant minimal privileges to app_user (Principle of Least Privilege)
GRANT CONNECT ON DATABASE secure_app TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO app_user;

-- Revoke dangerous privileges
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
