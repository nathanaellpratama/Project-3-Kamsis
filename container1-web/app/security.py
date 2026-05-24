"""
============================================
Security Middleware & Utilities
Proteksi: XSS, Buffer Overflow, Input Validation
============================================
"""

import re
import bleach
from flask import request, abort


# ---- Allowed HTML tags for bleach sanitizer ----
ALLOWED_TAGS = []  # No HTML tags allowed (strip all)
ALLOWED_ATTRIBUTES = {}
ALLOWED_PROTOCOLS = ['https']


def sanitize_input(text):
    """
    Sanitize user input to prevent XSS attacks.
    Strips all HTML tags and dangerous content.
    """
    if not text:
        return text

    # Strip all HTML tags using bleach
    cleaned = bleach.clean(
        text,
        tags=ALLOWED_TAGS,
        attributes=ALLOWED_ATTRIBUTES,
        protocols=ALLOWED_PROTOCOLS,
        strip=True
    )

    # Remove null bytes (buffer overflow attempt)
    cleaned = cleaned.replace('\x00', '')

    return cleaned


def validate_input(value, input_type='text'):
    """
    Validate input based on type.
    Returns True if valid, False if not.
    """
    if not value:
        return False

    if input_type == 'username':
        # Only alphanumeric and underscore, 1-50 chars
        return bool(re.match(r'^[a-zA-Z0-9_]{1,50}$', value))

    elif input_type == 'email':
        # Basic email validation
        return bool(re.match(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', value))

    elif input_type == 'text':
        # General text - check for dangerous patterns
        dangerous_patterns = [
            r'<script',
            r'javascript:',
            r'on\w+\s*=',
            r'eval\s*\(',
            r'expression\s*\(',
            r'url\s*\(',
        ]
        text_lower = value.lower()
        for pattern in dangerous_patterns:
            if re.search(pattern, text_lower):
                return False
        return True

    return True


def check_sql_injection(value):
    """
    Additional SQL injection pattern detection.
    Note: SQLAlchemy ORM already prevents SQL injection via parameterized queries.
    This is a defense-in-depth measure.
    """
    if not value:
        return False

    sql_patterns = [
        r"('\s*(OR|AND)\s+')",
        r"(UNION\s+SELECT)",
        r"(DROP\s+TABLE)",
        r"(INSERT\s+INTO)",
        r"(DELETE\s+FROM)",
        r"(UPDATE\s+\w+\s+SET)",
        r"(;\s*DROP)",
        r"(;\s*DELETE)",
        r"(;\s*UPDATE)",
        r"(;\s*INSERT)",
        r"(--\s*$)",
        r"(/\*.*\*/)",
        r"(EXEC\s+)",
        r"(xp_\w+)",
        r"(0x[0-9a-fA-F]+)",
    ]

    value_upper = value.upper()
    for pattern in sql_patterns:
        if re.search(pattern, value_upper, re.IGNORECASE):
            return True

    return False


def register_security_middleware(app):
    """Register security middleware with the Flask app."""

    @app.before_request
    def security_checks():
        """Run security checks on every request."""

        # ---- Buffer Overflow Protection ----
        # Check Content-Length header
        content_length = request.content_length
        if content_length and content_length > 1 * 1024 * 1024:  # 1MB
            abort(413)

        # Check URL length
        if len(request.url) > 2048:
            abort(414)

        # Check header sizes
        for header_name, header_value in request.headers:
            if len(str(header_value)) > 8192:
                abort(431)

        # ---- SQL Injection Detection (Defense in Depth) ----
        # Check query parameters
        for key, value in request.args.items():
            if check_sql_injection(value):
                abort(403)

        # Check form data
        if request.method == 'POST':
            for key, value in request.form.items():
                if isinstance(value, str) and check_sql_injection(value):
                    abort(403)

    @app.after_request
    def add_security_headers(response):
        """Add additional security headers to every response."""
        # XSS Protection
        response.headers['X-XSS-Protection'] = '1; mode=block'
        # Prevent MIME type sniffing
        response.headers['X-Content-Type-Options'] = 'nosniff'
        # Prevent clickjacking
        response.headers['X-Frame-Options'] = 'DENY'
        # Referrer Policy
        response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        # Remove server header
        response.headers.pop('Server', None)

        return response
