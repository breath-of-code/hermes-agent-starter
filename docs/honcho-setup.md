# Honcho Memory Provider Setup Guide

This guide explains how to activate **Honcho** as the external memory provider for Hermes. Honcho is an AI-native memory provider that learns who you are across conversations. It runs alongside Hermes's built-in `MEMORY.md` / `USER.md` (always active as fallback).

> **Docs:** [Hermes Memory Providers](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory-providers/) · [Honcho Integration](https://docs.honcho.dev/v3/guides/integrations/hermes)

---

## 1. Choose Cloud or Self-Hosted

| Option | Best For | Requirements |
|--------|----------|--------------|
| **Honcho Cloud** | Easiest setup, cross-machine sync | Account at https://app.honcho.dev |
| **Self-Hosted** | Privacy / offline / custom deployment | Running Honcho server (e.g., Docker) |

This blueprint defaults to Honcho Cloud: `baseUrl: https://api.honcho.dev` in `config/honcho.json`.

---

## 2. Install the Python Package

Hermes needs the `honcho-ai` package installed in the environment it runs from.

```bash
pip install honcho-ai
```

If you use a specific Python environment for Hermes, install it there.

---

## 3. Get an API Key

1. Go to https://app.honcho.dev
2. Sign up or log in
3. Navigate to **Settings → API Keys**
4. Create a new key and copy it

> **Never paste the key into a committed file.** It belongs only in `.env` (which is gitignored).

---

## 4. Configure `.env`

Edit the repo's `.env` (created from `.env.example`):

```bash
cp .env.example .env
nano .env          # or vim, code, etc.
```

Uncomment and fill in:

```bash
# Optional: Honcho memory provider (cloud: https://api.honcho.dev, or self-hosted)
# Get your key at https://app.honcho.dev → Settings → API Keys
HONCHO_API_KEY=hn-...
```

Then copy `.env` to `~/.hermes/.env` so Hermes can read it:

```bash
cp .env ~/.hermes/.env
```

> **Why copy manually?** `scripts/sync-config.sh` intentionally does NOT copy `.env` to avoid overwriting secrets on other machines.

---

## 5. Configure `config/honcho.json`

The repo ships with a template at `config/honcho.json`:

```json
{
  "_comment": "Honcho memory provider configuration for Hermes Agent. Copy to $HERMES_HOME/honcho.json (or ~/.honcho/config.json for global). API key goes in .env as HONCHO_API_KEY, NOT in this file.",
  "workspace": "hermes-blueprint",
  "peerName": "user",
  "aiPeer": "hermes",
  "baseUrl": "https://api.honcho.dev",
  "writeFrequency": "turn",
  "recallMode": "auto",
  "sessionStrategy": "default",
  "sessionPeerPrefix": false,
  "pinUserPeer": true,
  "observation": {
    "user": true,
    "assistant": true
  },
  "contextBudget": {
    "maxTokens": 4000,
    "maxMessages": 20
  },
  "dialectic": {
    "enabled": true,
    "interval": 10
  }
}
```

### Customization checklist
- **`workspace`**: shared environment. All your Hermes profiles see the same user identity inside one workspace.
- **`peerName`**: your user identity in Honcho. If you share the blueprint, change it to your name.
- **`aiPeer`**: the AI identity. Default `hermes` is fine for a single profile.
- **`baseUrl`**: leave as `https://api.honcho.dev` for cloud; change to your server URL for self-hosted.
- **`recallMode`**: `auto` (default), `hybrid`, `context`, or `tools`. `auto` lets Hermes decide.
- **`writeFrequency`**: `turn`, `async`, `session`, or integer N. `turn` writes every turn; `async` is lighter.
- **`sessionStrategy`**: `default`, `per-directory`, `per-repo`, `per-session`, `global`.

After editing, sync it into place:

```bash
bash scripts/sync-config.sh
```

This copies `config/honcho.json` to `~/.hermes/honcho.json`.

---

## 6. Enable Honcho in `config/config.yaml`

Uncomment the provider line under `memory:`:

```yaml
memory:
  memory_enabled: true
  user_profile_enabled: true
  nudge_interval: 10
  # External memory provider (optional — uncomment to activate)
  provider: honcho             # honcho | openviking | mem0 | hindsight | holographic | retaindb | byterover | supermemory
```

Then sync again:

```bash
bash scripts/sync-config.sh
```

---

## 7. Run the Setup Wizard

```bash
hermes memory setup honcho
```

This runs the Honcho-specific post-setup. It may prompt you to choose:
- **Browser auth** (default on machines with a browser)
- **Device code auth** (use this on headless cloud/SSH machines — it prints a code and link to approve in another browser)

If you already have a `~/.hermes/honcho.json`, the wizard will read and validate it.

---

## 8. Verify

```bash
hermes memory status
hermes doctor
hermes chat -q "What workspace am I connected to?"
```

You should see Honcho listed as the active memory provider.

---

## 9. Headless / Cloud Machine Setup

If you are installing on a remote server without a browser:

1. Run `hermes memory setup honcho`
2. When prompted, choose **device** authentication
3. The CLI prints a short code and a verification URL
4. Open the URL in a browser on any other machine
5. Approve the device
6. Return to the server — setup completes automatically

You can also pre-copy the API key via `.env` and skip the wizard entirely if `HONCHO_API_KEY` is set.

---

## 10. Profiles and Multiple AI Peers

Honcho models conversations as peers: one **user peer** (`peerName`) and one **AI peer** (`aiPeer`) per Hermes profile.

- The **workspace** is shared across profiles.
- The **user peer** is the same human across profiles.
- Each **AI peer** builds its own representation of you, so a `coder` profile can stay code-oriented while a `writer` profile stays editorial.

To add a new profile with its own Honcho peer:

```bash
hermes profile create coder --clone
```

This creates a `hermes.coder` block in `honcho.json` with `aiPeer: "coder"`, shared `workspace`, and inherited settings.

To backfill Honcho peers for existing profiles:

```bash
hermes honcho sync
```

---

## 11. Fine-Tuning Honcho Behavior

### Key knobs
| Key | Default | Description |
|-----|---------|-------------|
| `contextCadence` | `1` | Minimum turns between base-layer context refreshes |
| `dialecticCadence` | `2` | Minimum turns between dialectic LLM reasoning calls |
| `dialecticDepth` | `1` | Number of `.chat()` passes per dialectic invocation (1–3) |
| `dialecticReasoningLevel` | `low` | Base reasoning level: `minimal`, `low`, `medium`, `high`, `max` |
| `recallMode` | `hybrid` | `hybrid` (auto + tools), `context` (inject only), `tools` (tools only) |
| `writeFrequency` | `async` | `async`, `turn`, `session`, or integer N |
| `sessionStrategy` | `per-directory` | `per-directory`, `per-repo`, `per-session`, `global`, `default` |
| `contextBudget.maxTokens` | `4000` | Token budget for injected context per turn |

Lower `dialecticCadence` / higher `dialecticDepth` = richer memory but more API/LLM cost. Raise `contextCadence` to reduce Honcho API calls.

---

## 12. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `honcho-ai` not found | `pip install honcho-ai` in Hermes's Python environment |
| `HONCHO_API_KEY` missing | Verify `.env` is copied to `~/.hermes/.env` and contains `HONCHO_API_KEY=hn-...` |
| `honcho.json` not loaded | Run `bash scripts/sync-config.sh`; check `ls ~/.hermes/honcho.json` |
| Provider not active | Run `hermes memory setup honcho` or `hermes config set memory.provider honcho` |
| Headless auth fails | Use device-code auth at the wizard prompt |
| Data doesn't sync across machines | Ensure all machines use the same `workspace`, `peerName`, and `HONCHO_API_KEY` |

---

## 13. Built-In Memory Fallback

Even with Honcho enabled, Hermes keeps writing to `~/.hermes/MEMORY.md` and `~/.hermes/USER.md`. If Honcho is unavailable, the built-in files still carry your durable facts. You can sync them into the repo with:

```bash
bash scripts/sync-config.sh --pull-memory
```

Review the files before committing — they may contain sensitive information.
