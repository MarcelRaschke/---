#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SKILLS_DIR="$PROJECT_DIR/skills"

if ! command -v clawshield &>/dev/null; then
    error "ClawShield not found. Install with: npm install -g clawshield"
    exit 1
fi

if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
    info "No skills installed in $SKILLS_DIR — nothing to scan."
    exit 0
fi

FORMAT="${1:---format text}"
THRESHOLD="${2:---threshold high}"

info "Scanning skills in $SKILLS_DIR..."
echo ""

clawshield scan "$SKILLS_DIR" $FORMAT $THRESHOLD

echo ""
info "Scan complete."
