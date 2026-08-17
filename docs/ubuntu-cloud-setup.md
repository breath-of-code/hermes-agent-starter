# Ubuntu 24 Cloud Machine Setup Guide

This guide explains how to install Hermes Agent on an Ubuntu 24 cloud machine and clone the `hermes-agent-starter` repository using SSH.

---

## 1. Create a Dedicated User

Run these commands as root (or via an existing sudo user):

```bash
sudo adduser hermes
sudo usermod -aG sudo hermes
su - hermes
```

Run Hermes as a non-root user for safety. The agent executes shell commands on your behalf, and running it under a regular account limits the damage of mistakes or malicious instructions.

---

## 2. Generate an SSH Key

```bash
ssh-keygen -t ed25519 -C "hermes-cloud" -f ~/.ssh/id_ed25519
```

Press Enter twice to skip a passphrase, or set one if you prefer.

Add the key to the running SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Print the public key so you can add it to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the output. It looks like:

```
ssh-ed25519 AAAAC3NzaC... hermes-cloud
```

---

## 3. Add the SSH Key to GitHub

1. Go to https://github.com/settings/keys
2. Click **New SSH key**
3. Title: `hermes-cloud`
4. Paste the public key
5. Click **Add SSH key**

If you are cloning your own fork, make sure the key has write access to that repository.

---

## 4. Install Hermes Agent

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

This installs Hermes in user space under `~/.hermes`.

---

## 5. Clone the Blueprint Repository

```bash
git clone git@github.com:your-username/hermes-agent-starter.git
cd hermes-agent-starter
```

If you are using your own fork, replace `your-username` with your GitHub username.

---

## 6. Configure Secrets

### 6.1 Create `.env` from the template

```bash
cd ~/hermes-agent-starter
cp .env.example .env
```

### 6.2 Edit `.env`

Use `nano`:

```bash
nano .env
```

Nano shortcuts:

- Move cursor: arrow keys
- Save: `Ctrl + O`, then `Enter`
- Exit: `Ctrl + X`

Other editors:

```bash
vim .env          # press i to insert, Esc then :wq to save and exit
code .env         # if VS Code is installed
```

### 6.3 Fill in your keys

Uncomment the lines you need by removing the `#` at the start, then paste your real key after the `=`.

Example:

```bash
# LLM provider (matches config/config.yaml)
OLLAMA_API_KEY=your-ollama-key-here

# Optional: Honcho memory provider
HONCHO_API_KEY=hn-your-key-here

# Optional: Telegram gateway
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
```

Do **not** commit `.env`. It is already in `.gitignore` and must stay on the machine only.

### 6.4 Keep `.env` secret

- Never paste `.env` contents into chat, email, or public repositories.
- Never run `cat .env` in an untrusted environment.
- Use `source .env` only when you need the variables in the current shell.

---

## 7. Sync Configs to `~/.hermes/`

```bash
bash scripts/sync-config.sh
```

This copies `config/SOUL.md`, `config/config.yaml`, `config/honcho.json`, active skills, and profiles into `~/.hermes/`.

### Important: `sync-config.sh` does not copy `.env`

`scripts/sync-config.sh` intentionally does **not** copy `.env` to `~/.hermes/.env` to avoid accidentally overwriting secrets. You must make the API keys available to Hermes yourself.

Choose one of the following methods after editing `.env`:

**Option A — Create `~/.hermes/.env` (recommended):**

```bash
cp ~/hermes-agent-starter/.env ~/.hermes/.env
```

Verify it is in the right place:

```bash
ls -la ~/.hermes/.env
```

**Option B — Source the repo `.env` for the current shell only:**

```bash
cd ~/hermes-agent-starter
set -a
source .env
set +a
```

Variables loaded this way disappear when the shell closes. Use Option A for a persistent setup.

---

## 8. Verify the Installation

```bash
hermes doctor
hermes chat -q "Hello, who am I?"
```

---

## Optional: Auto-Load the SSH Key

Add this to `~/.bashrc` so the SSH key is loaded on every shell session:

```bash
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
```

---

## Notes

- Do not run Hermes as root unless you have an isolated, single-purpose VM and accept the risk.
- Do not mount the host Docker socket into a Hermes container. That gives the agent root-equivalent host access. Use Hermes's built-in `terminal.backend: docker` sandbox option instead.
- All secrets live in `.env`. The blueprint never commits `.env` files.
