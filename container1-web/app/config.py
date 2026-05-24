"""
============================================
Flask Configuration
============================================
"""

import os


class Config:
    """Application configuration loaded from environment variables."""

    # Secret key for session management
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-key-change-in-production')

    # Database - SQLAlchemy (prevents SQL injection via parameterized queries)
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://app_user:SecureP@ssw0rd2024@127.0.0.1:5432/secure_app'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_size': 5,
        'max_overflow': 10,
    }

    # Session Security
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    PERMANENT_SESSION_LIFETIME = 1800  # 30 minutes

    # CSRF Protection
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = 3600  # 1 hour

    # Buffer Overflow Protection - Input Limits
    MAX_CONTENT_LENGTH = 1 * 1024 * 1024  # 1MB max request size
    MAX_USERNAME_LENGTH = 50
    MAX_EMAIL_LENGTH = 120
    MAX_PASSWORD_LENGTH = 128
    MAX_FULLNAME_LENGTH = 100
    MAX_BIO_LENGTH = 500
    MAX_TITLE_LENGTH = 200
    MAX_MESSAGE_LENGTH = 2000
