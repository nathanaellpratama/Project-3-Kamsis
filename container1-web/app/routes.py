"""
============================================
Main Application Routes
Proteksi: SQL Injection, XSS, Buffer Overflow
============================================
"""

from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from app import db
from app.models import User, Message
from app.security import validate_input, sanitize_input

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    """Landing page."""
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))
    return redirect(url_for('auth.login'))


@main_bp.route('/dashboard')
@login_required
def dashboard():
    """User dashboard - shows messages."""
    # SQLAlchemy ORM prevents SQL injection
    messages = Message.query.order_by(Message.created_at.desc()).limit(20).all()
    return render_template('dashboard.html', messages=messages)


@main_bp.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    """User profile - update info."""
    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        bio = request.form.get('bio', '').strip()

        # ---- Buffer Overflow Protection ----
        errors = []
        if full_name and len(full_name) > 100:
            errors.append('Nama lengkap maksimal 100 karakter.')
        if bio and len(bio) > 500:
            errors.append('Bio maksimal 500 karakter.')

        if errors:
            for error in errors:
                flash(error, 'danger')
            return render_template('profile.html')

        # ---- XSS Prevention: Sanitize inputs ----
        current_user.full_name = sanitize_input(full_name)
        current_user.bio = sanitize_input(bio)

        try:
            db.session.commit()
            flash('Profil berhasil diperbarui.', 'success')
        except Exception:
            db.session.rollback()
            flash('Gagal memperbarui profil.', 'danger')

        return redirect(url_for('main.profile'))

    return render_template('profile.html')


@main_bp.route('/messages', methods=['GET', 'POST'])
@login_required
def messages():
    """Post and view messages - tests XSS and SQL Injection protection."""
    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        content = request.form.get('content', '').strip()

        # ---- Buffer Overflow Protection ----
        errors = []
        if not title or len(title) > 200:
            errors.append('Judul harus 1-200 karakter.')
        if not content or len(content) > 2000:
            errors.append('Konten harus 1-2000 karakter.')

        if errors:
            for error in errors:
                flash(error, 'danger')
            return redirect(url_for('main.messages'))

        # ---- XSS Prevention: Sanitize inputs ----
        title = sanitize_input(title)
        content = sanitize_input(content)

        # ---- SQL Injection Prevention: SQLAlchemy ORM ----
        message = Message(
            title=title,
            content=content,
            user_id=current_user.id
        )

        try:
            db.session.add(message)
            db.session.commit()
            flash('Pesan berhasil dikirim.', 'success')
        except Exception:
            db.session.rollback()
            flash('Gagal mengirim pesan.', 'danger')

        return redirect(url_for('main.messages'))

    # Query messages using ORM (SQL injection safe)
    all_messages = Message.query.order_by(Message.created_at.desc()).limit(50).all()
    return render_template('dashboard.html', messages=all_messages, show_form=True)


@main_bp.route('/search')
@login_required
def search():
    """
    Search functionality - demonstrates SQL injection protection.
    Uses SQLAlchemy parameterized queries, NOT raw string concatenation.
    """
    query = request.args.get('q', '').strip()

    if not query:
        flash('Masukkan kata kunci pencarian.', 'info')
        return redirect(url_for('main.dashboard'))

    # ---- Buffer Overflow Protection ----
    if len(query) > 100:
        flash('Kata kunci pencarian terlalu panjang (max 100 karakter).', 'danger')
        return redirect(url_for('main.dashboard'))

    # ---- XSS Prevention ----
    query = sanitize_input(query)

    # ---- SQL Injection Prevention ----
    # SAFE: Using SQLAlchemy ORM with parameterized queries
    # This is NEVER concatenated into raw SQL
    results = Message.query.filter(
        db.or_(
            Message.title.ilike(f'%{query}%'),
            Message.content.ilike(f'%{query}%')
        )
    ).order_by(Message.created_at.desc()).limit(20).all()

    return render_template('dashboard.html', messages=results, search_query=query)


# ---- Error Handlers ----

@main_bp.app_errorhandler(404)
def not_found(error):
    return render_template('base.html', error='Halaman tidak ditemukan (404)'), 404


@main_bp.app_errorhandler(413)
def too_large(error):
    flash('Request terlalu besar. Maksimal 1MB.', 'danger')
    return redirect(url_for('main.dashboard'))


@main_bp.app_errorhandler(429)
def rate_limited(error):
    flash('Terlalu banyak request. Coba lagi nanti.', 'danger')
    return render_template('login.html'), 429
