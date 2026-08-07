# Slack Gateway Setup Guide

A step-by-step guide to connecting Hermes to Slack so you can chat with your agent from any Slack workspace.

## Prerequisites

- A Slack workspace where you have permission to install apps.
- A few minutes in the [Slack API Console](https://api.slack.com/apps).

## Step 1 — Create a Slack app

1. Go to https://api.slack.com/apps.
2. Click **Create New App**.
3. Choose **From scratch**.
4. Enter an app name (e.g., `hermes-agent`) and pick your workspace.
5. Click **Create App**.

## Step 2 — Add bot scopes

1. In the left sidebar, go to **OAuth & Permissions**.
2. Scroll down to **Scopes** → **Bot Token Scopes**.
3. Add the following scopes:
   - `chat:write`
   - `channels:history`
   - `app_mentions:read`
   - `im:history`
   - `im:write`

## Step 3 — Install the app to your workspace

1. At the top of **OAuth & Permissions**, click **Install to Workspace**.
2. Review permissions and click **Allow**.
3. Copy the **Bot User OAuth Token** (starts with `xoxb-`).

## Step 4 — Enable Socket Mode

Socket Mode lets your bot receive events without exposing a public URL.

1. In the left sidebar, go to **Socket Mode**.
2. Toggle **Enable Socket Mode** to **On**.
3. You'll be prompted to add a scope — add `connections:write`.
4. Generate an **App-Level Token** (starts with `xapp-`).

## Step 5 — Configure `.env`

Add the tokens to your `.env` file (do not commit `.env`):

```bash
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
```

## Step 6 — Sync the Slack gateway config

```bash
bash scripts/sync-config.sh --sync-gateway
```

This merges `config/slack.yaml` into `~/.hermes/config.yaml`.

## Step 7 — Verify

```bash
hermes gateway status
hermes gateway
```

Mention your bot in a Slack channel or DM to start a conversation.

## Troubleshooting

- **Bot does not respond to mentions**: ensure `app_mentions:read` is added and the app is subscribed to `app_mention` events under **Event Subscriptions**.
- **Socket Mode disconnects**: regenerate the App-Level Token if it was copied incorrectly.
- **Cannot send DMs**: make sure `im:write` and `im:history` scopes are present and the app is reinstalled after adding scopes.
