# Staging Skills

Skills in this directory are **templates awaiting real Hermes usage**. They start with `invocation_count: 0` and `success_count: 0`.

## Lifecycle

1. **Created** — Agent writes a new skill here with `invocation_count: 0, success_count: 0`.
2. **Used** — Each time the agent invokes the skill successfully, `success_count` increments.
3. **Promoted** — When `success_count >= 3` (per `.curator-rules.json`), the skill is auto-promoted to `skills/active/` by `scripts/promote-skills.sh`.
4. **Stale** — If unused for 30+ days, the curator marks it stale.
5. **Archived** — After 90+ days stale, the curator archives it.

## Current Skills

| Skill | Invocations | Successes | Status |
|-------|-------------|-----------|--------|
| `git-sync-workflow.SKILL.md` | 0 | 0 | Awaiting first use |
| `docker-compose-deploy.SKILL.md` | 0 | 0 | Awaiting first use |
| `python-project-init.SKILL.md` | 0 | 0 | Awaiting first use |

## Promotion Threshold

`min_successful_invocations: 3` (set in `skills/.curator-rules.json`)

Skills need 3 successful real-world invocations before they graduate to `skills/active/`. This prevents a "worked once" skill from becoming permanent procedural memory.
