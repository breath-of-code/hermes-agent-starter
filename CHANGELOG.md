# Changelog

## [1.0.0] — 2026-07-29

### Added
- Public edition of the Hermes Agent Blueprint
- Generic `config/SOUL.md` persona template
- Generic `config/config.yaml` agent settings subset
- `scripts/sync-config.sh` — one-command config sync to `~/.hermes/`
- `scripts/cron-health-check.sh` — cron health monitoring
- `scripts/promote-skills.sh` — auto-promote staging skills after 3+ successful invocations
- `skills/.curator-rules.json` — skill promotion thresholds
- Example staging skills: `git-sync-workflow`, `docker-compose-deploy`, `python-project-init`
- Per-context profile templates: `profiles/dev-ops/AGENTS.md`, `profiles/research/AGENTS.md`
- `.editorconfig`, `.gitattributes`, `.gitignore` for cross-platform consistency
- Honcho memory provider template (`config/honcho.json`)
- Generic `.env.example` with placeholder provider and gateway tokens

### Notes
- This public edition is derived from a private upstream blueprint. Personal names, task history, and repository-specific workflow rules have been removed or anonymized.
