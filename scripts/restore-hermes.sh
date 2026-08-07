#!/bin/bash
# restore-hermes.sh — Restore ~/.hermes/ from an archive created by backup-hermes.sh
# Usage: bash scripts/restore-hermes.sh [--dry-run|-n] <archive_path>
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
DRY_RUN=false
ARCHIVE_PATH=""

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo "Unknown flag: $1"
            echo "Usage: bash scripts/restore-hermes.sh [--dry-run|-n] <archive_path>"
            exit 1
            ;;
        *)
            ARCHIVE_PATH="$1"
            shift
            ;;
    esac
done

# Validate archive path
if [ -z "$ARCHIVE_PATH" ]; then
    echo "Usage: bash scripts/restore-hermes.sh [--dry-run|-n] <archive_path>"
    echo ""
    echo "  archive_path  Path to a .tar.gz archive created by backup-hermes.sh"
    exit 1
fi

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "[-] Error: Archive not found: $ARCHIVE_PATH"
    exit 1
fi

# Validate archive is a tar.gz
if ! tar -tzf "$ARCHIVE_PATH" >/dev/null 2>&1; then
    echo "[-] Error: $ARCHIVE_PATH is not a valid tar.gz archive"
    exit 1
fi

# Check what's in the archive
ARCHIVE_CONTENTS="$(tar -tzf "$ARCHIVE_PATH" | head -20)"
ARCHIVE_FILE_COUNT="$(tar -tzf "$ARCHIVE_PATH" | wc -l)"

if $DRY_RUN; then
    echo "[DRY-RUN] Would restore from: $ARCHIVE_PATH"
    echo "[DRY-RUN] Archive contains $ARCHIVE_FILE_COUNT files"
    echo "[DRY-RUN] First 20 entries:"
    echo "$ARCHIVE_CONTENTS" | sed 's/^/  /'
    echo ""

    if [ -d "$HERMES_HOME" ]; then
        echo "[DRY-RUN] Current ~/.hermes/ exists — would back up to ~/.hermes.bak.$(date +%Y%m%d_%H%M%S)"
    else
        echo "[DRY-RUN] Current ~/.hermes/ does not exist — would create fresh"
    fi

    echo "[DRY-RUN] Would extract archive to $HOME"
    echo "[DRY-RUN] Done. No files were modified."
    exit 0
fi

# Defensive: refuse if HERMES_HOME exists but is not a directory
if [ -e "$HERMES_HOME" ] && [ ! -d "$HERMES_HOME" ]; then
    echo "[-] Error: $HERMES_HOME exists but is not a directory."
    echo "    This is unexpected. Please investigate before restoring."
    exit 1
fi

# Back up current ~/.hermes/ if it exists
if [ -d "$HERMES_HOME" ]; then
    BACKUP_DIR="$HOME/.hermes.bak.$(date +%Y%m%d_%H%M%S)"
    echo "[+] Backing up current ~/.hermes/ to $BACKUP_DIR"
    cp -r "$HERMES_HOME" "$BACKUP_DIR"
    echo "    Backup complete: $BACKUP_DIR"
    echo ""
fi

# Extract archive
echo "[+] Restoring from: $ARCHIVE_PATH"
echo "    Archive contains $ARCHIVE_FILE_COUNT files"
tar -xzf "$ARCHIVE_PATH" -C "$HOME"
echo "    Extraction complete."

echo ""
echo "[+] Restore finished."
echo ""
echo "    Next steps:"
echo "    1. Copy your .env if it was excluded from the archive:"
echo "       cp /path/to/your/.env ~/.hermes/.env"
echo "    2. Verify the installation:"
echo "       hermes doctor"
echo "    3. Restart Hermes if it's running."
echo ""
echo "    If something went wrong, your previous ~/.hermes/ is backed up at:"
if [ -d "$HERMES_HOME" ] && [ -n "${BACKUP_DIR:-}" ]; then
    echo "    $BACKUP_DIR"
else
    echo "    (no backup was needed — ~/.hermes/ did not exist before restore)"
fi
