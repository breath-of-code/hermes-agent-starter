#!/bin/bash
# lint-blueprint.sh — Run standard verification checks on the blueprint repo.
# Usage: bash scripts/lint-blueprint.sh [--skip-export] [--fast]
#   --skip-export    Skip the public-export verification (saves time).
#   --fast           Alias for --skip-export; quick routine check.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_EXPORT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-export|--fast)
            SKIP_EXPORT=true
            shift
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: bash scripts/lint-blueprint.sh [--skip-export|--fast]"
            exit 1
            ;;
    esac
done

ERRORS=0
WARNINGS=0

error() {
    echo "[-] $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo "[!] $1"
    WARNINGS=$((WARNINGS + 1))
}

ok() {
    echo "[+] $1"
}

echo "[+] Linting hermes-agent-blueprint..."
echo ""

# ── 1. Shell script syntax ───────────────────────────────────────
ok "Checking shell script syntax..."
for script in "$REPO_ROOT"/scripts/*.sh; do
    [ -f "$script" ] || continue
    if bash -n "$script"; then
        ok "  bash -n OK: $(basename "$script")"
    else
        error "bash -n failed: $script"
    fi
done
echo ""

# ── 2. YAML validity ─────────────────────────────────────────────
ok "Checking YAML files..."
PYTHON_CMD=""
if command -v python &>/dev/null; then
    PYTHON_CMD=python
elif command -v python3 &>/dev/null; then
    PYTHON_CMD=python3
else
    warn "Python not found — skipping YAML/JSON validation"
    PYTHON_CMD=""
fi

# Use relative paths for Python on Windows/MSYS, because native Python
# doesn't understand MSYS-style absolute paths like /d/foo.
cd "$REPO_ROOT"

if [ -n "$PYTHON_CMD" ]; then
    for yaml in config/*.yaml; do
        [ -f "$yaml" ] || continue
        if $PYTHON_CMD -c "import yaml; yaml.safe_load(open('$yaml').read())" 2>/dev/null; then
            ok "  YAML OK: $yaml"
        else
            error "YAML invalid: $yaml"
        fi
    done
fi
echo ""

# ── 3. JSON validity ─────────────────────────────────────────────
ok "Checking JSON files..."
if [ -n "$PYTHON_CMD" ]; then
    for json in config/*.json skills/.curator-rules.json; do
        [ -f "$json" ] || continue
        if $PYTHON_CMD -c "import json; json.load(open('$json'))" 2>/dev/null; then
            ok "  JSON OK: $json"
        else
            error "JSON invalid: $json"
        fi
    done
fi
echo ""

# ── 4. Staged secrets check ──────────────────────────────────────
ok "Checking for staged secrets..."
cd "$REPO_ROOT"
if [ -n "$(git diff --cached --name-only 2>/dev/null)" ]; then
    if git diff --cached -- .env >/dev/null 2>&1 && [ -n "$(git diff --cached -- .env 2>/dev/null)" ]; then
        error "Staged changes include .env or .env-like files — do not commit secrets"
    else
        ok "  No .env files staged"
    fi
else
    ok "  No staged changes"
fi

# Also warn if .env exists in repo root (it should be gitignored, but confirm)
if [ -f "$REPO_ROOT/.env" ]; then
    warn ".env file exists at repo root — ensure it is gitignored and not committed"
else
    ok "  No .env file in repo root"
fi
echo ""

# ── 5. Public export verification ────────────────────────────────
if ! $SKIP_EXPORT; then
    ok "Running public export verification (use --skip-export to skip)..."
    EXPORT_DIR="/tmp/hermes-agent-blueprint-lint-public"
    if bash "$REPO_ROOT/scripts/export-public.sh" "$EXPORT_DIR" >/dev/null 2>&1; then
        ok "  Public export verified successfully"
        rm -rf "$EXPORT_DIR"
    else
        error "Public export verification failed (run scripts/export-public.sh manually for details)"
    fi
else
    warn "Skipping public export verification (--skip-export set)"
fi
echo ""

# ── Summary ──────────────────────────────────────────────────────
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "[+] All checks passed."
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    echo "[!] Lint passed with $WARNINGS warning(s)."
    exit 0
else
    echo "[-] Lint failed: $ERRORS error(s), $WARNINGS warning(s)."
    exit 1
fi
