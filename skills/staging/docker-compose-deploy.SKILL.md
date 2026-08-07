---
id: docker-compose-deploy
title: Standard Multi-Container Docker Service Deployment
tags: [devops, automation]
version: 1.0.0
last_verified: 2026-07-26
invocation_count: 0
success_count: 0
---

# Intent
Deploys a multi-container service using `docker compose` with health checks. Validates the compose file before starting, waits for all containers to become healthy, and reports status.

# Prerequisites
- Docker and docker compose (v2+) installed
- `docker-compose.yml` (or `compose.yaml`) present in the working directory
- Docker daemon running

# Procedure
1. Verify Docker daemon is reachable:
   ```bash
   docker info --format '{{.ServerVersion}}'
   ```
   If this fails, report "Docker daemon is not running or not accessible."

2. Validate the compose file:
   ```bash
   docker compose -f docker-compose.yml config --quiet
   ```
   If validation fails (non-zero exit), stop and report the error output.

3. Pull latest images (optional but recommended):
   ```bash
   docker compose pull
   ```

4. Start services in detached mode:
   ```bash
   docker compose up -d --remove-orphans
   ```

5. Wait for health checks (max 120s). Poll every 10s:
   ```bash
   for i in $(seq 1 12); do
     unhealthy=$(docker compose ps --format json | grep -c '"Health":"unhealthy"' || true)
     starting=$(docker compose ps --format json | grep -c '"Health":"starting"' || true)
     if [ "$unhealthy" -gt 0 ]; then
       echo "UNHEALTHY containers detected"
       docker compose ps
       exit 1
     fi
     if [ "$starting" -eq 0 ]; then
       echo "All containers healthy"
       docker compose ps
       exit 0
     fi
     sleep 10
   done
   echo "TIMEOUT: containers still starting after 120s"
   docker compose ps
   exit 1
   ```

6. Report final status: list all containers and their health state.

# Error Handling
- If `docker info` fails: Docker daemon is down. Report and abort.
- If `config --quiet` fails: report the YAML/configuration error. Do NOT attempt to start services.
- If `docker compose up` fails: report the error output. Check for port conflicts or missing images.
- If containers don't become healthy within 120s: report which services are still starting or unhealthy.
- If any container reports "unhealthy": report the failing service and its logs:
  ```bash
  docker compose logs --tail=50 <service-name>
  ```
