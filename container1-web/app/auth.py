"""
============================================
Authentication Routes
Proteksi: Hash+Salt, SQL Injection, Brute Force
============================================
"""

from datetime import datetime
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
from app import db
from app.models import User, LoginLog
from app.security import validate_input, sanitize_input

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    """User registration with input validation and password hashing."""
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))

    if request.method == 'POST':
        # Get form data
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')
        full_name = request.form.get('full_name', '').strip()

        # ---- Input Validation (Buffer Overflow Protection) ----
        errors = []

        if not username or len(username) > 50:
            errors.append('Username harus 1-50 karakter.')
        if not validate_input(username, 'username'):
            errors.append('Username hanya boleh huruf, angka, dan underscore.')

        if not email or len(email) > 120:
            errors.append('Email harus 1-120 karakter.')
        if not validate_input(email, 'email'):
            errors.append('Format email tidak valid.')

        if not password or len(password) < 8 or len(password) > 128:
            errors.append('Password harus 8-128 karakter.')

        if password != confirm_password:
            errors.append('Password tidak cocok.')

        if full_name and len(full_name) > 100:
            errors.append('Nama lengkap maksimal 100 karakter.')

        # Sanitize inputs (XSS prevention)
        username = sanitize_input(username)
        full_name = sanitize_input(full_name)

        # Check for existing user (using parameterized query via SQLAlchemy)
        if User.query.filter_by(username=username).first():
            errors.append('Username sudah digunakan.')
        if User.query.filter_by(email=email).first():
            errors.append('Email sudah digunakan.')

        if errors:
            for error in errors:
                flash(error, 'danger')
            return render_template('register.html',
                                   username=username, email=email, full_name=full_name)

        # ---- Create User with Hash+Salt Password ----
        user = User(
            username=username,
            email=email,
            full_name=full_name
        )
        user.set_password(password)  # bcrypt hash + auto-generated salt

        try:
            db.session.add(user)
            db.session.commit()
            flash('Registrasi berhasil! Silakan login.', 'success')
            return redirect(url_for('auth.login'))
        except Exception as e:
            db.session.rollback()
            flash('Terjadi kesalahan. Silakan coba lagi.', 'danger')

    return render_template('register.html')


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """User login with brute force protection."""
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')

        # ---- Input Validation ----
        if not username or len(username) > 50:
            flash('Username tidak valid.', 'danger')
            return render_template('login.html')

        if not password or len(password) > 128:
            flash('Password tidak valid.', 'danger')
            return render_template('login.html')

        # Sanitize input
        username = sanitize_input(username)

        # ---- Authentication (SQL Injection safe via SQLAlchemy ORM) ----
        user = User.query.filter_by(username=username).first()

        # Log login attempt
        log = LoginLog(
            username=username,
            ip_address=request.headers.get('X-Real-IP', request.remote_addr),
            user_agent=request.headers.get('User-Agent', '')[:512],
            success=False
        )

        if user is None or not user.check_password(password):
            # Failed login
            if user:
                user.login_attempts += 1
                # Lock account after 5 failed attempts
                if user.login_attempts >= 5:
                    user.is_active = False
                    flash('Akun terkunci karena terlalu banyak percobaan login gagal.', 'danger')
                db.session.commit()

            log.success = False
            db.session.add(log)
            db.session.commit()

            flash('Username atau password salah.', 'danger')
            return render_template('login.html')

        # Check if account is locked
        if not user.is_active:
            flash('Akun Anda terkunci. Hubungi administrator.', 'danger')
            return render_template('login.html')

        # Successful login
        user.login_attempts = 0
        user.last_login = datetime.utcnow()
        log.success = True
        db.session.add(log)
        db.session.commit()

        login_user(user, remember=False)
        flash(f'Selamat datang, {user.username}!', 'success')

        next_page = request.args.get('next')
        return redirect(next_page if next_page else url_for('main.dashboard'))

    return render_template('login.html')


@auth_bp.route('/logout')
@login_required
def logout():
    """User logout."""
    logout_user()
    flash('Anda telah logout.', 'info')
    return redirect(url_for('auth.login'))
