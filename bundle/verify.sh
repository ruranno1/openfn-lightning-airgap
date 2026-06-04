#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:4000}"

echo "Checking container status..."
docker compose ps

echo
echo "Waiting for Lightning to respond at ${URL} ..."

for i in $(seq 1 30); do
  if curl -fsS "${URL}" >/dev/null 2>&1; then
    echo
    echo "SUCCESS: Lightning is running and responding at ${URL}"
    exit 0
  fi
  echo "Attempt ${i}/30: not ready yet..."
  sleep 5
done

echo
echo "FAILED: Lightning did not respond at ${URL}"
echo
echo "Useful troubleshooting commands:"
echo "docker compose ps"
echo "docker compose logs --tail=100 lightning"
echo "docker compose logs --tail=100 postgres"
exit 1
