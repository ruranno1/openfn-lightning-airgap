#!/usr/bin/env bash
set -euo pipefail

LIGHTNING_VERSION="v2.16.6"
POSTGRES_IMAGE="postgres:16-alpine"
LIGHTNING_IMAGE="openfn/lightning:${LIGHTNING_VERSION}"
WS_WORKER_IMAGE="openfn/ws-worker:latest"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
BUNDLE_NAME="openfn-lightning-airgap-${LIGHTNING_VERSION}"
BUNDLE_DIR="${DIST_DIR}/${BUNDLE_NAME}"

echo "Building OpenFn Lightning air-gap bundle: ${LIGHTNING_VERSION}"

rm -rf "${DIST_DIR}"
mkdir -p "${BUNDLE_DIR}/images"

echo "Pulling Docker images..."
docker pull "${POSTGRES_IMAGE}"
docker pull "${LIGHTNING_IMAGE}"
docker pull "${WS_WORKER_IMAGE}"

echo "Saving Docker images..."
docker save \
  "${POSTGRES_IMAGE}" \
  "${LIGHTNING_IMAGE}" \
  "${WS_WORKER_IMAGE}" \
  -o "${BUNDLE_DIR}/images/images.tar"

echo "Copying deployment files..."
cp "${SCRIPT_DIR}/docker-compose.yml" "${BUNDLE_DIR}/"
cp "${SCRIPT_DIR}/env.example" "${BUNDLE_DIR}/"
cp "${SCRIPT_DIR}/install.sh" "${BUNDLE_DIR}/"
cp "${SCRIPT_DIR}/verify.sh" "${BUNDLE_DIR}/"
cp "${SCRIPT_DIR}/check-bundle.sh" "${BUNDLE_DIR}/"
cp "${SCRIPT_DIR}/generate-env.sh" "${BUNDLE_DIR}/"

chmod +x "${BUNDLE_DIR}"/*.sh

echo "Generating checksums..."
(
  cd "${BUNDLE_DIR}"
  find . -type f ! -name "sha256sums.txt" -print0 | sort -z | xargs -0 sha256sum > sha256sums.txt
)

echo "Creating tarball..."
(
  cd "${DIST_DIR}"
  tar -czf "${BUNDLE_NAME}.tar.gz" "${BUNDLE_NAME}"
  sha256sum "${BUNDLE_NAME}.tar.gz" > "${BUNDLE_NAME}.tar.gz.sha256"
)

echo
echo "Bundle created:"
echo "${DIST_DIR}/${BUNDLE_NAME}.tar.gz"
echo "${DIST_DIR}/${BUNDLE_NAME}.tar.gz.sha256"
