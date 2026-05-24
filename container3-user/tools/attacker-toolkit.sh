#!/bin/bash
# ============================================
# All-in-One Attacker Toolkit
# Menu-driven attack testing suite
# ============================================

echo "======================================"
echo "  SECURITY TESTING TOOLKIT"
echo "  Project 3 - Keamanan Sistem"
echo "  Telkom University"
echo "======================================"

WEB_HOST="10.10.10.10"
SNORT_HOST="10.10.10.20"

show_menu() {
    echo ""
    echo "====== TARGET: $WEB_HOST ======"
    echo ""
    echo "  TESTING MENU:"
    echo "  1) Test Normal User Access"
    echo "  2) Test SQL Injection"
    echo "  3) Test XSS Attacks"
    echo "  4) Test DoS Attacks"
    echo "  5) Test Port Scanning"
    echo "  6) Test Buffer Overflow"
    echo "  7) Run ALL Tests"
    echo ""
    echo "  UTILITIES:"
    echo "  8) Ping Web Server"
    echo "  9) Check Web Server Status"
    echo "  0) Exit"
    echo ""
    read -p "  Pilihan: " choice
}

run_test() {
    local script="$1"
    if [ -f "/opt/scripts/$script" ]; then
        echo ""
        bash "/opt/scripts/$script"
    else
        echo "Script not found: $script"
    fi
}

while true; do
    show_menu
    case $choice in
        1) run_test "test-normal.sh" ;;
        2) run_test "test-sql-injection.sh" ;;
        3) run_test "test-xss.sh" ;;
        4) run_test "test-dos.sh" ;;
        5) run_test "test-portscan.sh" ;;
        6) run_test "test-buffer-overflow.sh" ;;
        7)
            echo ""
            echo "Running ALL tests..."
            run_test "test-normal.sh"
            run_test "test-sql-injection.sh"
            run_test "test-xss.sh"
            run_test "test-dos.sh"
            run_test "test-portscan.sh"
            run_test "test-buffer-overflow.sh"
            echo ""
            echo "ALL TESTS COMPLETE!"
            ;;
        8) ping -c 4 "$WEB_HOST" ;;
        9) curl -sk -I "https://${WEB_HOST}/" 2>/dev/null | head -15 ;;
        0) echo "Bye!"; exit 0 ;;
        *) echo "Pilihan tidak valid." ;;
    esac
done
