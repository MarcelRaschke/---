#!/usr/bin/env bash
set -euo pipefail

# Scan installed OpenClaw skills for security threats.
# Layer 1: ClawShield (local, offline)
# Layer 2: ClawDefend (cloud API, requires CLAWDEFEND_API_KEY)
#
# Usage: ./scripts/scan-skills.sh [--threshold high|critical] [--format text|json]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$PROJECT_DIR/skills"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Source .env if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

THRESHOLD="${1:-high}"
FORMAT="${2:-text}"
EXIT_CODE=0

if [ ! -d "$SKILLS_DIR" ] || [ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
    info "No skills installed in $SKILLS_DIR — nothing to scan."
    exit 0
fi

# --- Layer 1: ClawShield (local scan) ---

if command -v clawshield &>/dev/null; then
    info "Running ClawShield local scan..."
    echo ""
    if ! clawshield scan "$SKILLS_DIR" --threshold "$THRESHOLD" --format "$FORMAT"; then
        EXIT_CODE=1
        error "ClawShield found issues exceeding threshold: $THRESHOLD"
    fi
    echo ""
else
    warn "ClawShield not installed. Run: npm install -g clawshield"
fi

# --- Layer 2: ClawDefend (cloud scan) ---

if [ -n "${CLAWDEFEND_API_KEY:-}" ]; then
    info "Running ClawDefend cloud scan..."

    TMPFILE=$(mktemp /tmp/skills-XXXXXX.tar.gz)
    trap 'rm -f "$TMPFILE"' EXIT

    tar czf "$TMPFILE" -C "$SKILLS_DIR" .

    RESPONSE=$(curl -sf -X POST \
        -H "Authorization: Bearer $CLAWDEFEND_API_KEY" \
        -H "Content-Type: application/gzip" \
        --data-binary "@$TMPFILE" \
        "https://api.clawdefend.com/v1/scan" 2>&1) || {
        warn "ClawDefend API request failed. Check your API key or network connection."
        echo ""
        info "Scan complete (local only)."
        exit $EXIT_CODE
    }

    CRITICAL=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin)
    findings = r.get('findings', [])
    count = sum(1 for f in findings if f.get('severity') in ('critical', 'high'))
    print(count)
except Exception:
    print(0)
" 2>/dev/null)

    TOTAL=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin)
    print(len(r.get('findings', [])))
except Exception:
    print(0)
" 2>/dev/null)

    echo ""
    if [ "$FORMAT" = "json" ]; then
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
        info "ClawDefend results: $TOTAL findings ($CRITICAL critical/high)"
        echo "$RESPONSE" | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin)
    for f in r.get('findings', []):
        sev = f.get('severity', 'unknown').upper()
        msg = f.get('message', 'No description')
        loc = f.get('file', '') + ':' + str(f.get('line', ''))
        print(f'  [{sev}] {loc} — {msg}')
except Exception:
    pass
" 2>/dev/null
    fi

    if [ "${CRITICAL:-0}" -gt 0 ]; then
        EXIT_CODE=1
        error "ClawDefend found $CRITICAL critical/high severity findings"
    fi
    echo ""
else
    info "ClawDefend cloud scan skipped (CLAWDEFEND_API_KEY not set)"
    info "Get a free API key at https://www.clawdefend.com/"
fi

info "Scan complete."
exit $EXIT_CODE
