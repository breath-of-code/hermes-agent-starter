# Hermes Agent Blueprint

A GitOps-driven, self-evolving Hermes Agent configuration framework. Clone this repo, sync, and your agent is ready — same identity, same skills, anywhere.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/your-username/hermes-agent-starter.git
cd hermes-agent-starter

# 2. Set up secrets
cp .env.example .env
# Edit .env with your API keys
# IMPORTANT: sync-config.sh does NOT copy .env to ~/.hermes/.
# Either copy it manually (`cp .env ~/.hermes/.env`) or source it before running Hermes.

# 3. Sync configs to ~/.hermes/
# Note: this copies the repo's config/config.yaml over ~/.hermes/config.yaml.
# Any local-only Hermes settings not in config/config.yaml will be replaced
# (the previous config is backed up with a .bak.<timestamp> suffix).
# Add persistent customizations to the repo's config/config.yaml instead.
bash scripts/sync-config.sh

# 4. Make secrets available to Hermes (sync-config.sh does not copy .env)
cp .env ~/.hermes/.env

# 5. Verify
hermes doctor
hermes chat -q "Hello, who am I?"
```

> **Why copy `.env` manually?** `scripts/sync-config.sh` intentionally does not overwrite `~/.hermes/.env` to avoid destroying secrets. Copy it once after editing.

## What's Inside

| Directory | Purpose |
|-----------|---------|
| `config/` | SOUL.md (persona) + config.yaml (agent settings) + tools.yaml + mcp.yaml + honcho.json + cron.yaml + cron-prompt.md |
| `skills/active/` | Production-validated skills |
| `skills/staging/` | New skills awaiting validation (3+ successful invocations) |
| `profiles/` | Per-context AGENTS.md directives (dev-ops, research) |
| `scripts/` | Utility scripts (sync-config.sh, sync-cron.sh, cron-health-check.sh, promote-skills.sh, backup-hermes.sh, restore-hermes.sh) |

## Model Selection

The `model:` block in `config/config.yaml` controls which AI model Hermes uses and how it behaves. After editing, run `bash scripts/sync-config.sh` to apply changes.

### Keys

| Key | Purpose | Example |
|-----|---------|---------|
| `default` | Model name/ID | `deepseek-v4-pro` |
| `provider` | Inference provider | `ollama-cloud`, `openrouter`, `anthropic` |
| `fallback_providers` | Backup providers tried in order on failure | See config.yaml comments |
| `reasoning_effort` | How much "thinking" the model does (under `agent:`) | `xhigh`, `high`, `medium`, `low`, `minimal`, `none` |
| `reasoning_overrides` | Per-model reasoning effort (under `agent:`) | `"deepseek-v4-pro": "xhigh"` |

### Examples

**OpenAI o3-mini with high reasoning:**
```yaml
model:
  default: o3-mini
  provider: openai-codex
agent:
  reasoning_effort: "high"
```

**Anthropic Claude Opus with fallback:**
```yaml
model:
  default: anthropic/claude-opus-4.6
  provider: openrouter
  fallback_providers:
    - provider: anthropic
      model: claude-sonnet-4
agent:
  reasoning_effort: "xhigh"
```

**Local Ollama with no reasoning overhead:**
```yaml
model:
  default: llama-3.1-70b
  provider: custom
  base_url: http://localhost:11434/v1
agent:
  reasoning_effort: "none"
```

> **Note:** `reasoning_effort` and `reasoning_overrides` live under `agent:`, not `model:`. See the commented examples in `config/config.yaml` for the full syntax. Configure fallback providers interactively with `hermes fallback add` or edit YAML directly.

## Skill Lifecycle

```
[Agent creates skill] → skills/staging/
        ↓
[3+ successful invocations] → promoted to skills/active/
        ↓
[Unused 30+ days] → curator marks stale
        ↓
[Stale 90+ days] → curator archives
```

## Daily Workflow

```bash
# Edit config/SOUL.md in the repo, then sync
bash scripts/sync-config.sh

# Commit changes (push handled manually by user)
git add -A
git commit -m "feat(skills): add new skill"
```

## Maintenance (Monthly)

```bash
cd ~/hermes-agent-starter
git pull origin main

# Sync repo configs to ~/.hermes/ (backs up existing ~/.hermes/config.yaml if changed).
# Local-only Hermes customizations should live in this repo's config/config.yaml,
# otherwise they will be replaced on each sync.
bash scripts/sync-config.sh

hermes curator run
cp ~/.hermes/skills/*.SKILL.md skills/active/ 2>/dev/null || true
git add -A && git commit -m "chore: monthly skill sync"
hermes update
```

## Memory

This blueprint is pre-configured for **Honcho** — an AI-native memory provider that learns who you are across conversations. Honcho runs alongside Hermes's built-in MEMORY.md/USER.md (always active as fallback).

### Activate Honcho
```bash
# 1. Get an API key at https://app.honcho.dev (or self-host)
# 2. Add it to .env:
#    HONCHO_API_KEY=hn-...

# 3. Run setup (interactive or direct):
hermes memory setup honcho
#   or: hermes memory setup  (pick Honcho from the list)

# 4. Verify:
hermes doctor
```

### Config files
- `config/honcho.json` — workspace, peers, cadence (synced by sync-config.sh)
- `.env` — `HONCHO_API_KEY` (never committed)
- `config/config.yaml` — uncomment `provider: honcho` under `memory:`

### Other providers
Hermes supports 8 memory providers: Honcho, OpenViking, Mem0, Hindsight, Holographic, RetainDB, ByteRover, Supermemory. See [Memory Providers](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory-providers/) for details.

### Full Honcho setup guide
For step-by-step instructions (cloud account, API key, `.env`, `honcho.json`, profiles, headless auth, troubleshooting), see [`docs/honcho-setup.md`](docs/honcho-setup.md).

## Memory Sync

The blueprint can sync Hermes's runtime memory files (`MEMORY.md` and `USER.md`) in both directions, making your agent's long-term memory portable across machines.

### Pull memory (runtime → repo)
Before committing, pull the latest memory from Hermes into the repo:

```bash
bash scripts/sync-config.sh --pull-memory
```

This copies `~/.hermes/MEMORY.md` → `config/MEMORY.md` and `~/.hermes/USER.md` → `config/USER.md`. Review the files before committing — they may contain sensitive information.

### Push memory (repo → runtime)
On a new machine, after cloning the repo, restore memory into Hermes:

```bash
bash scripts/sync-config.sh --push-memory
```

This copies `config/MEMORY.md` → `~/.hermes/MEMORY.md` and `config/USER.md` → `~/.hermes/USER.md`, backing up any existing runtime files first.

### Workflow
1. **On your primary machine:** `bash scripts/sync-config.sh --pull-memory` → review → `git add config/MEMORY.md config/USER.md` → commit
2. **On a new machine:** `git clone` → `bash scripts/sync-config.sh --push-memory` → `hermes chat`

> **Important:** `--sync-all` includes `--push-memory` (repo → runtime) but NOT `--pull-memory` (runtime → repo). Memory files must first be pulled on your primary machine and committed to the repo before they can be restored on other machines. If `config/MEMORY.md` and `config/USER.md` don't exist in the repo, `--sync-all` silently skips memory.

## Backup & Restore

`sync-config.sh` only syncs the version-controlled blueprint subset. To move your full Hermes runtime directory (`~/.hermes/`) to a new machine or recover from a corrupted install, use the backup/restore scripts.

### Backup
```bash
# Create a timestamped archive in backups/
bash scripts/backup-hermes.sh

# Or specify an output directory
bash scripts/backup-hermes.sh /path/to/backups

# Preview what would be included
bash scripts/backup-hermes.sh --dry-run
```

By default, the archive excludes secrets and volatile runtime files:
- `.env` and `.env.*`
- `MEMORY.md`, `USER.md`
- Logs, caches, `node_modules`, `__pycache__`, `*.pyc`

To include secrets (not recommended for shared archives):
```bash
bash scripts/backup-hermes.sh --include-secrets
```

### Restore
```bash
bash scripts/restore-hermes.sh backups/hermes-YYYYmmdd-HHMMSS.tar.gz
```

This backs up the current `~/.hermes/` to `~/.hermes.bak.<timestamp>` first, then extracts the archive. Use `--dry-run` to preview without making changes.

After restoring, copy your `.env` if it was excluded from the archive:
```bash
cp .env ~/.hermes/.env
hermes doctor
```

### Which tool to use when
| Tool | Use case |
|------|----------|
| `scripts/sync-config.sh` | Day-to-day sync of the version-controlled blueprint subset (SOUL.md, config.yaml, skills, profiles, etc.) |
| `scripts/backup-hermes.sh` + `scripts/restore-hermes.sh` | Full migration or disaster recovery of the entire `~/.hermes/` directory |

## Tools & MCP Sync

The blueprint can manage toolset and MCP server configurations independently from the main config, using YAML deep-merge to avoid overwriting local-only settings.

### Sync toolsets
```bash
bash scripts/sync-config.sh --sync-tools
```
Merges `config/tools.yaml` (platform_toolsets, known_plugin_toolsets, custom_toolsets) into `~/.hermes/config.yaml`. Use this to version-control which tools are enabled per platform.

### Sync MCP servers
```bash
bash scripts/sync-config.sh --sync-mcp
```
Merges `config/mcp.yaml` (MCP server definitions) into `~/.hermes/config.yaml`. Includes commented-out templates for filesystem, GitHub, PostgreSQL, Brave Search, and more.

### Sync everything (new machine)
```bash
bash scripts/sync-config.sh --sync-all
```
Runs core config sync + `--sync-tools` + `--sync-mcp` + `--sync-cron` + `--push-memory`. This is the recommended first-run command after cloning on a new machine.

> **Note:** `--sync-tools` and `--sync-mcp` use Python YAML deep-merge (not full replace), so local-only Hermes settings in `~/.hermes/config.yaml` are preserved. A backup is always created before merging.

## Cron Jobs

This blueprint ships ready-to-use cron job templates so you can set up autonomous task scheduling.

### What's included

| File | Purpose |
|------|---------|
| `config/cron.yaml` | Two example jobs (weekday + weekend) with schedules, max tasks, and toolsets |
| `config/cron-prompt.md` | The shared task prompt both jobs use |

### Activate

```bash
# Sync cron jobs only
bash scripts/sync-config.sh --sync-cron

# Or sync everything (includes cron)
bash scripts/sync-config.sh --sync-all
```

### Customize

Edit `config/cron.yaml` to change job names, schedules, max tasks, or toolsets. Edit `config/cron-prompt.md` to change the task prompt. Set `workdir` to your repo path. After editing, re-sync:

```bash
bash scripts/sync-config.sh --sync-cron
```

### Verify

```bash
hermes cron list
```

> **Note:** Cron jobs are idempotent — re-syncing updates existing jobs instead of creating duplicates. See `config/cron.yaml` and `config/cron-prompt.md` for the full configuration.

## Gateway Setup

Hermes can connect to messaging platforms (Telegram, Discord, Slack, Signal, WhatsApp, Email) so you can talk to your agent from anywhere.

### Quick setup (interactive)
```bash
hermes gateway setup
# Follow the prompts to connect Telegram, Discord, Slack, etc.
```

### Ready-to-use configs

Standalone gateway configs with step-by-step setup guides:

| Platform | Config | Guide |
|----------|--------|-------|
| Discord | `config/discord.yaml` | [`config/discord.md`](config/discord.md) |
| Telegram | `config/telegram.yaml` | [`config/telegram.md`](config/telegram.md) |

Each guide covers: prerequisites, step-by-step setup, token creation, `.env` configuration, sync command, and troubleshooting.

### Manual setup
```bash
# 1. Get tokens for your platform(s):
#    Telegram: create a bot via @BotFather → see config/telegram.md
#    Discord:  https://discord.com/developers/applications → see config/discord.md
#    Slack:    https://api.slack.com/apps

# 2. Add tokens to .env:
#    TELEGRAM_BOT_TOKEN=...
#    DISCORD_BOT_TOKEN=...

# 3. Merge gateway configs into ~/.hermes/config.yaml:
bash scripts/sync-config.sh --sync-gateway

# 4. Start the gateway:
hermes gateway
```

### Platform-specific options
See `config/discord.yaml` and `config/telegram.yaml` for options like `require_mention`, `auto_thread`, `allowed_channels`, and `allowed_chats`. Full docs: [Messaging Platforms](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/).

## Migration to a New Machine

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
git clone https://github.com/your-username/hermes-agent-starter.git
cd hermes-agent-starter
cp .env.example .env   # edit with real keys
bash scripts/sync-config.sh --sync-all   # core configs + tools + MCP + gateway + cron + memory
hermes doctor
```

## Platform Support

This blueprint is tested and intended to work on Windows (Git Bash), macOS, and Linux.

| Platform | Shell | Python | Notes |
|----------|-------|--------|-------|
| Windows | Git Bash / MSYS2 | `python` | All `.sh` scripts run in Git Bash. Use forward slashes for paths. |
| macOS | bash (Terminal / iTerm) | `python3` | Xcode Command Line Tools provide `git` and `make`. `sed -i` uses BSD syntax. |
| Linux | bash | `python3` | Standard on Ubuntu/Debian/Fedora. GNU `sed` and GNU coreutils expected. |

### Verify your setup
```bash
# 1. Scripts pass syntax check
for f in scripts/*.sh; do bash -n "$f" && echo "OK: $f"; done

# 2. YAML/JSON config files are valid
python3 -c "import yaml; yaml.safe_load(open('config/config.yaml').read())"
python3 -c "import yaml; yaml.safe_load(open('config/tools.yaml').read())"
python3 -c "import yaml; yaml.safe_load(open('config/mcp.yaml').read())"
python3 -c "import json; json.load(open('config/honcho.json'))"

# 3. Configs would sync cleanly (no files changed)
bash scripts/sync-config.sh --dry-run
```

### Known platform differences
- `python` vs `python3`: `scripts/sync-config.sh` detects the available command automatically. `scripts/promote-skills.sh` also prefers `python` but fall back to `python3`.
- `sed -i` syntax: `scripts/promote-skills.sh` branches on `OSTYPE` for macOS vs Linux/Windows.
- Path separators: the repo and scripts use forward slashes everywhere, which works on all three platforms.
