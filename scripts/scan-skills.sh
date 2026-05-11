#!/usr/bin/env bash
set -euo pipefail

# Scan installed OpenClaw skills for security threats using ClawShield.
# Usage: ./scripts/scan-skills.sh [--format json] [--threshold critical]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/skills"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if ! command -v clawshield &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} ClawShield not found. Install with: npm install -g clawshield"
    exit 1
fi

if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
    echo -e "${GREEN}[INFO]${NC} No skills installed in $SKILLS_DIR — nothing to scan."
    exit 0
fi

FORMAT="${1:---format text}"
THRESHOLD="${2:---threshold high}"

echo -e "${GREEN}[INFO]${NC} Scanning skills in $SKILLS_DIR..."
echo ""

clawshield scan "$SKILLS_DIR" $FORMAT $THRESHOLD

echo ""
echo -e "${GREEN}[INFO]${NC} Scan complete."
