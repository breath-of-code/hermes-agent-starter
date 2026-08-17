# Changelog

## [0.1.0] — 2026-08-07

### Added
- Public edition of the Hermes Agent Blueprint
- Generic `config/SOUL.md` persona template
- Generic `config/config.yaml` agent settings (provider, model, reasoning)
- Gateway platform templates: `config/discord.yaml`, `config/telegram.yaml`, `config/slack.yaml`
- Service config templates: `config/tools.yaml`, `config/mcp.yaml`, `config/honcho.json`
- Gateway setup guides: `config/discord.md`, `config/telegram.md`, `config/slack.md`
- Setup guides: `docs/honcho-setup.md`, `docs/ubuntu-cloud-setup.md`
- `scripts/sync-config.sh` — one-command config sync to `~/.hermes/` (core + tools + MCP + gateway + memory)
- `scripts/cron-health-check.sh` — cron health monitoring
- `scripts/promote-skills.sh` — auto-promote staging skills after 3+ successful invocations
- `scripts/backup-hermes.sh` / `scripts/restore-hermes.sh` — config backup and restore
- `scripts/lint-blueprint.sh` — repo linting (bash syntax, YAML/JSON validity)
- `skills/.curator-rules.json` — skill promotion thresholds
- Example staging skills: `git-sync-workflow`, `docker-compose-deploy`, `python-project-init`
- Per-context profile templates: `profiles/dev-ops/`, `profiles/research/`
- `.editorconfig`, `.gitattributes`, `.gitignore` for cross-platform consistency
- Generic `.env.example` with placeholder provider and gateway tokens
- MIT `LICENSE`

### Notes
- This public edition is derived from a private upstream blueprint. Personal names, task history, and repository-specific workflow rules have been removed or anonymized.
