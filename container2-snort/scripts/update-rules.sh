#!/bin/bash
# ============================================
# Manual Rule Update Script
# Updates community rules & reloads Snort
# ============================================

RULES_DIR="/etc/snort/rules"
BACKUP_DIR="/etc/snort/rules/backup"
COMMUNITY_URL="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"

echo "======================================"
echo " Snort Rule Update Manager"
echo "======================================"

show_menu() {
    echo ""
    echo "Pilih opsi:"
    echo "  1) Download & update community rules"
    echo "  2) Tambah rule manual ke local.rules"
    echo "  3) Lihat local rules"
    echo "  4) Lihat community rules"
    echo "  5) Lihat custom web-attacks rules"
    echo "  6) Validasi konfigurasi Snort"
    echo "  7) Reload Snort (apply rules baru)"
    echo "  8) Backup rules saat ini"
    echo "  9) Restore rules dari backup"
    echo "  0) Keluar"
    echo ""
    read -p "Pilihan: " choice
}

download_community_rules() {
    echo "[UPDATE] Downloading community rules..."
    cd /tmp
    
    wget -q "$COMMUNITY_URL" -O snort3-community-rules.tar.gz 2>/dev/null
    if [ $? -eq 0 ]; then
        # Backup current rules
        backup_rules
        
        # Extract new rules
        tar xzf snort3-community-rules.tar.gz
        if [ -f snort3-community-rules/snort3-community.rules ]; then
            cp snort3-community-rules/snort3-community.rules "$RULES_DIR/community.rules"
            echo "[UPDATE] Community rules updated successfully!"
            echo "[UPDATE] Rule count: $(grep -c '^[^#]' $RULES_DIR/community.rules 2>/dev/null || echo 0) active rules"
        else
            echo "[UPDATE] Downloaded file structure unexpected. Checking contents..."
            ls -la snort3-community-rules/
        fi
        rm -rf snort3-community-rules snort3-community-rules.tar.gz
    else
        echo "[UPDATE] ERROR: Failed to download community rules."
        echo "[UPDATE] Check internet connection or URL: $COMMUNITY_URL"
        echo "[UPDATE] You can also manually download and place rules in: $RULES_DIR/community.rules"
    fi
}

add_manual_rule() {
    echo ""
    echo "Format rule Snort 3:"
    echo '  alert tcp any any -> $HOME_NET $HTTP_PORTS (msg:"Description"; content:"pattern"; sid:XXXXXX; rev:1;)'
    echo '  drop tcp any any -> $HOME_NET $HTTP_PORTS (msg:"Description"; content:"pattern"; sid:XXXXXX; rev:1;)'
    echo ""
    echo "Actions: alert (IDS/monitoring) | drop (IPS/blocking) | reject (IPS/block+RST)"
    echo ""
    read -p "Masukkan rule baru (atau 'cancel'): " new_rule
    
    if [ "$new_rule" = "cancel" ]; then
        echo "[RULE] Dibatalkan."
        return
    fi
    
    # Validate basic rule format
    if echo "$new_rule" | grep -qE "^(alert|drop|reject|log|pass)\s"; then
        echo "$new_rule" >> "$RULES_DIR/local.rules"
        echo "[RULE] Rule berhasil ditambahkan ke local.rules"
        echo "[RULE] Jalankan opsi 7 untuk reload Snort."
    else
        echo "[RULE] ERROR: Format rule tidak valid."
        echo "[RULE] Rule harus dimulai dengan: alert, drop, reject, log, atau pass"
    fi
}

view_rules() {
    local file="$1"
    local name="$2"
    echo ""
    echo "=== $name ==="
    if [ -f "$file" ]; then
        echo "Active rules: $(grep -c '^[^#]' "$file" 2>/dev/null || echo 0)"
        echo "---"
        cat "$file"
    else
        echo "File not found: $file"
    fi
}

validate_config() {
    echo "[VALIDATE] Validating Snort configuration..."
    snort -c /etc/snort/config/snort.lua \
        --plugin-path /usr/local/lib/snort/plugins \
        -T 2>&1
    echo "[VALIDATE] Validation complete."
}

reload_snort() {
    echo "[RELOAD] Reloading Snort..."
    SNORT_PID=$(pidof snort 2>/dev/null)
    if [ -n "$SNORT_PID" ]; then
        kill -SIGHUP "$SNORT_PID"
        echo "[RELOAD] Sent SIGHUP to Snort (PID: $SNORT_PID)"
        echo "[RELOAD] Snort is reloading rules..."
        sleep 2
        if kill -0 "$SNORT_PID" 2>/dev/null; then
            echo "[RELOAD] Snort is running with updated rules."
        else
            echo "[RELOAD] WARNING: Snort process may have stopped. Check logs."
        fi
    else
        echo "[RELOAD] Snort is not running. Start it first."
    fi
}

backup_rules() {
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    cp "$RULES_DIR/local.rules" "$BACKUP_DIR/local.rules.$TIMESTAMP" 2>/dev/null
    cp "$RULES_DIR/community.rules" "$BACKUP_DIR/community.rules.$TIMESTAMP" 2>/dev/null
    echo "[BACKUP] Rules backed up with timestamp: $TIMESTAMP"
}

restore_rules() {
    echo "[RESTORE] Available backups:"
    ls -la "$BACKUP_DIR/" 2>/dev/null || echo "No backups found."
    echo ""
    read -p "Enter backup filename to restore: " backup_file
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        if echo "$backup_file" | grep -q "^local"; then
            cp "$BACKUP_DIR/$backup_file" "$RULES_DIR/local.rules"
        elif echo "$backup_file" | grep -q "^community"; then
            cp "$BACKUP_DIR/$backup_file" "$RULES_DIR/community.rules"
        fi
        echo "[RESTORE] Rules restored from: $backup_file"
    else
        echo "[RESTORE] File not found."
    fi
}

# Main loop
while true; do
    show_menu
    case $choice in
        1) download_community_rules ;;
        2) add_manual_rule ;;
        3) view_rules "$RULES_DIR/local.rules" "Local Rules" ;;
        4) view_rules "$RULES_DIR/community.rules" "Community Rules" ;;
        5) view_rules "$RULES_DIR/custom/web-attacks.rules" "Custom Web Attack Rules" ;;
        6) validate_config ;;
        7) reload_snort ;;
        8) backup_rules ;;
        9) restore_rules ;;
        0) echo "Bye!"; exit 0 ;;
        *) echo "Pilihan tidak valid." ;;
    esac
done
