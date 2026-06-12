#!/usr/bin/env bash
# Shared utilities for OpenClaw scripts.
# Source this from any script: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
pass()  { echo -e "  ${GREEN}PASS${NC}  $*"; }
fail()  { echo -e "  ${RED}FAIL${NC}  $*"; }
