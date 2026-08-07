#!/bin/bash
# sync-config.sh — Copy repo configs into ~/.hermes/ (and vice versa for memory)
# Usage: bash scripts/sync-config.sh [--dry-run|-n] [--pull-memory] [--push-memory] [--sync-tools] [--sync-mcp] [--sync-gateway] [--sync-cron] [--sync-all]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# ── Platform detection ──────────────────────────────────────────
# Used to select the right python command and sed syntax.
# On Windows (Git Bash/MSYS): python, GNU sed. HERMES_HOME defaults to $HOME/.hermes.
# On macOS: python3, BSD sed (sed -i '').
# On Linux: python3, GNU sed (sed -i).
detect_os() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)  echo "windows" ;;
        Darwin)                 echo "macos"   ;;
        Linux)                  echo "linux"   ;;
        *)                      echo "unknown" ;;
    esac
}
OS="$(detect_os)"

# Detect python command (python on Windows, python3 on Linux/macOS)
if command -v python &>/dev/null; then
    PYTHON=python
elif command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=""
fi

# Normalize path to forward slashes (Python on Windows chokes on backslashes in -c strings)
# Also converts MSYS paths like /d/foo to Windows paths like D:/foo
normalize_path() {
    local p="$1"
    # If cygpath is available (Git Bash/MSYS), convert to Windows mixed path
    if command -v cygpath &>/dev/null; then
        p="$(cygpath -m "$p")"
    fi
    # Ensure forward slashes
    echo "$p" | sed 's|\\|/|g'
}

# Parse flags
DRY_RUN=false
PULL_MEMORY=false
PUSH_MEMORY=false
SYNC_TOOLS=false
SYNC_MCP=false
SYNC_GATEWAY=false
SYNC_CRON=false
SYNC_ALL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --pull-memory)
            PULL_MEMORY=true
            shift
            ;;
        --push-memory)
            PUSH_MEMORY=true
            shift
            ;;
        --sync-tools)
            SYNC_TOOLS=true
            shift
            ;;
        --sync-mcp)
            SYNC_MCP=true
            shift
            ;;
        --sync-gateway)
            SYNC_GATEWAY=true
            shift
            ;;
        --sync-cron)
            SYNC_CRON=true
            shift
            ;;
        --sync-all)
            SYNC_ALL=true
            shift
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: bash scripts/sync-config.sh [--dry-run|-n] [--pull-memory] [--push-memory] [--sync-tools] [--sync-mcp] [--sync-gateway] [--sync-cron] [--sync-all]"
            exit 1
            ;;
    esac
done

# --sync-all implies all sub-syncs
if $SYNC_ALL; then
    SYNC_TOOLS=true
    SYNC_MCP=true
    SYNC_GATEWAY=true
    SYNC_CRON=true
    PUSH_MEMORY=true
fi

if $DRY_RUN; then
    echo "[DRY-RUN] Would sync configs between $REPO_ROOT and $HERMES_HOME"
    echo ""
fi

# Helper: execute or print depending on DRY_RUN
run_cmd() {
    if $DRY_RUN; then
        echo "  [DRY-RUN] $*"
    else
        "$@"
    fi
}

# Helper: conditional echo for dry-run
dry_echo() {
    if $DRY_RUN; then
        echo "  [DRY-RUN] $*"
    else
        echo "$*"
    fi
}

# Validate HERMES_HOME exists
if [ ! -d "$HERMES_HOME" ]; then
    if $DRY_RUN; then
        echo "  [DRY-RUN] Would fail: HERMES_HOME ($HERMES_HOME) does not exist."
        echo "  [DRY-RUN] Would exit with code 1"
        exit 0
    fi
    echo "[-] Error: HERMES_HOME ($HERMES_HOME) does not exist."
    echo "    Is Hermes Agent installed? Run 'hermes doctor' to check."
    exit 1
fi

if ! $DRY_RUN; then
    echo "[+] Copying configs from $REPO_ROOT to $HERMES_HOME"
fi

# SOUL.md — identity
if [ -f "$REPO_ROOT/config/SOUL.md" ]; then
    run_cmd cp "$REPO_ROOT/config/SOUL.md" "$HERMES_HOME/SOUL.md"
    dry_echo "    SOUL.md → $HERMES_HOME/SOUL.md"
fi

# config.yaml — agent configuration (version-controlled subset)
if [ -f "$REPO_ROOT/config/config.yaml" ]; then
    # Backup existing config if it exists and differs
    if [ -f "$HERMES_HOME/config.yaml" ]; then
        if ! cmp -s "$REPO_ROOT/config/config.yaml" "$HERMES_HOME/config.yaml"; then
            BACKUP="$HERMES_HOME/config.yaml.bak.$(date +%Y%m%d_%H%M%S)"
            run_cmd cp "$HERMES_HOME/config.yaml" "$BACKUP"
            dry_echo "    Backed up existing config to $BACKUP"
        else
            dry_echo "    config.yaml unchanged — skipping backup"
        fi
    fi
    run_cmd cp "$REPO_ROOT/config/config.yaml" "$HERMES_HOME/config.yaml"
    dry_echo "    config.yaml → $HERMES_HOME/config.yaml"
fi

# Skills — merge repo skills into ~/.hermes/skills/
if [ -d "$REPO_ROOT/skills/active" ]; then
    run_cmd mkdir -p "$HERMES_HOME/skills/"
    run_cmd cp -r "$REPO_ROOT/skills/active/"* "$HERMES_HOME/skills/" 2>/dev/null || true
    dry_echo "    skills/active/* → $HERMES_HOME/skills/"
fi

# Profiles — copy AGENTS.md files
if [ -d "$REPO_ROOT/profiles" ]; then
    run_cmd mkdir -p "$HERMES_HOME/profiles/"
    run_cmd cp -r "$REPO_ROOT/profiles/"* "$HERMES_HOME/profiles/" 2>/dev/null || true
    dry_echo "    profiles/* → $HERMES_HOME/profiles/"
fi

# honcho.json — memory provider config (if present)
if [ -f "$REPO_ROOT/config/honcho.json" ]; then
    if [ -f "$HERMES_HOME/honcho.json" ]; then
        if ! cmp -s "$REPO_ROOT/config/honcho.json" "$HERMES_HOME/honcho.json"; then
            BACKUP="$HERMES_HOME/honcho.json.bak.$(date +%Y%m%d_%H%M%S)"
            run_cmd cp "$HERMES_HOME/honcho.json" "$BACKUP"
            dry_echo "    Backed up existing honcho.json to $BACKUP"
        else
            dry_echo "    honcho.json unchanged — skipping backup"
        fi
    fi
    run_cmd cp "$REPO_ROOT/config/honcho.json" "$HERMES_HOME/honcho.json"
    dry_echo "    honcho.json → $HERMES_HOME/honcho.json"
fi

# --- Tools sync: merge config/tools.yaml into ~/.hermes/config.yaml ---
if $SYNC_TOOLS; then
    dry_echo ""
    dry_echo "[+] Merging tools config from $REPO_ROOT/config/tools.yaml into $HERMES_HOME/config.yaml"
    if [ ! -f "$REPO_ROOT/config/tools.yaml" ]; then
        dry_echo "    (skip) config/tools.yaml not found"
    elif [ -z "$PYTHON" ]; then
        dry_echo "    (skip) Python not found — cannot merge YAML"
    else
        # Backup existing config before merge
        if [ -f "$HERMES_HOME/config.yaml" ]; then
            BACKUP="$HERMES_HOME/config.yaml.bak.$(date +%Y%m%d_%H%M%S)"
            run_cmd cp "$HERMES_HOME/config.yaml" "$BACKUP"
            dry_echo "    Backed up existing config to $BACKUP"
        fi
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would deep-merge config/tools.yaml into $HERMES_HOME/config.yaml"
        else
            HERMES_CFG="$(normalize_path "$HERMES_HOME/config.yaml")"
            TOOLS_YAML="$(normalize_path "$REPO_ROOT/config/tools.yaml")"
            $PYTHON -c "
import yaml, sys
# Load base config (or empty dict if missing)
try:
    with open('$HERMES_CFG') as f:
        base = yaml.safe_load(f) or {}
except FileNotFoundError:
    base = {}

# Load tools overlay
with open('$TOOLS_YAML') as f:
    overlay = yaml.safe_load(f) or {}

# Deep merge: overlay keys into base (overlay wins on conflict)
def deep_merge(base_dict, overlay_dict):
    for key, value in overlay_dict.items():
        if key in base_dict and isinstance(base_dict[key], dict) and isinstance(value, dict):
            deep_merge(base_dict[key], value)
        else:
            base_dict[key] = value

deep_merge(base, overlay)

# Write back
with open('$HERMES_CFG', 'w') as f:
    yaml.dump(base, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
"
            echo "    config/tools.yaml merged into $HERMES_HOME/config.yaml"
        fi
    fi
fi

# --- MCP sync: merge config/mcp.yaml into ~/.hermes/config.yaml ---
if $SYNC_MCP; then
    dry_echo ""
    dry_echo "[+] Merging MCP config from $REPO_ROOT/config/mcp.yaml into $HERMES_HOME/config.yaml"
    if [ ! -f "$REPO_ROOT/config/mcp.yaml" ]; then
        dry_echo "    (skip) config/mcp.yaml not found"
    elif [ -z "$PYTHON" ]; then
        dry_echo "    (skip) Python not found — cannot merge YAML"
    else
        # Backup existing config before merge (skip if already backed up by --sync-tools in same run)
        if [ -f "$HERMES_HOME/config.yaml" ] && ! $SYNC_TOOLS; then
            BACKUP="$HERMES_HOME/config.yaml.bak.$(date +%Y%m%d_%H%M%S)"
            run_cmd cp "$HERMES_HOME/config.yaml" "$BACKUP"
            dry_echo "    Backed up existing config to $BACKUP"
        fi
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would deep-merge config/mcp.yaml into $HERMES_HOME/config.yaml"
        else
            HERMES_CFG="$(normalize_path "$HERMES_HOME/config.yaml")"
            MCP_YAML="$(normalize_path "$REPO_ROOT/config/mcp.yaml")"
            $PYTHON -c "
import yaml, sys
# Load base config (or empty dict if missing)
try:
    with open('$HERMES_CFG') as f:
        base = yaml.safe_load(f) or {}
except FileNotFoundError:
    base = {}

# Load MCP overlay
with open('$MCP_YAML') as f:
    overlay = yaml.safe_load(f) or {}

# Deep merge: overlay keys into base (overlay wins on conflict)
def deep_merge(base_dict, overlay_dict):
    for key, value in overlay_dict.items():
        if key in base_dict and isinstance(base_dict[key], dict) and isinstance(value, dict):
            deep_merge(base_dict[key], value)
        else:
            base_dict[key] = value

deep_merge(base, overlay)

# Write back
with open('$HERMES_CFG', 'w') as f:
    yaml.dump(base, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
"
            echo "    config/mcp.yaml merged into $HERMES_HOME/config.yaml"
        fi
    fi
fi

# --- Gateway sync: merge config/discord.yaml and config/telegram.yaml into ~/.hermes/config.yaml ---
if $SYNC_GATEWAY; then
    dry_echo ""
    dry_echo "[+] Merging gateway configs from $REPO_ROOT/config/ into $HERMES_HOME/config.yaml"
    GATEWAY_FILES=()
    [ -f "$REPO_ROOT/config/discord.yaml" ] && GATEWAY_FILES+=("$REPO_ROOT/config/discord.yaml")
    [ -f "$REPO_ROOT/config/telegram.yaml" ] && GATEWAY_FILES+=("$REPO_ROOT/config/telegram.yaml")

    if [ ${#GATEWAY_FILES[@]} -eq 0 ]; then
        dry_echo "    (skip) No gateway config files found (config/discord.yaml, config/telegram.yaml)"
    elif [ -z "$PYTHON" ]; then
        dry_echo "    (skip) Python not found — cannot merge YAML"
    else
        # Backup existing config before merge (skip if already backed up by --sync-tools or --sync-mcp in same run)
        if [ -f "$HERMES_HOME/config.yaml" ] && ! $SYNC_TOOLS && ! $SYNC_MCP; then
            BACKUP="$HERMES_HOME/config.yaml.bak.$(date +%Y%m%d_%H%M%S)"
            run_cmd cp "$HERMES_HOME/config.yaml" "$BACKUP"
            dry_echo "    Backed up existing config to $BACKUP"
        fi
        for GW_FILE in "${GATEWAY_FILES[@]}"; do
            GW_NAME="$(basename "$GW_FILE")"
            if $DRY_RUN; then
                echo "  [DRY-RUN] Would deep-merge $GW_NAME into $HERMES_HOME/config.yaml"
            else
                HERMES_CFG="$(normalize_path "$HERMES_HOME/config.yaml")"
                GW_YAML="$(normalize_path "$GW_FILE")"
                $PYTHON -c "
import yaml, sys
# Load base config (or empty dict if missing)
try:
    with open('$HERMES_CFG') as f:
        base = yaml.safe_load(f) or {}
except FileNotFoundError:
    base = {}

# Load gateway overlay
with open('$GW_YAML') as f:
    overlay = yaml.safe_load(f) or {}

# Deep merge: overlay keys into base (overlay wins on conflict)
def deep_merge(base_dict, overlay_dict):
    for key, value in overlay_dict.items():
        if key in base_dict and isinstance(base_dict[key], dict) and isinstance(value, dict):
            deep_merge(base_dict[key], value)
        else:
            base_dict[key] = value

deep_merge(base, overlay)

# Write back
with open('$HERMES_CFG', 'w') as f:
    yaml.dump(base, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
"
                echo "    $GW_NAME merged into $HERMES_HOME/config.yaml"
            fi
        done
    fi
fi

# --- Memory sync: runtime → repo (--pull-memory) ---
if $PULL_MEMORY; then
    dry_echo ""
    dry_echo "[+] Pulling memory from $HERMES_HOME into $REPO_ROOT/config/"
    for MEMFILE in MEMORY.md USER.md; do
        if [ -f "$HERMES_HOME/$MEMFILE" ]; then
            run_cmd cp "$HERMES_HOME/$MEMFILE" "$REPO_ROOT/config/$MEMFILE"
            dry_echo "    $HERMES_HOME/$MEMFILE → $REPO_ROOT/config/$MEMFILE"
        else
            dry_echo "    (skip) $HERMES_HOME/$MEMFILE not found"
        fi
    done
    dry_echo "    Review config/MEMORY.md and config/USER.md before committing — they may contain sensitive info."
fi

# --- Memory sync: repo → runtime (--push-memory) ---
if $PUSH_MEMORY; then
    dry_echo ""
    dry_echo "[+] Pushing memory from $REPO_ROOT/config/ into $HERMES_HOME"
    for MEMFILE in MEMORY.md USER.md; do
        if [ -f "$REPO_ROOT/config/$MEMFILE" ]; then
            # Backup existing runtime file if it exists and differs
            if [ -f "$HERMES_HOME/$MEMFILE" ]; then
                if ! cmp -s "$REPO_ROOT/config/$MEMFILE" "$HERMES_HOME/$MEMFILE"; then
                    BACKUP="$HERMES_HOME/${MEMFILE}.bak.$(date +%Y%m%d_%H%M%S)"
                    run_cmd cp "$HERMES_HOME/$MEMFILE" "$BACKUP"
                    dry_echo "    Backed up existing $MEMFILE to $BACKUP"
                else
                    dry_echo "    $MEMFILE unchanged — skipping backup"
                fi
            fi
            run_cmd cp "$REPO_ROOT/config/$MEMFILE" "$HERMES_HOME/$MEMFILE"
            dry_echo "    $REPO_ROOT/config/$MEMFILE → $HERMES_HOME/$MEMFILE"
        else
            dry_echo "    (skip) $REPO_ROOT/config/$MEMFILE not found"
        fi
    done
fi

# --- Cron sync: sync cron jobs from config/cron.yaml into Hermes runtime ---
if $SYNC_CRON; then
    dry_echo ""
    dry_echo "[+] Syncing cron jobs from $REPO_ROOT/config/cron.yaml"
    if [ -f "$REPO_ROOT/scripts/sync-cron.sh" ]; then
        if $DRY_RUN; then
            run_cmd bash "$REPO_ROOT/scripts/sync-cron.sh" --dry-run
        else
            bash "$REPO_ROOT/scripts/sync-cron.sh"
        fi
    else
        dry_echo "    (skip) scripts/sync-cron.sh not found"
    fi
fi

if $DRY_RUN; then
    echo ""
    echo "[DRY-RUN] Done. No files were modified."
else
    echo "[+] Done. Restart Hermes or run /reload-skills to pick up changes."
fi
