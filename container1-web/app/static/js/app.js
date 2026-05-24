/**
 * SecureApp - Client-side JavaScript
 * Additional client-side input validation (defense in depth)
 */

document.addEventListener('DOMContentLoaded', function() {
    // Auto-dismiss flash messages after 5 seconds
    const flashMessages = document.querySelectorAll('.flash-message');
    flashMessages.forEach(function(msg) {
        setTimeout(function() { msg.style.opacity = '0'; setTimeout(function() { msg.remove(); }, 300); }, 5000);
    });

    // Client-side input length validation
    const inputs = document.querySelectorAll('input[maxlength], textarea[maxlength]');
    inputs.forEach(function(input) {
        input.addEventListener('input', function() {
            const max = parseInt(this.getAttribute('maxlength'));
            if (this.value.length >= max) {
                this.style.borderColor = '#dc2626';
            } else {
                this.style.borderColor = '';
            }
        });
    });

    // Password confirmation validation
    const confirmPw = document.getElementById('confirm_password');
    if (confirmPw) {
        confirmPw.addEventListener('input', function() {
            const pw = document.getElementById('password');
            if (pw && this.value !== pw.value) {
                this.style.borderColor = '#dc2626';
            } else {
                this.style.borderColor = '#16a34a';
            }
        });
    }
});
