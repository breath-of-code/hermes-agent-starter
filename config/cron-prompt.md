# config/cron-prompt.md — Shared task prompt for your cron jobs
#
# This is a TEMPLATE. Replace the content below with the instruction you want
# your scheduled agent to run. The {{MAX_TASKS}} placeholder is substituted
# automatically by scripts/sync-cron.sh with each job's max_tasks value.
#
# Example: a daily maintenance task
#   "Review the repository for issues, fix anything safe to fix, and report
#    what you did. Work on up to {{MAX_TASKS}} items."
#
# See the Hermes docs for cron configuration:
#   https://hermes-agent.nousresearch.com/docs

Run your scheduled task. Work on up to {{MAX_TASKS}} items, then report what you did.
