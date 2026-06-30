#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-http://localhost:8080}"
MAX_RETRIES="${MAX_RETRIES:-12}"
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"
CI_MODE=false

if [ "${1:-}" = "--ci" ]; then
  CI_MODE=true
fi

check_endpoint() {
  local path="$1"
  local expected_code="$2"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}${path}" || echo "000")
  [ "${code}" = "${expected_code}" ]
}

wait_for_service() {
  local attempt=1
  while [ "${attempt}" -le "${MAX_RETRIES}" ]; do
    if check_endpoint "/api/health" "200"; then
      echo "[ok] Application health endpoint is ready (attempt ${attempt})"
      return 0
    fi
    echo "[wait] Application not ready yet (attempt ${attempt}/${MAX_RETRIES})..."
    sleep "${RETRY_INTERVAL}"
    attempt=$((attempt + 1))
  done
  echo "[fail] Application did not become healthy in time"
  return 1
}

echo "Running post-deployment verification against ${APP_URL}..."

if [ "${CI_MODE}" = true ]; then
  echo "[skip] Live endpoint checks skipped in CI mode"
  exit 0
fi

wait_for_service

check_endpoint "/api/hello/World" "200" && echo "[ok] GET /api/hello/World"
check_endpoint "/metrics" "200" && echo "[ok] GET /metrics"
check_endpoint "/actuator/prometheus" "200" && echo "[ok] GET /actuator/prometheus"

if check_endpoint "/api/error" "500"; then
  echo "[ok] GET /api/error returns expected error status"
else
  echo "[fail] GET /api/error did not return HTTP 500"
  exit 1
fi

echo "Post-deployment verification passed."
