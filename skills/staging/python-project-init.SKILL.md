---
id: python-project-init
title: Python Project Initialization with uv, pytest, and pre-commit
tags: [coding, automation]
version: 1.0.0
last_verified: 2026-07-26
invocation_count: 0
success_count: 0
---

# Intent
Initializes a new Python project with a modern toolchain: `uv` for package management, `pytest` for testing, `pre-commit` for linting/formatting hooks, and a standard `src` layout. Produces a project ready for immediate development.

# Prerequisites
- Python 3.11+ installed
- `uv` package manager installed (`pip install uv` or `curl -LsSf https://astral.sh/uv/install.sh | sh`)
- Git installed

# Procedure
1. Accept the project name as input. If not provided, ask for it. Slugify: lowercase, hyphens for spaces.
2. Create the project directory and navigate into it:
   ```bash
   mkdir <project-name> && cd <project-name>
   ```
3. Initialize git:
   ```bash
   git init
   ```
4. Initialize the Python project with uv:
   ```bash
   uv init --app --python 3.11
   ```
5. Set up src layout. Move the generated package into `src/`:
   ```bash
   mkdir -p src/<package-name>
   mv <package-name>/* src/<package-name>/ 2>/dev/null || true
   rmdir <package-name> 2>/dev/null || true
   ```
   If uv created a flat layout, create `src/<package-name>/__init__.py` manually.
6. Add dev dependencies:
   ```bash
   uv add --dev pytest pytest-cov pre-commit ruff mypy
   ```
7. Create `tests/` directory with a placeholder test:
   ```bash
   mkdir tests
   ```
   Create `tests/test_placeholder.py`:
   ```python
   def test_import():
       """Verify the package is importable."""
       import <package-name>
       assert <package-name> is not None
   ```
8. Create `.pre-commit-config.yaml`:
   ```yaml
   repos:
     - repo: https://github.com/astral-sh/ruff-pre-commit
       rev: v0.11.0
       hooks:
         - id: ruff
           args: [--fix]
         - id: ruff-format
     - repo: https://github.com/pre-commit/mirrors-mypy
       rev: v1.15.0
       hooks:
         - id: mypy
           args: [--ignore-missing-imports]
   ```
9. Install pre-commit hooks:
   ```bash
   uv run pre-commit install
   ```
10. Create `.gitignore` with Python-appropriate entries:
    ```
    __pycache__/
    *.pyc
    .venv/
    .pytest_cache/
    .mypy_cache/
    .ruff_cache/
    dist/
    *.egg-info/
    .env
    ```
11. Run the placeholder test to verify everything works:
    ```bash
    uv run pytest tests/ -v
    ```
12. Create initial commit:
    ```bash
    git add -A
    git commit -m "chore: initial project scaffold with uv, pytest, pre-commit"
    ```
13. Report: project name, Python version, installed packages, and test result.

# Error Handling
- If `uv` is not installed: report "uv is not installed. Install it with: pip install uv" and abort.
- If Python 3.11 is not available: report the available Python version and abort.
- If `uv init` fails: report the error and abort.
- If `uv add` fails for any package: report which package failed and continue with the rest.
- If `pytest` fails: report the test failure output. Do NOT commit.
- If `pre-commit install` fails: report the error but continue (hooks can be installed later).
