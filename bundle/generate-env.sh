#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  echo "FAILED: .env already exists. Move or remove it before generating a new one."
  exit 1
fi

cp env.example .env

POSTGRES_PASSWORD_VALUE="$(openssl rand -hex 16)"
SECRET_KEY_BASE_VALUE="$(openssl rand -base64 64 | tr -d '\n')"
PRIMARY_ENCRYPTION_KEY_VALUE="$(openssl rand -base64 32 | tr -d '\n')"
WORKER_SECRET_VALUE="$(openssl rand -base64 32 | tr -d '\n')"

openssl genrsa -out worker_private.pem 2048 >/dev/null 2>&1
openssl rsa -in worker_private.pem -pubout -out worker_public.pem >/dev/null 2>&1

WORKER_RUNS_PRIVATE_KEY_VALUE="$(base64 -w0 worker_private.pem)"
WORKER_LIGHTNING_PUBLIC_KEY_VALUE="$(base64 -w0 worker_public.pem)"

sed -i "s#change-this-postgres-password#${POSTGRES_PASSWORD_VALUE}#g" .env
sed -i "s#change-this-secret-key-base#${SECRET_KEY_BASE_VALUE}#g" .env
sed -i "s#change-this-primary-encryption-key#${PRIMARY_ENCRYPTION_KEY_VALUE}#g" .env
sed -i "s#change-this-worker-runs-private-key#${WORKER_RUNS_PRIVATE_KEY_VALUE}#g" .env
sed -i "s#change-this-worker-lightning-public-key#${WORKER_LIGHTNING_PUBLIC_KEY_VALUE}#g" .env
sed -i "s#change-this-worker-secret#${WORKER_SECRET_VALUE}#g" .env

rm -f worker_private.pem worker_public.pem

echo "SUCCESS: .env generated."
echo "Review .env before running ./install.sh"
