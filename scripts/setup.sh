#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Setup Script
# Guides you through setting up OpenClaw via native install or Docker.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Check prerequisites ---

check_node() {
    if command -v node &>/dev/null; then
        local version
        version=$(node --version | sed 's/v//')
        local major
        major=$(echo "$version" | cut -d. -f1)
        if [ "$major" -ge 22 ]; then
            info "Node.js $version found"
            return 0
        else
            warn "Node.js $version found, but 22.16+ is required"
            return 1
        fi
    else
        warn "Node.js not found"
        return 1
    fi
}

check_docker() {
    if command -v docker &>/dev/null && command -v docker compose &>/dev/null 2>&1; then
        info "Docker and Docker Compose found"
        return 0
    else
        warn "Docker or Docker Compose not found"
        return 1
    fi
}

# --- Setup .env ---

setup_env() {
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        info "Created .env from .env.example"
        warn "Please edit .env and add your API key(s) before starting OpenClaw"
    else
        info ".env already exists, skipping"
    fi
}

# --- Setup workspace ---

setup_workspace() {
    mkdir -p "$PROJECT_DIR/workspace"
    info "Workspace directory ready"
}

# --- Install methods ---

install_native() {
    info "Installing OpenClaw globally via npm..."
    npm install -g openclaw@latest
    info "Running OpenClaw onboarding..."
    openclaw onboard --install-daemon
}

install_docker() {
    info "Starting OpenClaw via Docker Compose..."
    cd "$PROJECT_DIR"
    docker compose up -d
    info "Waiting for OpenClaw to start..."
    sleep 5
    if docker compose ps | grep -q "healthy\|running"; then
        info "OpenClaw is running!"
    else
        warn "OpenClaw may still be starting. Check with: docker compose logs -f"
    fi
}

# --- Main ---

echo ""
echo "========================================="
echo "  OpenClaw Setup"
echo "========================================="
echo ""

HAS_NODE=false
HAS_DOCKER=false

check_node && HAS_NODE=true
check_docker && HAS_DOCKER=true

if [ "$HAS_NODE" = false ] && [ "$HAS_DOCKER" = false ]; then
    error "Neither Node.js 22+ nor Docker found."
    echo "  Install Node.js: https://nodejs.org/"
    echo "  Install Docker:  https://docs.docker.com/get-docker/"
    exit 1
fi

setup_env
setup_workspace

# Build menu options dynamically based on available tools
declare -A MENU_ACTIONS
echo ""
echo "How would you like to install OpenClaw?"
echo ""
opt=1
if [ "$HAS_NODE" = true ]; then
    echo "  $opt) Native (npm install -g openclaw)"
    MENU_ACTIONS[$opt]="native"
    ((opt++))
fi
if [ "$HAS_DOCKER" = true ]; then
    echo "  $opt) Docker (docker compose up)"
    MENU_ACTIONS[$opt]="docker"
    ((opt++))
fi
echo "  $opt) Skip installation (just configure)"
MENU_ACTIONS[$opt]="skip"
echo ""

read -rp "Choose [1-$opt]: " choice

case "${MENU_ACTIONS[$choice]:-}" in
    native) install_native ;;
    docker) install_docker ;;
    skip)
        info "Skipping installation. Configuration files are ready."
        info "Run 'npm install -g openclaw@latest' or 'docker compose up -d' when ready."
        ;;
    *)
        error "Invalid choice"
        exit 1
        ;;
esac

echo ""
info "Setup complete! Next steps:"
info "  1. Edit .env with your API key(s)"
info "  2. Run 'openclaw doctor --fix' to verify your setup"
info "  3. Visit https://docs.openclaw.ai for configuration guides"
echo ""
