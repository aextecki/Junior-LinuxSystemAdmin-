#!/bin/bash

# =============================================
# Project Phoenix: Permission & Ownership Setup
# Tasks:
# 1. Set owner: dev_lead, group: developers (recursive)
# 2. Set dir perms: 750 (owner full, group rx, others none)
# 3. Set SetGID on src/ for group inheritance
# =============================================

set -euo pipefail  # Exit on error, undefined vars, pipe failure

# === CONFIGURATION ===
PROJECT_DIR="$HOME/project/phoenix_project"
SRC_DIR="$PROJECT_DIR/src"
OWNER="dev_lead"
GROUP="developers"

# === VALIDATION ===
echo "Validating environment..."

# Check if project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
    echo "Please create it first or check the path." >&2
    exit 1
fi

# Check if src directory exists
if [[ ! -d "$SRC_DIR" ]]; then
    echo "WARNING: src directory not found: $SRC_DIR" >&2
    echo "Creating it..."
    mkdir -p "$SRC_DIR"
fi

# Check if user and group exist
if ! id "$OWNER" >/dev/null 2>&1; then
    echo "ERROR: User '$OWNER' does not exist." >&2
    echo "Create it with: sudo adduser $OWNER" >&2
    exit 1
fi

if ! getent group "$GROUP" >/dev/null 2>&1; then
    echo "ERROR: Group '$GROUP' does not exist." >&2
    echo "Create it with: sudo addgroup $GROUP" >&2
    exit 1
fi

# === TASK 1: Change Ownership (Recursive) ===
echo
echo "[1/3] Changing ownership of '$PROJECT_DIR' to $OWNER:$GROUP (recursive)..."
sudo chown -R "$OWNER":"$GROUP" "$PROJECT_DIR"
echo "Ownership updated."

# === TASK 2: Set Directory Permissions (750) ===
echo
echo "[2/3] Setting permissions on '$PROJECT_DIR' to 750 (drwxr-x---)..."
sudo chmod 750 "$PROJECT_DIR"
echo "Permissions set: owner=rwx, group=rx, others=none"

# === TASK 3: Set SetGID on src/ for Group Inheritance ===
echo
echo "[3/3] Setting SetGID on '$SRC_DIR' so new files inherit group '$GROUP'..."
sudo chmod g+s "$SRC_DIR"
echo "SetGID applied: new files will belong to '$GROUP'"

# Optional: Set default permissions for new files (umask not needed here)
# But ensure directory allows group write if needed
sudo chmod g+w "$SRC_DIR"  # Allow group to create files

# === VERIFICATION ===
echo
echo "Verification:"
echo "   Directory: $PROJECT_DIR"
ls -ld "$PROJECT_DIR"
echo "   src/:"
ls -ld "$SRC_DIR"

echo
echo "New files in src/ will inherit group '$GROUP'."
echo "Example test:"
echo "   su - $OWNER -c \"touch $SRC_DIR/test.txt && ls -l $SRC_DIR/test.txt\""

echo
echo "Setup Complete!"
echo "   Owner: $OWNER"
echo "   Group: $GROUP"
echo "   SetGID: Enabled on src/"
