#!/bin/bash

source ~/devops/env
MAX_RETRIES=5
RETRY_INTERVAL=5
HEALTHCHECK_PATH="http://localhost:${PORT}/api/health"
LOG_OUTPUT_PATH="$DEPLOYMENT_DIRECTORY/health-check.log"

try=1
while [ $try -le $MAX_RETRIES ]; do
  response=$(curl --silent --write-out "%{http_code}" --output /dev/null "$HEALTHCHECK_PATH")

  if [ "$response" -eq 200 ]; then
    echo "$(date): Health check was successful, try $try" >> "$LOG_OUTPUT_PATH"
    exit 0
  else
    echo "$(date): Health check was unsuccessful, try $try" >> "$LOG_OUTPUT_PATH"
  fi

  if [ $try -lt $MAX_RETRIES ]; then
    sleep $RETRY_INTERVAL
  fi

  try=$((try+1))
done

echo "$(date): Health check was unsuccessful, try $try" >> "$LOG_OUTPUT_PATH"
exit 1
