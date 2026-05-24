"""
============================================
Flask Application Factory
Container 1: Web Application
============================================
Security Features:
- HTTPS enforcement
- CSRF protection
- XSS protection via CSP headers
- SQL injection prevention via SQLAlchemy ORM
- Buffer overflow prevention via input limits
- Secure session management
============================================
"""

import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_wtf.csrf import CSRFProtect
from flask_talisman import Talisman
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Initialize extensions
db = SQLAlchemy()
login_manager = LoginManager()
csrf = CSRFProtect()


def create_app():
    """Application factory pattern."""
    app = Flask(__name__)

    # Load configuration
    app.config.from_object('app.config.Config')

    # ---- Initialize Extensions ----

    # Database (SQLAlchemy - prevents SQL Injection)
    db.init_app(app)

    # Login Manager
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = 'Please log in to access this page.'
    login_manager.session_protection = 'strong'

    # CSRF Protection
    csrf.init_app(app)

    # Content Security Policy (XSS Protection)
    csp = {
        'default-src': "'self'",
        'script-src': "'self'",
        'style-src': "'self' 'unsafe-inline'",
        'img-src': "'self' data:",
        'font-src': "'self'",
        'frame-ancestors': "'none'",
        'form-action': "'self'",
    }

    # Talisman - Security headers & HTTPS enforcement
    Talisman(
        app,
        force_https=False,  # Nginx handles HTTPS
        strict_transport_security=True,
        session_cookie_secure=True,
        session_cookie_http_only=True,
        content_security_policy=csp,
        content_security_policy_nonce_in=['script-src'],
    )

    # Rate Limiter
    Limiter(
        app=app,
        key_func=get_remote_address,
        default_limits=["200 per day", "50 per hour"],
        storage_uri="memory://",
    )

    # ---- Security Middleware ----
    from app.security import register_security_middleware
    register_security_middleware(app)

    # ---- Register Blueprints ----
    from app.auth import auth_bp
    from app.routes import main_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(main_bp)

    # ---- Create Database Tables ----
    with app.app_context():
        from app import models  # noqa: F401
        db.create_all()

    return app
