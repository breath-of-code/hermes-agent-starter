#!/bin/bash
# promote-skills.sh — Auto-promote staging skills that meet promotion thresholds
# Part of hermes-agent-blueprint Phase 3 automation
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGING_DIR="${REPO_ROOT}/skills/staging"
ACTIVE_DIR="${REPO_ROOT}/skills/active"
CURATOR_RULES="${REPO_ROOT}/skills/.curator-rules.json"
LOG_FILE="${REPO_ROOT}/.hermes/promotion.log"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$ACTIVE_DIR"

# ── Read thresholds from curator rules ─────────────────────────

MIN_INVOCATIONS=3
if [ -f "$CURATOR_RULES" ]; then
    MIN_INVOCATIONS=$(python -c "import json; print(json.load(open('$CURATOR_RULES'))['curator']['min_successful_invocations'])" 2>/dev/null || echo 3)
fi

echo "=== Skill Promotion Run — $TIMESTAMP ===" | tee -a "$LOG_FILE"
echo "Threshold: min_successful_invocations = $MIN_INVOCATIONS" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# ── Scan staging skills ────────────────────────────────────────

PROMOTED=0
SKIPPED=0
ERRORS=0

if [ ! -d "$STAGING_DIR" ] || [ -z "$(ls -A "$STAGING_DIR"/*.SKILL.md 2>/dev/null || true)" ]; then
    echo "No staging skills found. Nothing to promote." | tee -a "$LOG_FILE"
    exit 0
fi

for skill_file in "$STAGING_DIR"/*.SKILL.md; do
    [ -f "$skill_file" ] || continue
    skill_name=$(basename "$skill_file")

    # Extract invocation_count and success_count from frontmatter
    invocation_count=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep "^invocation_count:" | awk '{print $2}' || echo "0")
    success_count=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep "^success_count:" | awk '{print $2}' || echo "0")

    # Guard against empty/missing frontmatter values
    : "${invocation_count:=0}"
    : "${success_count:=0}"

    echo "  [$skill_name] invocations=$invocation_count, successes=$success_count" | tee -a "$LOG_FILE"

    # Check if skill meets promotion threshold
    if [ "$success_count" -ge "$MIN_INVOCATIONS" ]; then
        # Check if already in active (skip if identical)
        if [ -f "$ACTIVE_DIR/$skill_name" ]; then
            echo "    SKIP: already exists in active/" | tee -a "$LOG_FILE"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi

        # Promote: copy to active, update last_verified
        cp "$skill_file" "$ACTIVE_DIR/$skill_name"
        # Update last_verified timestamp in the active copy
        # sed -i differs between BSD (macOS) and GNU (Linux); branch on OSTYPE
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^last_verified:.*/last_verified: $(date +%Y-%m-%d)/" "$ACTIVE_DIR/$skill_name"
        else
            sed -i "s/^last_verified:.*/last_verified: $(date +%Y-%m-%d)/" "$ACTIVE_DIR/$skill_name"
        fi
        echo "    PROMOTED → skills/active/$skill_name" | tee -a "$LOG_FILE"
        PROMOTED=$((PROMOTED + 1))
    else
        echo "    SKIP: below threshold (need $MIN_INVOCATIONS, have $success_count)" | tee -a "$LOG_FILE"
        SKIPPED=$((SKIPPED + 1))
    fi
done

# ── Summary ────────────────────────────────────────────────────

echo "" | tee -a "$LOG_FILE"
echo "Summary: promoted=$PROMOTED, skipped=$SKIPPED, errors=$ERRORS" | tee -a "$LOG_FILE"

# Write promotion status file
STATUS_FILE="${REPO_ROOT}/.hermes/promotion-status.json"
cat > "$STATUS_FILE" << JSONEOF
{
  "timestamp": "$TIMESTAMP",
  "threshold": $MIN_INVOCATIONS,
  "promoted": $PROMOTED,
  "skipped": $SKIPPED,
  "errors": $ERRORS
}
JSONEOF

echo "Status written to $STATUS_FILE" | tee -a "$LOG_FILE"

exit 0
