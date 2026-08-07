#!/bin/bash
# sync-cron.sh — Sync cron jobs from config/cron.yaml into Hermes runtime
# Usage: bash scripts/sync-cron.sh [--dry-run|-n]
# Reads config/cron.yaml and config/cron-prompt.md, creates or updates
# cron jobs via `hermes cron create` / `hermes cron edit`.
# Idempotent — existing jobs are updated, not duplicated.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_YAML="$REPO_ROOT/config/cron.yaml"
PROMPT_FILE="$REPO_ROOT/config/cron-prompt.md"

DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: bash scripts/sync-cron.sh [--dry-run|-n]"
            exit 1
            ;;
    esac
done

# ── Prerequisites ──────────────────────────────────────────────

if [ ! -f "$CRON_YAML" ]; then
    echo "[-] Error: $CRON_YAML not found."
    exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
    echo "[-] Error: $PROMPT_FILE not found."
    exit 1
fi

if ! command -v hermes &>/dev/null; then
    echo "[-] Error: 'hermes' CLI not found in PATH."
    echo "    Is Hermes Agent installed? Run 'hermes doctor' to check."
    exit 1
fi

# ── Helpers ────────────────────────────────────────────────────

# Get the job ID for a given job name from `hermes cron list`.
# Returns the 12-char hex ID, or empty string if not found.
# Output format: ID is on the line immediately before "Name: <name>".
get_job_id() {
    local name="$1"
    hermes cron list 2>/dev/null | grep -B1 "Name:.*$name" | grep -oE '^  [0-9a-f]{12}' | awk '{print $1}' || true
}

# Substitute {{MAX_TASKS}} in the prompt with the given value.
build_prompt() {
    local max_tasks="$1"
    sed "s/{{MAX_TASKS}}/$max_tasks/g" "$PROMPT_FILE"
}

# ── Parse YAML with Python ─────────────────────────────────────

# Detect python command
if command -v python &>/dev/null; then
    PYTHON=python
elif command -v python3 &>/dev/null; then
    PYTHON=python3
else
    echo "[-] Error: Python not found — cannot parse YAML."
    exit 1
fi

# Normalize path for Python on Windows
normalize_path() {
    local p="$1"
    if command -v cygpath &>/dev/null; then
        p="$(cygpath -m "$p")"
    fi
    echo "$p" | sed 's|\\\\|/|g'
}

CRON_YAML_NORM="$(normalize_path "$CRON_YAML")"
PROMPT_FILE_NORM="$(normalize_path "$PROMPT_FILE")"

# Extract job definitions as JSON for shell processing
JOBS_JSON="$($PYTHON -c "
import yaml, json, sys
with open('$CRON_YAML_NORM') as f:
    data = yaml.safe_load(f)
jobs = data.get('jobs', [])
print(json.dumps(jobs))
")"

if [ -z "$JOBS_JSON" ] || [ "$JOBS_JSON" = "[]" ]; then
    echo "[-] No jobs defined in $CRON_YAML."
    exit 0
fi

# ── Process each job ────────────────────────────────────────────

JOB_COUNT=$($PYTHON -c "import json,sys; print(len(json.loads(sys.stdin.read())))" <<< "$JOBS_JSON")
echo "[+] Found $JOB_COUNT job(s) in $CRON_YAML"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in $($PYTHON -c "import json,sys; print(' '.join(str(i) for i in range(len(json.loads(sys.stdin.read())))))" <<< "$JOBS_JSON"); do
    NAME=$($PYTHON -c "import json,sys; print(json.loads(sys.stdin.read())[$i]['name'])" <<< "$JOBS_JSON")
    SCHEDULE=$($PYTHON -c "import json,sys; print(json.loads(sys.stdin.read())[$i]['schedule'])" <<< "$JOBS_JSON")
    MAX_TASKS=$($PYTHON -c "import json,sys; print(json.loads(sys.stdin.read())[$i]['max_tasks'])" <<< "$JOBS_JSON")
    TOOLSETS=$($PYTHON -c "import json,sys; print(','.join(json.loads(sys.stdin.read())[$i].get('toolsets',[])))" <<< "$JOBS_JSON")
    WORKDIR=$($PYTHON -c "import json,sys; print(json.loads(sys.stdin.read())[$i].get('workdir',''))" <<< "$JOBS_JSON")
    DELIVER=$($PYTHON -c "import json,sys; print(json.loads(sys.stdin.read())[$i].get('deliver','local'))" <<< "$JOBS_JSON")

    # Build the prompt with MAX_TASKS substituted
    PROMPT="$(build_prompt "$MAX_TASKS")"

    # Check if job already exists
    EXISTING_ID="$(get_job_id "$NAME")"

    if [ -n "$EXISTING_ID" ]; then
        # ── Update existing job ──
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would update job '$NAME' (id: $EXISTING_ID)"
            echo "    schedule: $SCHEDULE"
            echo "    max_tasks: $MAX_TASKS"
            echo "    toolsets: $TOOLSETS"
            echo "    workdir: $WORKDIR"
            echo "    deliver: $DELIVER"
        else
            echo "[~] Updating existing job: $NAME (id: $EXISTING_ID)"
            # Build edit command args
            EDIT_ARGS=(
                --schedule "$SCHEDULE"
                --prompt "$PROMPT"
                --workdir "$WORKDIR"
                --deliver "$DELIVER"
            )
            if hermes cron edit "${EDIT_ARGS[@]}" "$EXISTING_ID" 2>&1; then
                # `hermes cron edit` pauses the job — resume it
                hermes cron resume "$EXISTING_ID" >/dev/null 2>&1 || true
                echo "    [+] Updated successfully."
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo "    [-] Failed to update."
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    else
        # ── Create new job ──
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would create job '$NAME'"
            echo "    schedule: $SCHEDULE"
            echo "    max_tasks: $MAX_TASKS"
            echo "    toolsets: $TOOLSETS"
            echo "    workdir: $WORKDIR"
            echo "    deliver: $DELIVER"
        else
            echo "[+] Creating new job: $NAME"
            # Build create command args
            CREATE_ARGS=(
                --name "$NAME"
                --workdir "$WORKDIR"
                --deliver "$DELIVER"
            )
            # Add toolsets
            if [ -n "$TOOLSETS" ]; then
                IFS=',' read -ra TS_ARRAY <<< "$TOOLSETS"
                for ts in "${TS_ARRAY[@]}"; do
                    CREATE_ARGS+=(--skill "$ts")
                done
            fi
            if hermes cron create "${CREATE_ARGS[@]}" "$SCHEDULE" "$PROMPT" 2>&1; then
                echo "    [+] Created successfully."
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo "    [-] Failed to create."
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    fi
    echo ""
done

# ── Summary ────────────────────────────────────────────────────

if $DRY_RUN; then
    echo "[DRY-RUN] Done. No changes made."
else
    echo "[+] Done. $SUCCESS_COUNT succeeded, $FAIL_COUNT failed."
    if [ "$FAIL_COUNT" -gt 0 ]; then
        exit 1
    fi
fi
