#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Backup Script
# Creates a timestamped backup of workspace data and configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${1:-$PROJECT_DIR/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="openclaw-backup-$TIMESTAMP"

GREEN='\033[0;32m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC} $*"; }

mkdir -p "$BACKUP_DIR"

info "Creating backup: $BACKUP_NAME"

tar czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" \
    -C "$PROJECT_DIR" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='backups' \
    workspace/ \
    config/ \
    .env 2>/dev/null || true

BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)
info "Backup saved: $BACKUP_DIR/$BACKUP_NAME.tar.gz ($BACKUP_SIZE)"

# Keep only last 10 backups
cd "$BACKUP_DIR"
ls -t openclaw-backup-*.tar.gz 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
info "Backup retention: keeping last 10 backups"
