#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${HOME}/devops/env"
ENV_TEMPLATE="${PROJECT_ROOT}/scripts/env.template"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Prepare the local development and deployment environment.

Options:
  --docker-only    Start only the Docker Compose observability stack
  --deploy-env     Create or update the WSL deployment environment file
  --full           Run deploy-env setup and start Docker Compose (default)
  --help           Show this help message
EOF
}

log() {
  echo "[setup] $*"
}

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

setup_deploy_env() {
  mkdir -p "$(dirname "${ENV_FILE}")"

  if [ -f "${ENV_FILE}" ]; then
    log "Environment file already exists at ${ENV_FILE}"
    return
  fi

  if [ ! -f "${ENV_TEMPLATE}" ]; then
    echo "Missing environment template: ${ENV_TEMPLATE}" >&2
    exit 1
  fi

  cp "${ENV_TEMPLATE}" "${ENV_FILE}"
  sed -i "s|__PROJECT_DIRECTORY__|${PROJECT_ROOT}|g" "${ENV_FILE}"
  sed -i "s|__DEPLOYMENT_DIRECTORY__|${HOME}/midterm/deployment|g" "${ENV_FILE}"
  sed -i "s|__USER__|${USER}|g" "${ENV_FILE}"

  log "Created deployment environment file at ${ENV_FILE}"
  log "Review and adjust paths if you deploy from WSL2"
}

start_docker_stack() {
  check_command docker
  cd "${PROJECT_ROOT}"
  log "Starting application and observability stack with Docker Compose..."
  docker compose up -d --build
  log "Stack is starting. Services:"
  log "  Application:  http://localhost:8080"
  log "  Prometheus:   http://localhost:9090"
  log "  Grafana:      http://localhost:3000 (admin/admin)"
  log "  Kibana:       http://localhost:5601"
  log "Waiting for services to become healthy..."
  if bash "${PROJECT_ROOT}/scripts/post-deploy-check.sh"; then
    log "Post-deployment verification passed."
  else
    log "Post-deployment verification failed. Check container logs with: docker compose logs app"
    exit 1
  fi
}

MODE="full"

while [ $# -gt 0 ]; do
  case "$1" in
    --docker-only) MODE="docker-only" ;;
    --deploy-env) MODE="deploy-env" ;;
    --full) MODE="full" ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

case "${MODE}" in
  docker-only)
    start_docker_stack
    ;;
  deploy-env)
    setup_deploy_env
    ;;
  full)
    setup_deploy_env
    start_docker_stack
    ;;
esac

log "Environment setup complete."
