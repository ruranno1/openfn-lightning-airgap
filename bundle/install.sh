#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "FAILED: Docker is not installed or not in PATH."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "FAILED: Docker Compose v2 is not available. Expected: docker compose"
  exit 1
fi

if [ ! -f images/images.tar ]; then
  echo "FAILED: images/images.tar not found. Run this script from the extracted bundle directory."
  exit 1
fi

if [ ! -f .env ]; then
  echo "FAILED: .env file not found."
  echo "Create it first using: cp env.example .env"
  echo "Then edit .env and replace all change-this values."
  exit 1
fi

if grep -q "change-this" .env; then
  echo "FAILED: .env still contains placeholder values containing 'change-this'."
  echo "Edit .env and set real secrets/passwords before starting."
  exit 1
fi

echo "Loading Docker images from bundle..."
docker load -i images/images.tar

echo "Starting OpenFn Lightning services..."
docker compose up -d

echo
echo "Current service status:"
docker compose ps

echo
echo "Install step completed. Run ./verify.sh to confirm Lightning is working."
