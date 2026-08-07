# Discord Gateway Setup

Connect Hermes to Discord so you can chat with your agent from any server or DM.

## Prerequisites

- A Discord account
- A Discord server where you have "Manage Server" permission (or create a test server)

## Step-by-Step

### 1. Create a Discord Application

1. Go to https://discord.com/developers/applications
2. Click **New Application** (top right)
3. Name it (e.g., "Hermes Agent") and click **Create**

### 2. Create a Bot

1. In the left sidebar, click **Bot**
2. Click **Add Bot** → **Yes, do it!**
3. Under the **Token** section, click **Reset Token** → **Yes, do it!**
4. Copy the token (it looks like `MTIzNDU2Nzg5...`). You won't see it again.

### 3. Enable Required Intents

Still on the Bot page, under **Privileged Gateway Intents**:
- Turn ON **Message Content Intent** (required to read messages)
- Turn ON **Server Members Intent** (required for member info)

Click **Save Changes**.

### 4. Invite the Bot to Your Server

1. In the left sidebar, click **OAuth2** → **URL Generator**
2. Under **Scopes**, check:
   - `bot`
   - `applications.commands` (for slash commands)
3. Under **Bot Permissions**, check:
   - `Send Messages`
   - `Read Messages/View Channels`
   - `Read Message History`
   - `Create Public Threads`
   - `Send Messages in Threads`
   - `Add Reactions`
   - `Use Slash Commands`
4. Copy the generated URL at the bottom and open it in your browser
5. Select your server and click **Authorize**

### 5. Add the Token to .env

```bash
# In your hermes-agent-blueprint directory:
echo "DISCORD_BOT_TOKEN=MTIzNDU2Nzg5..." >> .env
```

### 6. Sync and Start

```bash
# Merge the Discord config into ~/.hermes/config.yaml
bash scripts/sync-config.sh --sync-gateway

# Start the gateway
hermes gateway
```

### 7. Verify

In your Discord server, type `@Hermes Agent hello` (or whatever you named the bot). The bot should respond.

```bash
# Check gateway status
hermes gateway status
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `require_mention` | `true` | Only respond when @mentioned |
| `auto_thread` | `true` | Create threads on @mention |
| `reactions` | `true` | Show emoji reactions on bot messages |
| `allowed_channels` | `""` (all) | Restrict to specific channel IDs |
| `free_response_channels` | `[]` | Channels where bot responds without @mention |

## Troubleshooting

**Bot doesn't respond:**
- Check `hermes gateway status` for errors
- Verify `DISCORD_BOT_TOKEN` is set in `.env`
- Ensure **Message Content Intent** is enabled in the Discord Developer Portal
- Make sure the bot has `Send Messages` and `Read Messages` permissions in the channel

**"Missing Access" error:**
- Re-invite the bot using the OAuth2 URL generator with the correct permissions

**Token leaked:**
- Go to Discord Developer Portal → Bot → **Reset Token** immediately
- Update `.env` with the new token
