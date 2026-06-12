#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

echo ""
echo "========================================="
echo "  OpenClaw Update"
echo "========================================="
echo ""

if docker compose -f "$PROJECT_DIR/docker-compose.yml" ps --quiet 2>/dev/null | grep -q .; then
    info "Docker installation detected"
    info "Pulling latest image..."
    cd "$PROJECT_DIR"
    docker compose pull
    info "Restarting with new image..."
    docker compose up -d
    sleep 5
    if docker compose ps | grep -q "healthy\|running"; then
        info "Update complete! OpenClaw is running."
    else
        warn "Container may still be starting. Check: docker compose logs -f"
    fi
elif command -v openclaw &>/dev/null; then
    info "Native installation detected"
    current=$(openclaw --version 2>/dev/null || echo "unknown")
    info "Current version: $current"
    info "Updating via npm..."
    npm install -g openclaw@latest
    new=$(openclaw --version 2>/dev/null || echo "unknown")
    info "Updated to: $new"
    if command -v openclaw &>/dev/null && openclaw status &>/dev/null 2>&1; then
        info "Restarting daemon..."
        openclaw daemon restart 2>/dev/null || true
    fi
else
    warn "No OpenClaw installation found."
    warn "Run ./scripts/setup.sh to install first."
    exit 1
fi

echo ""
info "Done! Run 'openclaw doctor --fix' to verify."
echo ""
