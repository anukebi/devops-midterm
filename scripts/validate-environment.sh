#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CI_MODE=false

if [ "${1:-}" = "--ci" ]; then
  CI_MODE=true
fi

failures=0

check() {
  local name="$1"
  local command="$2"
  if eval "${command}" >/dev/null 2>&1; then
    echo "[ok] ${name}"
  else
    echo "[fail] ${name}"
    failures=$((failures + 1))
  fi
}

echo "Validating project environment..."

check "Maven wrapper exists" "test -x ${PROJECT_ROOT}/mvnw"
check "Dockerfile exists" "test -f ${PROJECT_ROOT}/Dockerfile"
check "Docker Compose file exists" "test -f ${PROJECT_ROOT}/docker-compose.yml"
check "Terraform configuration exists" "test -f ${PROJECT_ROOT}/pipeline/terraform/main.tf"
check "Ansible playbook exists" "test -f ${PROJECT_ROOT}/pipeline/ansible/deploy.yml"
check "Health check script exists" "test -x ${PROJECT_ROOT}/pipeline/healthcheck.sh"
check "Prometheus configuration exists" "test -f ${PROJECT_ROOT}/monitoring/prometheus/prometheus.yml"
check "Grafana dashboards exist" "test -f ${PROJECT_ROOT}/monitoring/grafana/dashboards/application-services.json"
check "Environment template exists" "test -f ${PROJECT_ROOT}/scripts/env.template"
check "Post-deploy check script exists" "test -x ${PROJECT_ROOT}/scripts/post-deploy-check.sh"

if [ "${CI_MODE}" = false ]; then
  check "Docker is available" "command -v docker"
  check "Java is available" "command -v java"
  check "Terraform is available" "command -v terraform"
  check "Ansible is available" "command -v ansible-playbook"
fi

if [ "${failures}" -gt 0 ]; then
  echo "Environment validation failed with ${failures} issue(s)."
  exit 1
fi

echo "Environment validation passed."
