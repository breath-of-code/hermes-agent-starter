#!/bin/bash
# backup-hermes.sh — Create a timestamped archive of ~/.hermes/ for backup/migration
# Usage: bash scripts/backup-hermes.sh [--dry-run|-n] [--include-secrets] [output_dir]
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
OUTPUT_DIR=""
DRY_RUN=false
INCLUDE_SECRETS=false

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --include-secrets)
            INCLUDE_SECRETS=true
            shift
            ;;
        -*)
            echo "Unknown flag: $1"
            echo "Usage: bash scripts/backup-hermes.sh [--dry-run|-n] [--include-secrets] [output_dir]"
            exit 1
            ;;
        *)
            OUTPUT_DIR="$1"
            shift
            ;;
    esac
done

# Default output directory
if [ -z "$OUTPUT_DIR" ]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    OUTPUT_DIR="$REPO_ROOT/backups"
fi

# Validate HERMES_HOME exists
if [ ! -d "$HERMES_HOME" ]; then
    echo "[-] Error: HERMES_HOME ($HERMES_HOME) does not exist."
    echo "    Is Hermes Agent installed? Run 'hermes doctor' to check."
    exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="hermes-${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"

if $DRY_RUN; then
    echo "[DRY-RUN] Would create archive: $ARCHIVE_PATH"
    echo "[DRY-RUN] Source: $HERMES_HOME"
    echo ""
    echo "[DRY-RUN] Exclusions:"
    echo "  - .env, .env.*"
    echo "  - MEMORY.md, USER.md"
    echo "  - logs/"
    echo "  - node_modules/, __pycache__/, *.pyc"
    echo "  - .npm/, .cache/"
    if ! $INCLUDE_SECRETS; then
        echo "  - (secrets excluded — use --include-secrets to include .env)"
    fi
    echo ""
    echo "[DRY-RUN] Would include all other files from $HERMES_HOME"
    echo "[DRY-RUN] Done. No files were modified."
    exit 0
fi

# Warn about secrets exclusion
if ! $INCLUDE_SECRETS; then
    echo "[!] Secrets (.env, .env.*) will be EXCLUDED from the archive."
    echo "    Use --include-secrets if you need to back up API keys (not recommended for shared archives)."
    echo ""
fi

# Build tar exclude patterns
EXCLUDE_ARGS=(
    --exclude='.env'
    --exclude='.env.*'
    --exclude='MEMORY.md'
    --exclude='USER.md'
    --exclude='logs'
    --exclude='node_modules'
    --exclude='__pycache__'
    --exclude='*.pyc'
    --exclude='.npm'
    --exclude='.cache'
)

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "[+] Creating archive: $ARCHIVE_PATH"
echo "    Source: $HERMES_HOME"

# Create the archive (cd to parent so paths are relative to ~/.hermes)
tar -czf "$ARCHIVE_PATH" -C "$(dirname "$HERMES_HOME")" "${EXCLUDE_ARGS[@]}" "$(basename "$HERMES_HOME")"

ARCHIVE_SIZE="$(du -h "$ARCHIVE_PATH" | cut -f1)"
echo "[+] Archive created: $ARCHIVE_PATH ($ARCHIVE_SIZE)"
echo ""
echo "    To restore on another machine:"
echo "    bash scripts/restore-hermes.sh $ARCHIVE_PATH"
