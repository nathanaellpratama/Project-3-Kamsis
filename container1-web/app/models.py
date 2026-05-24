"""
============================================
Database Models
Proteksi: Hash+Salt (bcrypt), Input Length Limits
============================================
"""

from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from app import db, login_manager


class User(UserMixin, db.Model):
    """User model with bcrypt password hashing (hash + salt)."""

    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    # Input length constraints prevent buffer overflow
    username = db.Column(db.String(50), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    # Werkzeug uses pbkdf2:sha256 with salt by default (can also use bcrypt)
    password_hash = db.Column(db.String(256), nullable=False)
    full_name = db.Column(db.String(100))
    bio = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    login_attempts = db.Column(db.Integer, default=0)
    last_login = db.Column(db.DateTime)

    # Relationships
    messages = db.relationship('Message', backref='author', lazy='dynamic',
                               cascade='all, delete-orphan')

    def set_password(self, password):
        """
        Hash password using pbkdf2:sha256 with automatic salt.
        Werkzeug generates a unique salt for each password.
        Format: method$salt$hash
        """
        self.password_hash = generate_password_hash(
            password,
            method='pbkdf2:sha256',
            salt_length=16
        )

    def check_password(self, password):
        """Verify password against stored hash+salt."""
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'


class LoginLog(db.Model):
    """Login audit log for security monitoring."""

    __tablename__ = 'login_logs'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50))
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.String(512))
    success = db.Column(db.Boolean)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<LoginLog {self.username} {"OK" if self.success else "FAIL"}>'


class Message(db.Model):
    """Message model for testing XSS protection."""

    __tablename__ = 'messages'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'),
                        nullable=False)
    # Length constraints for buffer overflow protection
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Message {self.title}>'


@login_manager.user_loader
def load_user(user_id):
    """Load user by ID for Flask-Login session management."""
    return User.query.get(int(user_id))
