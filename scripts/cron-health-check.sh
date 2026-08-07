#!/bin/bash
# cron-health-check.sh — Verify cron jobs are running and log health status
# Part of hermes-agent-blueprint Phase 3 automation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="${REPO_ROOT}/.hermes/cron-health.log"
STATUS_FILE="${REPO_ROOT}/.hermes/cron-status.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "$LOG_FILE")"

# ── Configuration ──────────────────────────────────────────────
# Cron jobs are defined in the hermes cron system (see 'hermes cron list').
# This script checks for the blueprint-builder job specifically in check_hermes_cron().

# ── Health Check Functions ─────────────────────────────────────

check_hermes_cron() {
    # Check if Hermes cron system is active
    if command -v hermes &>/dev/null; then
        local cron_output
        cron_output=$(hermes cron list 2>/dev/null || echo "ERROR: hermes cron list failed")
        if [[ "$cron_output" == ERROR:* ]]; then
            echo "FAIL: hermes cron list command failed"
            return 1
        fi
        if echo "$cron_output" | grep -q "blueprint-builder"; then
            echo "OK: blueprint-builder cron job found in hermes cron list"
            return 0
        else
            echo "WARN: blueprint-builder not found in hermes cron list"
            return 1
        fi
    else
        echo "FAIL: hermes CLI not found"
        return 1
    fi
}

check_recent_activity() {
    # Check if TASKS.md has been modified recently (indicates cron is working)
    local tasks_file="${REPO_ROOT}/TASKS.md"
    if [ -f "$tasks_file" ]; then
        local last_modified
        last_modified=$(stat -c %Y "$tasks_file" 2>/dev/null || stat -f %m "$tasks_file" 2>/dev/null)
        local now
        now=$(date +%s)
        local age_minutes=$(( (now - last_modified) / 60 ))

        if [ "$age_minutes" -lt 60 ]; then
            echo "OK: TASKS.md modified ${age_minutes}min ago (recent activity)"
            return 0
        elif [ "$age_minutes" -lt 180 ]; then
            echo "WARN: TASKS.md modified ${age_minutes}min ago (stale, but within window)"
            return 0
        else
            echo "FAIL: TASKS.md last modified ${age_minutes}min ago (no recent activity)"
            return 1
        fi
    else
        echo "FAIL: TASKS.md not found at $tasks_file"
        return 1
    fi
}

check_git_sync() {
    # Check if repo is in sync with remote.
    # In the no-push workflow, being ahead of origin/main is normal (user merges
    # locally). Being behind is actionable: the user needs to pull before syncing.
    # Network fetch is bounded with a timeout so the cron check doesn't hang.
    cd "$REPO_ROOT"

    local timeout_cmd
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 30"
    else
        timeout_cmd=""
    fi

    if ! $timeout_cmd git fetch origin main --quiet 2>/dev/null; then
        echo "WARN: cannot fetch from remote (offline or timeout)"
        return 0
    fi

    local behind
    behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "-1")
    local ahead
    ahead=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo "-1")

    if [ "$behind" -eq 0 ] && [ "$ahead" -eq 0 ]; then
        echo "OK: repo in sync with origin/main"
        return 0
    elif [ "$behind" -gt 0 ]; then
        echo "FAIL: repo behind origin/main by $behind commits — run 'git pull origin main'"
        return 1
    elif [ "$ahead" -gt 0 ]; then
        echo "OK: repo ahead of origin/main by $ahead commits (local commits awaiting user's manual push)"
        return 0
    else
        echo "FAIL: cannot determine sync status"
        return 1
    fi
}

# ── Main ───────────────────────────────────────────────────────

echo "=== Hermes Cron Health Check — $TIMESTAMP ===" | tee -a "$LOG_FILE"

FAILURES=0
WARNINGS=0
CHECKS_TOTAL=0
declare -a CHECK_RESULTS=()

run_check() {
    local name="$1"
    local result
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    result=$("$name" 2>&1) || true
    CHECK_RESULTS+=("$result")
    echo "  [$name] $result" | tee -a "$LOG_FILE"

    if [[ "$result" == FAIL:* ]]; then
        FAILURES=$((FAILURES + 1))
    elif [[ "$result" == WARN:* ]]; then
        WARNINGS=$((WARNINGS + 1))
    fi
}

run_check check_hermes_cron
run_check check_recent_activity
run_check check_git_sync

# ── Summary ────────────────────────────────────────────────────

SUMMARY="PASS"
if [ "$FAILURES" -gt 0 ]; then
    SUMMARY="FAIL"
elif [ "$WARNINGS" -gt 0 ]; then
    SUMMARY="WARN"
fi

echo "" | tee -a "$LOG_FILE"
echo "Summary: $SUMMARY (checks=$CHECKS_TOTAL, failures=$FAILURES, warnings=$WARNINGS)" | tee -a "$LOG_FILE"

# Write JSON status file
cat > "$STATUS_FILE" << JSONEOF
{
  "timestamp": "$TIMESTAMP",
  "status": "$SUMMARY",
  "checks_total": $CHECKS_TOTAL,
  "failures": $FAILURES,
  "warnings": $WARNINGS,
  "details": [
JSONEOF

for i in "${!CHECK_RESULTS[@]}"; do
    comma=","
    if [ "$i" -eq $((${#CHECK_RESULTS[@]} - 1)) ]; then
        comma=""
    fi
    echo "    \"${CHECK_RESULTS[$i]}\"$comma" >> "$STATUS_FILE"
done

echo "  ]" >> "$STATUS_FILE"
echo "}" >> "$STATUS_FILE"

echo "Status written to $STATUS_FILE" | tee -a "$LOG_FILE"

# Exit with appropriate code
if [ "$SUMMARY" = "FAIL" ]; then
    exit 1
else
    exit 0
fi
