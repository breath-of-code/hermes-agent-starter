# AGENTS.md — Hermes Agent Blueprint Project Instructions

## Project Identity
This is the **hermes-agent-blueprint** repo — a GitOps-driven configuration framework for Hermes Agent. It contains the SOUL.md persona, config.yaml, skills, profiles, and automation scripts that define user's Hermes Agent identity.

## Critical Rules

### No Git Push
- Commit locally with conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).
- **NEVER run `git push`.** user handles all pushes manually.
- T008 (Push to GitHub) is a manual task — skip it.

### Environment
- Hermes auto-generates environment hints (OS, shell, Python version, home directory) at session start — use those as ground truth.
- Use **bash** for shell commands — NOT PowerShell or cmd.exe.
- Use forward slashes for paths in terminal commands (works on all platforms).
- Prefer `uv` for Python package management if installed. Use `python` on Windows, `python3` on Linux/macOS.
- Working directory: the repo root (where this AGENTS.md lives).

### Script Quality
- All `.sh` scripts must pass `bash -n` syntax check.
- All scripts must be executable (`chmod +x`).
- Use `set -euo pipefail` in every script.

### File Conventions
- Never commit `.env` files, secrets, or API keys.
- `.hermes/` directory is gitignored — logs and status files go there.
- Skill files use `.SKILL.md` extension with YAML frontmatter.
- Config files: `config/SOUL.md` (persona), `config/config.yaml` (agent settings).

### Task Workflow
- Work from `TASKS.md` — it's the single source of truth for the backlog.
- Max 7 tasks per session.
- For each task: Analyze → Plan → Exec → Eval → Loop (max 3 iterations).
- Mark tasks `[x]` when done, `[!]` when blocked.
- Update the Session Log table after every task completion.
- When no pending tasks remain, search the web for Hermes updates and propose new improvement tasks.

### Commit Format
- `feat: description` — new feature or capability
- `fix: description` — bug fix
- `chore: description` — maintenance, config, scripts
- `docs: description` — documentation only
- `refactor: description` — code restructuring without behavior change

### Testing
- Before committing, verify:
  - All `.sh` scripts pass `bash -n`
  - YAML/JSON files are valid
  - No secrets in staged files (`git diff --cached -- .env`)
- Recommended: run `shellcheck` on scripts (catches semantic bugs `bash -n` misses)
