#!/bin/bash
# ============================================
# Real-Time Alert Monitor
# Monitors Snort alerts in real-time
# ============================================

ALERT_FILE="/var/log/snort/alert_fast.txt"

echo "======================================"
echo " Snort Real-Time Alert Monitor"
echo " Tekan Ctrl+C untuk berhenti"
echo "======================================"
echo ""

show_menu() {
    echo "Pilih mode monitoring:"
    echo "  1) Monitor SEMUA alert (real-time)"
    echo "  2) Monitor hanya SQL Injection alerts"
    echo "  3) Monitor hanya XSS alerts"
    echo "  4) Monitor hanya Port Scan alerts"
    echo "  5) Monitor hanya DoS alerts"
    echo "  6) Monitor hanya Buffer Overflow alerts"
    echo "  7) Tampilkan ringkasan alert terakhir"
    echo "  8) Hapus log alert"
    echo "  0) Keluar"
    echo ""
    read -p "Pilihan: " choice
}

monitor_all() {
    echo "[MONITOR] Monitoring all Snort alerts..."
    echo "[MONITOR] Waiting for alerts on: $ALERT_FILE"
    echo "---"
    tail -f "$ALERT_FILE" 2>/dev/null || {
        echo "[MONITOR] Alert file not found. Creating..."
        touch "$ALERT_FILE"
        tail -f "$ALERT_FILE"
    }
}

monitor_filtered() {
    local filter="$1"
    local label="$2"
    echo "[MONITOR] Monitoring $label alerts..."
    echo "---"
    tail -f "$ALERT_FILE" 2>/dev/null | grep --line-buffered -i "$filter"
}

show_summary() {
    echo ""
    echo "=== Alert Summary ==="
    if [ -f "$ALERT_FILE" ]; then
        total=$(wc -l < "$ALERT_FILE")
        echo "Total alerts: $total"
        echo ""
        echo "--- By Category ---"
        echo "SQL Injection: $(grep -ci 'SQL Injection' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "XSS:           $(grep -ci 'XSS' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "Port Scan:     $(grep -ci 'Port Scan\|Scan\|Recon' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "DoS:           $(grep -ci 'DoS\|flood' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "Buffer Overflow: $(grep -ci 'Buffer Overflow\|Oversized' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "Brute Force:   $(grep -ci 'Brute Force\|login attempt' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "ICMP:          $(grep -ci 'ICMP' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "Community:     $(grep -ci 'COMMUNITY' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo "Custom:        $(grep -ci 'CUSTOM' "$ALERT_FILE" 2>/dev/null || echo 0)"
        echo ""
        echo "--- Last 10 Alerts ---"
        tail -10 "$ALERT_FILE"
    else
        echo "No alert file found."
    fi
}

clear_logs() {
    read -p "Yakin ingin menghapus semua alert logs? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        > "$ALERT_FILE"
        echo "[MONITOR] Alert logs cleared."
    else
        echo "[MONITOR] Dibatalkan."
    fi
}

# Check if running with argument for direct mode
if [ "$1" = "--follow" ] || [ "$1" = "-f" ]; then
    monitor_all
    exit 0
fi

# Interactive menu
while true; do
    show_menu
    case $choice in
        1) monitor_all ;;
        2) monitor_filtered "SQL Injection" "SQL Injection" ;;
        3) monitor_filtered "XSS" "XSS" ;;
        4) monitor_filtered "Port Scan\|Scan\|Recon" "Port Scan" ;;
        5) monitor_filtered "DoS\|flood" "DoS" ;;
        6) monitor_filtered "Buffer Overflow\|Oversized" "Buffer Overflow" ;;
        7) show_summary ;;
        8) clear_logs ;;
        0) echo "Bye!"; exit 0 ;;
        *) echo "Pilihan tidak valid." ;;
    esac
done
