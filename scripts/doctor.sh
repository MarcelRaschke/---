#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Doctor Script
# Diagnoses common issues with your OpenClaw setup.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC}  $*"; }
warn() { echo -e "  ${YELLOW}WARN${NC}  $*"; }
fail() { echo -e "  ${RED}FAIL${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ERRORS=0

echo ""
echo "========================================="
echo "  OpenClaw Doctor"
echo "========================================="
echo ""

# --- Check .env ---
echo "Configuration:"
if [ -f "$PROJECT_DIR/.env" ]; then
    pass ".env file exists"
    # Check for at least one API key
    if grep -qE '^(ANTHROPIC_API_KEY|OPENAI_API_KEY|OPENROUTER_API_KEY|GOOGLE_API_KEY)=.+' "$PROJECT_DIR/.env"; then
        pass "At least one API key is configured"
    else
        warn "No API keys set in .env — OpenClaw needs at least one (or Ollama)"
    fi
else
    fail ".env file not found — run: cp .env.example .env"
    ((ERRORS++))
fi

# --- Check workspace ---
if [ -d "$PROJECT_DIR/workspace" ]; then
    pass "Workspace directory exists"
    if [ -w "$PROJECT_DIR/workspace" ]; then
        pass "Workspace is writable"
    else
        fail "Workspace is not writable — run: chmod 755 workspace"
        ((ERRORS++))
    fi
else
    warn "Workspace directory missing — will be created on first run"
fi

echo ""
echo "Runtime:"

# --- Check Docker ---
if command -v docker &>/dev/null; then
    pass "Docker is installed ($(docker --version | head -1))"
    if docker info &>/dev/null 2>&1; then
        pass "Docker daemon is running"
    else
        warn "Docker daemon is not running or not accessible"
    fi
    if command -v docker compose &>/dev/null 2>&1; then
        pass "Docker Compose is available"
    else
        warn "Docker Compose not found"
    fi
else
    warn "Docker not installed (optional if using native install)"
fi

# --- Check Node.js ---
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 22 ]; then
        pass "Node.js $NODE_VER (meets requirement >= 22)"
    else
        warn "Node.js $NODE_VER (requirement: >= 22.16)"
    fi
else
    warn "Node.js not installed (optional if using Docker)"
fi

# --- Check OpenClaw native ---
if command -v openclaw &>/dev/null; then
    pass "OpenClaw CLI installed ($(openclaw --version 2>/dev/null || echo 'version unknown'))"
else
    warn "OpenClaw CLI not installed globally"
fi

echo ""
echo "Network:"

# --- Check ports ---
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"

check_port() {
    local port=$1 name=$2
    if ss -tlnp 2>/dev/null | grep -q ":$port " || lsof -i ":$port" &>/dev/null 2>&1; then
        pass "Port $port ($name) is in use — service likely running"
    else
        warn "Port $port ($name) is free — service not running"
    fi
}

check_port "$GATEWAY_PORT" "Gateway"
check_port "$BRIDGE_PORT" "Bridge"

# --- Health check ---
if curl -fsS "http://127.0.0.1:$GATEWAY_PORT/healthz" &>/dev/null; then
    pass "Gateway health check passed"
else
    warn "Gateway health check failed (may not be running)"
fi

echo ""
echo "Security:"

# --- Check .env not tracked ---
if [ -d "$PROJECT_DIR/.git" ]; then
    if git -C "$PROJECT_DIR" ls-files --error-unmatch .env &>/dev/null 2>&1; then
        fail ".env is tracked by git! Run: git rm --cached .env"
        ((ERRORS++))
    else
        pass ".env is not tracked by git"
    fi
fi

# --- Check cert files ---
if [ -d "$PROJECT_DIR/nginx/certs" ]; then
    if [ -f "$PROJECT_DIR/nginx/certs/fullchain.pem" ] && [ -f "$PROJECT_DIR/nginx/certs/privkey.pem" ]; then
        pass "TLS certificates found"
    else
        warn "nginx/certs/ exists but missing fullchain.pem or privkey.pem"
    fi
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}Found $ERRORS error(s) that need attention.${NC}"
    exit 1
else
    echo -e "${GREEN}No critical issues found.${NC}"
fi
echo ""
