# DevOps Workspace Directive

## Architectural Rules
1. Every containerization execution workflow must utilize minimal alpine or slim base images.
2. Hardened Parameterization: Do not expose raw internal container ports to public host interfaces unless declared explicitly in local proxy files.
3. Every shell script generated must explicitly enforce error handling patterns (`set -euo pipefail`).

## Workflow Checklist
- Check syntactic alignment via standard configuration lints before initiating code deployment cycles.
- Run comprehensive container integration tests over modified environments before concluding terminal routines.
- Prefer `docker compose` over `docker-compose` (the standalone binary is deprecated).

## Environment
- Target: Linux servers (Ubuntu 22.04+)
- Orchestration: Docker Compose v2+
- CI: GitHub Actions (when applicable)
- Monitoring: Health checks in compose files, not external monitors
