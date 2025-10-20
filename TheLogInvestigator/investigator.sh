#!/bin/bash

# =============================================
# Project Phoenix Investigation Script
# Author: Investigator
# Purpose: Diagnose application, system, and deployment issues
# =============================================

set -euo pipefail  # Exit on error, undefined var, pipe failure

# Define paths
LOG_FILE="$HOME/project/logs/app.log"
ERROR_REPORT="$HOME/project/error_report.txt"
BOOT_ISSUES="$HOME/project/boot_issues.txt"
NGINX_CONF="$HOME/project/config/nginx.conf"
SERVER1_DIR="/home/labex/project/server1_files"
SERVER2_DIR="/home/labex/project/server2_files"
MISSING_FILES="/home/labex/project/missing_files.txt"

# Ensure project directory exists
mkdir -p "$HOME/project"

echo "[1/4] Filtering ERROR lines from app.log..."
if [[ ! -f "$LOG_FILE" ]]; then
    echo "ERROR: Log file not found: $LOG_FILE" >&2
    exit 1
fi

grep "ERROR" "$LOG_FILE" > "$ERROR_REPORT" || {
    echo "No ERROR lines found or grep failed."
    > "$ERROR_REPORT"  # Create empty file
}
echo "   → Saved to $ERROR_REPORT"

echo "[2/4] Checking kernel ring buffer for 'fail' or 'error' (case-insensitive)..."
sudo dmesg | grep -iE "(fail|error)" > "$BOOT_ISSUES" || {
    echo "No matching kernel messages found."
    > "$BOOT_ISSUES"
}
echo "   → Saved to $BOOT_ISSUES"

echo "[3/4] Extracting worker_processes from nginx.conf..."
if [[ ! -f "$NGINX_CONF" ]]; then
    echo "WARNING: Nginx config not found: $NGINX_CONF" >&2
else
    WORKER_LINE=$(grep "^[[:space:]]*worker_processes" "$NGINX_CONF" | head -1 || echo "# worker_processes not found")
    echo "$WORKER_LINE" >> "$ERROR_REPORT"
    echo "   → Appended: '$WORKER_LINE' to $ERROR_REPORT"
fi

echo "[4/4] Comparing server directories for missing files..."
if [[ ! -d "$SERVER1_DIR" || ! -d "$SERVER2_DIR" ]]; then
    echo "ERROR: One or both server directories not found!" >&2
    echo "   Expected: $SERVER1_DIR and $SERVER2_DIR"
    exit 1
fi

# Use diff -r to recursively compare and show "Only in" files
diff -r --brief "$SERVER1_DIR" "$SERVER2_DIR" 2>/dev/null | \
    grep "^Only in $SERVER1_DIR" | \
    sed "s|Only in $SERVER1_DIR/|: |; s|: |/|" > "$MISSING_FILES" || {
    echo "No unique files in server1_files or diff failed."
    > "$MISSING_FILES"
}

# Also include full diff for context (optional, but helpful)
{
    echo "=== FULL DIFF (server1_files vs server2_files) ==="
    diff -r "$SERVER1_DIR" "$SERVER2_DIR" 2>/dev/null || true
    echo
    echo "=== FILES ONLY IN server1_files (missing in production) ==="
    grep "^Only in $SERVER1_DIR" <(diff -r "$SERVER1_DIR" "$SERVER2_DIR" 2>/dev/null) | \
        sed "s|Only in $SERVER1_DIR/|: |; s|: |/|" || true
} >> "$MISSING_FILES"

echo "   → Comparison saved to $MISSING_FILES"

echo
echo "Investigation Complete!"
echo "   • Errors: $ERROR_REPORT"
echo "   • Boot issues: $BOOT_ISSUES"
echo "   • Missing files: $MISSING_FILES"



