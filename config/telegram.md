# Telegram Gateway Setup

Connect Hermes to Telegram so you can chat with your agent from any device.

## Prerequisites

- A Telegram account
- The Telegram app (mobile or desktop)

## Step-by-Step

### 1. Create a Bot via @BotFather

1. Open Telegram and search for **@BotFather** (the official bot creation tool)
2. Start a chat and send: `/newbot`
3. Follow the prompts:
   - **Name:** e.g., "Hermes Agent" (display name)
   - **Username:** e.g., `hermes_agent_bot` (must end in `bot`)
4. @BotFather will reply with your **bot token** (looks like `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. (Optional) Set Bot Commands

Still in @BotFather, set up commands for your bot:

```
/setcommands
@hermes_agent_bot
start - Start a conversation
help - Show help
```

### 3. Add the Token to .env

```bash
# In your hermes-agent-starter directory:
echo "TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz" >> .env
```

### 4. Sync and Start

```bash
# Merge the Telegram config into ~/.hermes/config.yaml
bash scripts/sync-config.sh --sync-gateway

# Start the gateway
hermes gateway
```

### 5. Verify

1. Open Telegram and search for your bot's username (e.g., `@hermes_agent_bot`)
2. Start a chat and send: `hello`
3. The bot should respond

```bash
# Check gateway status
hermes gateway status
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `reactions` | `false` | Show emoji reactions on bot messages |
| `allowed_chats` | `""` (all) | Restrict to specific chat IDs |
| `rich_messages` | `true` | Use Markdown formatting in messages |

## Restricting Access

By default, anyone who finds your bot's username can chat with it. To restrict access:

1. Find your Telegram user ID (send `/start` to @userinfobot)
2. Add it to `allowed_chats` in `config/telegram.yaml`:
   ```yaml
   allowed_chats: ["123456789"]
   ```
3. Re-sync: `bash scripts/sync-config.sh --sync-gateway`

## Troubleshooting

**Bot doesn't respond:**
- Check `hermes gateway status` for errors
- Verify `TELEGRAM_BOT_TOKEN` is set in `.env`
- Make sure you've started a chat with the bot (bots can't initiate conversations)

**"401 Unauthorized" error:**
- The token is invalid or has been revoked
- Go to @BotFather, use `/revoke` to get a new token, and update `.env`

**Token leaked:**
- Go to @BotFather, send `/revoke` to revoke the old token
- @BotFather will give you a new token — update `.env` immediately
