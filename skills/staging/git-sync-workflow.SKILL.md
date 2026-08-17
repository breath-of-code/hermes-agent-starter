---
id: git-sync-workflow
title: Daily Git Pull → Sync → Commit Workflow
tags: [devops, automation]
version: 1.0.0
last_verified: 2026-07-26
invocation_count: 0
success_count: 0
---

# Intent
Performs the daily git synchronization workflow: pull latest changes, sync local configs to Hermes, commit any new changes. This is the standard end-of-session or periodic sync routine for the hermes-agent-starter repo.

# Prerequisites
- Git installed and configured
- `hermes-agent-starter` repo cloned locally
- `scripts/sync-config.sh` present and executable
- Remote `origin` configured and accessible (SSH or HTTPS with credentials)

# Procedure
1. Navigate to the blueprint repo root:
   ```bash
   cd ~/hermes-agent-starter
   ```
2. Pull latest changes from remote:
   ```bash
   git pull origin main
   ```
3. If pull fails due to merge conflicts, abort and report the conflicting files. Do NOT force-resolve.
4. Run the config sync script to copy repo configs into `~/.hermes/`:
   ```bash
   bash scripts/sync-config.sh
   ```
5. Check for uncommitted changes:
   ```bash
   git status --porcelain
   ```
6. If there are changes:
   a. Stage all changes:
      ```bash
      git add -A
      ```
   b. Commit with a descriptive message:
      ```bash
      git commit -m "chore: daily sync $(date +%Y-%m-%d)"
      ```
   c. Note: push is handled manually by user — do NOT run `git push`.
7. If there are no changes, report "Nothing to sync — repo is up to date."
8. Verify the commit succeeded:
   ```bash
   git log --oneline -1
   ```

# Error Handling
- If `git pull` fails with authentication error: report "Git authentication failed. Check SSH keys or HTTPS credentials."
- If `git pull` fails with merge conflict: report the conflicting files and abort. Do NOT attempt to resolve.
- If `sync-config.sh` fails: report the script error output and abort.
- If `git commit` fails (nothing to commit): report "Nothing to commit — working tree clean."
